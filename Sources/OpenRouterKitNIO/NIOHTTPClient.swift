//
//  NIOHTTPClient.swift
//  OpenRouterKit
//
//  AsyncHTTPClient-based implementation of HTTPClient for cross-platform
//  streaming support, including Linux.
//

import Foundation
import OpenRouterKit
import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An HTTP client backed by AsyncHTTPClient (SwiftNIO) that provides
/// streaming support on all platforms including Linux.
final class NIOHTTPClient: HTTPClient, @unchecked Sendable {
    private let requestBuilder: RequestBuilder
    package let httpClient: AsyncHTTPClient.HTTPClient

    init(requestBuilder: RequestBuilder, httpClient: AsyncHTTPClient.HTTPClient) {
        self.requestBuilder = requestBuilder
        self.httpClient = httpClient
    }

    func execute<T: Decodable>(_ endpoint: Endpoint, expectedStatusCode: Int) async throws -> T {
        let urlRequest = try requestBuilder.build(endpoint)
        let request = try buildNIORequest(from: urlRequest)

        let response = try await httpClient.execute(request, timeout: .seconds(60))
        let status = Int(response.status.code)
        let buffer = try await response.body.collect(upTo: 10 * 1024 * 1024) // 10 MB
        let data = Data(buffer: buffer)

        if status != expectedStatusCode {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: status, errorResponse: errorResponse)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(
                httpStatusCode: errorResponse?.error.code ?? status,
                errorResponse: errorResponse
            )
        }
    }

    func stream(_ endpoint: Endpoint) async throws -> AsyncThrowingStream<String, Error> {
        try await streamMapped(endpoint) { line in
            SSEParser.processLine(line).map { [$0] } ?? []
        }
    }

    func streamEvents(_ endpoint: Endpoint) async throws -> AsyncThrowingStream<ChatStreamEvent, Error> {
        try await streamMapped(endpoint, transform: SSEParser.processLineAsEvents)
    }

    /// Shared streaming infrastructure using AsyncHTTPClient's response body
    /// as an AsyncSequence of ByteBuffer chunks.
    private func streamMapped<T: Sendable>(
        _ endpoint: Endpoint,
        transform: @escaping @Sendable (String) -> [T]
    ) async throws -> AsyncThrowingStream<T, Error> {
        let urlRequest = try requestBuilder.build(endpoint)
        let request = try buildNIORequest(from: urlRequest)

        let response = try await httpClient.execute(request, timeout: .seconds(300))
        let status = Int(response.status.code)

        if status != 200 {
            let buffer = try await response.body.collect(upTo: 1 * 1024 * 1024) // 1 MB
            let data = Data(buffer: buffer)
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: status, errorResponse: errorResponse)
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var lineBuffer = Data()
                    for try await var chunk in response.body {
                        let bytes = chunk.readBytes(length: chunk.readableBytes) ?? []
                        for byte in bytes {
                            lineBuffer.append(byte)
                            if byte == UInt8(ascii: "\n") {
                                let line = String(decoding: lineBuffer, as: UTF8.self)
                                for value in transform(line) {
                                    continuation.yield(value)
                                }
                                lineBuffer.removeAll(keepingCapacity: true)
                            }
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

    /// Converts a Foundation URLRequest into an AsyncHTTPClient HTTPClientRequest.
    private func buildNIORequest(from urlRequest: URLRequest) throws -> HTTPClientRequest {
        guard let url = urlRequest.url else {
            throw URLError(.badURL)
        }

        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .init(rawValue: urlRequest.httpMethod ?? "GET")

        if let headers = urlRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                request.headers.add(name: key, value: value)
            }
        }

        if let body = urlRequest.httpBody {
            request.body = .bytes(body)
        }

        return request
    }
}
