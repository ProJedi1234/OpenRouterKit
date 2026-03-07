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
    /// When no custom `httpClient` is provided, this method automatically
    /// detects HTTP proxy settings from environment variables (`HTTPS_PROXY`,
    /// `HTTP_PROXY`, `https_proxy`, `http_proxy`). If a proxy is detected,
    /// a new `HTTPClient` is created with proxy configuration; otherwise
    /// the shared instance (`.shared`) is used.
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
    ///   - httpClient: The AsyncHTTPClient instance to use. If nil, auto-detects proxy
    ///     from environment or falls back to `.shared`.
    /// - Returns: A configured OpenRouterClient using SwiftNIO for HTTP transport
    public static func nio(
        baseURL: String = "https://openrouter.ai/api/v1",
        apiKey: String,
        siteURL: String? = nil,
        siteName: String? = nil,
        httpClient: AsyncHTTPClient.HTTPClient? = nil
    ) -> OpenRouterClient {
        let requestBuilder = RequestBuilder(
            baseURL: baseURL,
            apiKey: apiKey,
            siteURL: siteURL,
            siteName: siteName
        )
        let (resolvedClient, ownsClient) = Self.resolveHTTPClient(provided: httpClient)
        let nioClient = NIOHTTPClient(requestBuilder: requestBuilder, httpClient: resolvedClient, ownsHTTPClient: ownsClient)
        return OpenRouterClient(httpClient: nioClient)
    }

    /// Shuts down the underlying AsyncHTTPClient.
    ///
    /// Only needed when a custom (non-`.shared`) `HTTPClient` was provided
    /// or when auto-proxy detection created a new client.
    /// The `.shared` instance manages its own lifecycle automatically.
    ///
    /// - Throws: If the shutdown fails
    public func shutdownNIOHTTPClient() async throws {
        if let nioClient = self.httpClient as? NIOHTTPClient, nioClient.ownsHTTPClient {
            try await nioClient.httpClient.shutdown()
        }
    }

    /// Resolves the HTTPClient to use, auto-detecting proxy from environment.
    /// Returns the client and whether we own it (need to shut it down).
    private static func resolveHTTPClient(provided: AsyncHTTPClient.HTTPClient?) -> (AsyncHTTPClient.HTTPClient, Bool) {
        if let provided {
            return (provided, false)
        }
        if let proxy = Self.proxyFromEnvironment() {
            var config = AsyncHTTPClient.HTTPClient.Configuration()
            config.proxy = proxy
            return (AsyncHTTPClient.HTTPClient(configuration: config), true)
        }
        return (.shared, false)
    }

    /// Parses HTTP proxy configuration from standard environment variables.
    ///
    /// Supports proxy URLs in the format: `http://user:password@host:port`
    private static func proxyFromEnvironment() -> AsyncHTTPClient.HTTPClient.Configuration.Proxy? {
        let proxyString = ProcessInfo.processInfo.environment["HTTPS_PROXY"]
            ?? ProcessInfo.processInfo.environment["https_proxy"]
            ?? ProcessInfo.processInfo.environment["HTTP_PROXY"]
            ?? ProcessInfo.processInfo.environment["http_proxy"]

        guard let proxyString, let url = URL(string: proxyString) else {
            return nil
        }

        let host = url.host ?? "127.0.0.1"
        let port = url.port ?? 8080

        var authorization: AsyncHTTPClient.HTTPClient.Authorization?
        if let user = url.user {
            let password = url.password ?? ""
            authorization = .basic(username: user, password: password)
        }

        return .server(host: host, port: port, authorization: authorization)
    }
}
