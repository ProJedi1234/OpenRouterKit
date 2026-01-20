//
//  ChatService.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Service for chat completion operations.
final class ChatService: ChatServiceProtocol {
    private let httpClient: HTTPClient
    
    /// Creates a new chat service.
    ///
    /// - Parameter httpClient: The HTTP client to use for requests
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func send(request: ChatRequest) async throws -> ChatResponse {
        try await httpClient.execute(.chatCompletions(request), expectedStatusCode: 200)
    }

    #if canImport(Darwin)
    @available(iOS 15.0, macOS 12.0, *)
    func stream(request: ChatRequest) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                do {
                    var streamingRequest = request
                    streamingRequest.stream = true
                    let stream = try await httpClient.stream(.chatCompletions(streamingRequest))
                    for await chunk in stream {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
    #endif
}
