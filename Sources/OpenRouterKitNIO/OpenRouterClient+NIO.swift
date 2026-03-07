//
//  OpenRouterClient+NIO.swift
//  OpenRouterKit
//
//  Convenience factory for creating OpenRouterClient instances backed by
//  AsyncHTTPClient for cross-platform streaming support.
//

import Foundation
import OpenRouterKit
import AsyncHTTPClient

/// Re-export OpenRouterKit so users only need to import OpenRouterKitNIO.
@_exported import OpenRouterKit

extension OpenRouterClient {
    /// Creates a new OpenRouter client backed by AsyncHTTPClient (SwiftNIO).
    ///
    /// This client supports streaming on all platforms, including Linux,
    /// unlike the default URLSession-based client which only supports
    /// streaming on Darwin platforms (macOS, iOS, etc.).
    ///
    /// Example:
    /// ```swift
    /// import OpenRouterKitNIO
    ///
    /// let client = OpenRouterClient.nio(apiKey: "your-api-key")
    /// let stream = try await client.chat.stream(request: chatRequest)
    /// ```
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for the API (default: "https://openrouter.ai/api/v1")
    ///   - apiKey: Your OpenRouter API key
    ///   - siteURL: Optional site URL for referrer header
    ///   - siteName: Optional site name for X-Title header
    ///   - httpClient: The AsyncHTTPClient instance to use (default: `.shared`)
    /// - Returns: A configured OpenRouterClient using SwiftNIO for HTTP transport
    public static func nio(
        baseURL: String = "https://openrouter.ai/api/v1",
        apiKey: String,
        siteURL: String? = nil,
        siteName: String? = nil,
        httpClient: AsyncHTTPClient.HTTPClient = .shared
    ) -> OpenRouterClient {
        let requestBuilder = RequestBuilder(
            baseURL: baseURL,
            apiKey: apiKey,
            siteURL: siteURL,
            siteName: siteName
        )
        let nioClient = NIOHTTPClient(requestBuilder: requestBuilder, httpClient: httpClient)
        return OpenRouterClient(httpClient: nioClient)
    }

    /// Shuts down the underlying AsyncHTTPClient.
    ///
    /// Only needed when a custom (non-`.shared`) `HTTPClient` was provided
    /// to ``nio(baseURL:apiKey:siteURL:siteName:httpClient:)``.
    /// The `.shared` instance manages its own lifecycle automatically.
    ///
    /// - Throws: If the shutdown fails
    public func shutdownNIOHTTPClient() async throws {
        if let nioClient = self.httpClient as? NIOHTTPClient {
            try await nioClient.httpClient.shutdown()
        }
    }
}
