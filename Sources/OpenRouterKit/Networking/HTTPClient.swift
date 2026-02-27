//
//  HTTPClient.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Protocol for making HTTP requests to the OpenRouter API.
protocol HTTPClient: Sendable {
    /// Executes an HTTP request and decodes the response.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to call
    ///   - expectedStatusCode: The expected HTTP status code for success
    /// - Returns: Decoded response of type T
    /// - Throws: OpenRouterError or URLError if the request fails
    func execute<T: Decodable>(_ endpoint: Endpoint, expectedStatusCode: Int) async throws -> T

    #if canImport(Darwin)
    /// Streams a response from an HTTP request.
    ///
    /// - Parameter endpoint: The endpoint to stream from
    /// - Returns: An AsyncThrowingStream of String chunks
    /// - Throws: OpenRouterError or URLError if the request fails
    /// - Note: Streaming is only available on Darwin platforms (macOS, iOS, etc.)
    @available(iOS 15.0, macOS 12.0, *)
    func stream(_ endpoint: Endpoint) async throws -> AsyncThrowingStream<String, Error>

    /// Streams a response as structured events from an HTTP request.
    ///
    /// - Parameter endpoint: The endpoint to stream from
    /// - Returns: An AsyncThrowingStream of ChatStreamEvent values
    /// - Throws: OpenRouterError or URLError if the request fails
    /// - Note: Streaming is only available on Darwin platforms (macOS, iOS, etc.)
    @available(iOS 15.0, macOS 12.0, *)
    func streamEvents(_ endpoint: Endpoint) async throws -> AsyncThrowingStream<ChatStreamEvent, Error>
    #endif
}

/// URLSession-based implementation of HTTPClient.
final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let requestBuilder: RequestBuilder
    
    /// Creates a new URLSessionHTTPClient.
    ///
    /// - Parameters:
    ///   - session: The URLSession to use for requests
    ///   - requestBuilder: The request builder to construct requests
    init(session: URLSession, requestBuilder: RequestBuilder) {
        self.session = session
        self.requestBuilder = requestBuilder
    }
    
    func execute<T: Decodable>(_ endpoint: Endpoint, expectedStatusCode: Int) async throws -> T {
        let request = try requestBuilder.build(endpoint)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle error status codes
        if httpResponse.statusCode != expectedStatusCode {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        
        // Decode successful response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // If decoding fails, try to extract error information
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(
                httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode,
                errorResponse: errorResponse
            )
        }
    }

    #if canImport(Darwin)
    @available(iOS 15.0, macOS 12.0, *)
    func streamEvents(_ endpoint: Endpoint) async throws -> AsyncThrowingStream<ChatStreamEvent, Error> {
        try await streamMapped(endpoint, transform: Self.processLineAsEvents)
    }

    @available(iOS 15.0, macOS 12.0, *)
    func stream(_ endpoint: Endpoint) async throws -> AsyncThrowingStream<String, Error> {
        try await streamMapped(endpoint) { line in
            Self.processLine(line).map { [$0] } ?? []
        }
    }

    /// Shared streaming infrastructure for SSE endpoints.
    ///
    /// Handles request setup, HTTP status checking, byte-level line buffering
    /// (with correct multi-byte UTF-8 support), task cancellation on termination,
    /// and error propagation through the throwing stream.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to stream from
    ///   - transform: Converts each SSE line into zero or more output values
    /// - Returns: An AsyncThrowingStream of transformed values
    @available(iOS 15.0, macOS 12.0, *)
    private func streamMapped<T: Sendable>(
        _ endpoint: Endpoint,
        transform: @escaping @Sendable (String) -> [T]
    ) async throws -> AsyncThrowingStream<T, Error> {
        let request = try requestBuilder.build(endpoint)
        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            let errorData = try await bytes.reduce(into: Data()) { data, byte in
                data.append(byte)
            }
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: errorData)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var buffer = Data()
                    for try await byte in bytes {
                        buffer.append(byte)
                        if byte == UInt8(ascii: "\n") {
                            let line = String(decoding: buffer, as: UTF8.self)
                            for value in transform(line) {
                                continuation.yield(value)
                            }
                            buffer.removeAll(keepingCapacity: true)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    #endif

    private static func processLine(_ line: String) -> String? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty, trimmedLine.hasPrefix("data: ") else { return nil }

        let jsonString = String(trimmedLine.dropFirst(6))
        guard jsonString != "[DONE]",
              let jsonData = jsonString.data(using: .utf8),
              let delta = try? JSONDecoder().decode(StreamingDelta.self, from: jsonData),
              let content = delta.choices.first?.delta.content,
              !content.isEmpty else { return nil }

        return content
    }

    static func processLineAsEvents(_ line: String) -> [ChatStreamEvent] {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty, trimmedLine.hasPrefix("data: ") else { return [] }

        let jsonString = String(trimmedLine.dropFirst(6))
        guard jsonString != "[DONE]",
              let jsonData = jsonString.data(using: .utf8),
              let delta = try? JSONDecoder().decode(StreamingDelta.self, from: jsonData),
              let choice = delta.choices.first else { return [] }

        var events: [ChatStreamEvent] = []

        if let content = choice.delta.content, !content.isEmpty {
            events.append(.text(content))
        }

        if let toolCallDeltas = choice.delta.toolCalls {
            for toolCallDelta in toolCallDeltas {
                events.append(.toolCallDelta(toolCallDelta))
            }
        }

        if let finishReason = choice.finish_reason {
            events.append(.finished(finishReason: finishReason, usage: delta.usage))
        }

        return events
    }
}
