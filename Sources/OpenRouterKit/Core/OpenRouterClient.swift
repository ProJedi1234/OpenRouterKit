//
//  OpenRouterClient.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for interacting with the OpenRouter API.
///
/// `OpenRouterClient` provides access to chat completions, model information,
/// and API key management through dedicated service objects.
///
/// Example:
/// ```swift
/// let client = OpenRouterClient(apiKey: "your-api-key")
/// let response = try await client.chat.send(request: chatRequest)
/// ```
public final class OpenRouterClient: OpenRouterClientProtocol, Sendable {
    private let httpClient: HTTPClient
    
    /// Service for chat completion operations.
    public let chat: ChatServiceProtocol
    
    /// Service for model information operations.
    public let models: ModelsServiceProtocol
    
    /// Service for API key management operations.
    public let keys: KeysServiceProtocol
    
    /// Creates a new OpenRouter client.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for the API (default: "https://openrouter.ai/api/v1")
    ///   - apiKey: Your OpenRouter API key
    ///   - siteURL: Optional site URL for referrer header
    ///   - siteName: Optional site name for X-Title header
    ///   - session: The URLSession to use for requests (default: URLSession.shared)
    public init(
        baseURL: String = "https://openrouter.ai/api/v1",
        apiKey: String,
        siteURL: String? = nil,
        siteName: String? = nil,
        session: URLSession = URLSession.shared
    ) {
        let requestBuilder = RequestBuilder(
            baseURL: baseURL,
            apiKey: apiKey,
            siteURL: siteURL,
            siteName: siteName
        )
        self.httpClient = URLSessionHTTPClient(session: session, requestBuilder: requestBuilder)
        self.chat = ChatService(httpClient: httpClient)
        self.models = ModelsService(httpClient: httpClient)
        self.keys = KeysService(httpClient: httpClient)
    }
    
    // MARK: - Backward Compatibility Methods
    
    /// Sends a chat completion request.
    ///
    /// - Parameter request: The chat request to send
    /// - Returns: The chat response
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.chat.send(request:) instead")
    public func sendChatRequest(request: OpenRouterRequest) async throws -> OpenRouterResponse {
        let chatRequest = ChatRequest(
            messages: request.messages,
            prompt: request.prompt,
            model: request.model,
            responseFormat: request.responseFormat,
            stop: request.stop,
            stream: request.stream,
            maxTokens: request.maxTokens,
            temperature: request.temperature,
            topP: request.topP,
            topK: request.topK,
            frequencyPenalty: request.frequencyPenalty,
            presencePenalty: request.presencePenalty,
            repetitionPenalty: request.repetitionPenalty,
            seed: request.seed,
            tools: request.tools,
            toolChoice: request.toolChoice,
            logitBias: request.logitBias,
            transforms: request.transforms,
            models: request.models,
            route: request.route,
            provider: request.provider,
            reasoning: request.reasoning
        )
        let response = try await chat.send(request: chatRequest)
        // OpenRouterResponse is a typealias for ChatResponse, so we can return directly
        return response
    }
    
    /// Lists available models with optional filters.
    ///
    /// - Parameters:
    ///   - category: Optional category filter
    ///   - supportedParameters: Optional supported parameters filter
    ///   - useRSS: Optional RSS filter
    ///   - useRSSChatLinks: Optional RSS chat links filter
    /// - Returns: List of available models
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.models.list(...) instead")
    public func listModels(
        category: String? = nil,
        supportedParameters: String? = nil,
        useRSS: String? = nil,
        useRSSChatLinks: String? = nil
    ) async throws -> ModelsListResponse {
        try await models.list(
            category: category,
            supportedParameters: supportedParameters,
            useRSS: useRSS,
            useRSSChatLinks: useRSSChatLinks
        )
    }
    
    /// Lists models available to the current user.
    ///
    /// - Returns: List of models available to the user
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.models.listForUser() instead")
    public func listModelsForUser() async throws -> ModelsListResponse {
        try await models.listForUser()
    }
    
    /// Lists API keys.
    ///
    /// - Parameters:
    ///   - includeDisabled: Whether to include disabled keys
    ///   - offset: Pagination offset
    /// - Returns: List of API keys
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.keys.list(...) instead")
    public func listKeys(
        includeDisabled: Bool? = nil,
        offset: String? = nil
    ) async throws -> APIKeyListResponse {
        try await keys.list(includeDisabled: includeDisabled, offset: offset)
    }
    
    /// Creates a new API key.
    ///
    /// - Parameter request: The API key creation request
    /// - Returns: The created API key (including the key string)
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.keys.create(request:) instead")
    public func createKey(request: CreateAPIKeyRequest) async throws -> CreateAPIKeyResponse {
        try await keys.create(request: request)
    }
    
    /// Gets a single API key by hash.
    ///
    /// - Parameter hash: The hash identifier of the API key
    /// - Returns: The API key information
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.keys.get(hash:) instead")
    public func getKey(hash: String) async throws -> APIKeyResponse {
        try await keys.get(hash: hash)
    }
    
    /// Updates an API key.
    ///
    /// - Parameters:
    ///   - hash: The hash identifier of the API key
    ///   - request: The update request
    /// - Returns: The updated API key information
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.keys.update(hash:request:) instead")
    public func updateKey(hash: String, request: UpdateAPIKeyRequest) async throws -> APIKeyResponse {
        try await keys.update(hash: hash, request: request)
    }
    
    /// Deletes an API key.
    ///
    /// - Parameter hash: The hash identifier of the API key
    /// - Returns: Confirmation of deletion
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.keys.delete(hash:) instead")
    public func deleteKey(hash: String) async throws -> DeleteAPIKeyResponse {
        try await keys.delete(hash: hash)
    }
    
    /// Gets information about the current API key.
    ///
    /// - Returns: Current API key information
    /// - Throws: OpenRouterError if the request fails
    @available(*, deprecated, message: "Use client.keys.getCurrent() instead")
    public func getCurrentKey() async throws -> CurrentAPIKeyResponse {
        try await keys.getCurrent()
    }

    /// Streams a chat completion response.
    ///
    /// - Parameter request: The chat request to stream
    /// - Returns: An AsyncStream of String chunks
    @available(iOS 15.0, macOS 12.0, *)
    @available(*, deprecated, message: "Use client.chat.stream(request:) instead")
    public func streamChatRequest(request: OpenRouterRequest) -> AsyncStream<String> {
        let chatRequest = ChatRequest(
            messages: request.messages,
            prompt: request.prompt,
            model: request.model,
            responseFormat: request.responseFormat,
            stop: request.stop,
            stream: request.stream,
            maxTokens: request.maxTokens,
            temperature: request.temperature,
            topP: request.topP,
            topK: request.topK,
            frequencyPenalty: request.frequencyPenalty,
            presencePenalty: request.presencePenalty,
            repetitionPenalty: request.repetitionPenalty,
            seed: request.seed,
            tools: request.tools,
            toolChoice: request.toolChoice,
            logitBias: request.logitBias,
            transforms: request.transforms,
            models: request.models,
            route: request.route,
            provider: request.provider,
            reasoning: request.reasoning
        )
        return chat.stream(request: chatRequest)
    }
}
