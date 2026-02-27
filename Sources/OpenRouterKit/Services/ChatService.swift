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
    func stream(request: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        var streamingRequest = request
        streamingRequest.stream = true
        return try await httpClient.stream(.chatCompletions(streamingRequest))
    }

    @available(iOS 15.0, macOS 12.0, *)
    func streamEvents(request: ChatRequest) async throws -> AsyncThrowingStream<ChatStreamEvent, Error> {
        var streamingRequest = request
        streamingRequest.stream = true
        return try await httpClient.streamEvents(.chatCompletions(streamingRequest))
    }
    #endif
}
