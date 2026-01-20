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
}
