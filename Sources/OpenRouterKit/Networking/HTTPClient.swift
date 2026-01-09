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

    /// Streams a response from an HTTP request.
    ///
    /// - Parameter endpoint: The endpoint to stream from
    /// - Returns: An AsyncStream of String chunks
    /// - Throws: OpenRouterError or URLError if the request fails
    @available(iOS 15.0, macOS 12.0, *)
    func stream(_ endpoint: Endpoint) async throws -> AsyncStream<String>
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

    @available(iOS 15.0, macOS 12.0, *)
    func stream(_ endpoint: Endpoint) async throws -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                do {
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

                    var buffer = ""
                    for try await byte in bytes {
                        if let char = String(bytes: [byte], encoding: .utf8) {
                            buffer += char
                            if char == "\n" {
                                if let processedLine = Self.processLine(buffer) {
                                    continuation.yield(processedLine)
                                }
                                buffer = ""
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

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
}
