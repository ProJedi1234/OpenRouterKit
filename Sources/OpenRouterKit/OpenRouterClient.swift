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

// Define the OpenRouterClient
public final class OpenRouterClient: Sendable {
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession
    private let siteURL: String?
    private let siteName: String?

    public init(
        baseURL: String = "https://openrouter.ai/api/v1",
        apiKey: String,
        siteURL: String? = nil,
        siteName: String? = nil,
        session: URLSession = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.siteURL = siteURL
        self.siteName = siteName
        self.session = session
    }
    
    // Main async function to make a chat completion request
    public func sendChatRequest(request: OpenRouterRequest) async throws -> OpenRouterResponse {
        // Create the URL request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }
        
        // Encode the request body
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        // Make the network call
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle errors based on HTTP status code
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
            return decodedResponse
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    public func listModels(
        category: String? = nil,
        supportedParameters: String? = nil,
        useRSS: String? = nil,
        useRSSChatLinks: String? = nil
    ) async throws -> ModelsListResponse {
        var components = URLComponents(string: "\(baseURL)/models")
        var queryItems: [URLQueryItem] = []
        if let category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let supportedParameters {
            queryItems.append(URLQueryItem(name: "supported_parameters", value: supportedParameters))
        }
        if let useRSS {
            queryItems.append(URLQueryItem(name: "use_rss", value: useRSS))
        }
        if let useRSSChatLinks {
            queryItems.append(URLQueryItem(name: "use_rss_chat_links", value: useRSSChatLinks))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(ModelsListResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    public func listModelsForUser() async throws -> ModelsListResponse {
        guard let url = URL(string: "\(baseURL)/models/user") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(ModelsListResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    // MARK: - API Keys Methods

    /// List all API keys
    /// - Parameters:
    ///   - includeDisabled: Whether to include disabled API keys in the response
    ///   - offset: Number of API keys to skip for pagination
    /// - Returns: A list of API keys
    public func listKeys(
        includeDisabled: Bool? = nil,
        offset: String? = nil
    ) async throws -> APIKeyListResponse {
        var components = URLComponents(string: "\(baseURL)/keys")
        var queryItems: [URLQueryItem] = []
        if let includeDisabled {
            queryItems.append(URLQueryItem(name: "include_disabled", value: String(includeDisabled)))
        }
        if let offset {
            queryItems.append(URLQueryItem(name: "offset", value: offset))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(APIKeyListResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    /// Create a new API key
    /// - Parameter request: The request containing the API key details
    /// - Returns: The created API key information including the actual key string
    public func createKey(request: CreateAPIKeyRequest) async throws -> CreateAPIKeyResponse {
        guard let url = URL(string: "\(baseURL)/keys") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 201 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(CreateAPIKeyResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    /// Get a single API key by its hash
    /// - Parameter hash: The hash identifier of the API key to retrieve
    /// - Returns: The API key information
    public func getKey(hash: String) async throws -> APIKeyResponse {
        guard let url = URL(string: "\(baseURL)/keys/\(hash)") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(APIKeyResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    /// Update an API key
    /// - Parameters:
    ///   - hash: The hash identifier of the API key to update
    ///   - request: The request containing the fields to update
    /// - Returns: The updated API key information
    public func updateKey(hash: String, request: UpdateAPIKeyRequest) async throws -> APIKeyResponse {
        guard let url = URL(string: "\(baseURL)/keys/\(hash)") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(APIKeyResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    /// Delete an API key
    /// - Parameter hash: The hash identifier of the API key to delete
    /// - Returns: Confirmation that the API key was deleted
    public func deleteKey(hash: String) async throws -> DeleteAPIKeyResponse {
        guard let url = URL(string: "\(baseURL)/keys/\(hash)") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(DeleteAPIKeyResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    /// Get information on the API key associated with the current authentication session
    /// - Returns: Current API key information
    public func getCurrentKey() async throws -> CurrentAPIKeyResponse {
        guard let url = URL(string: "\(baseURL)/key") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if let siteURL = siteURL {
            urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        if let siteName = siteName {
            urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
        }
        do {
            return try JSONDecoder().decode(CurrentAPIKeyResponse.self, from: data)
        } catch {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw OpenRouterError(httpStatusCode: errorResponse?.error.code ?? httpResponse.statusCode, errorResponse: errorResponse)
        }
    }

    #if canImport(Darwin)
    @available(iOS 15.0, macOS 12.0, *)
    public func streamChatRequest(request: OpenRouterRequest) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                var request = request
                request.stream = true
                do {
                    guard let url = URL(string: "\(baseURL)/chat/completions") else {
                        continuation.finish()
                        return
                    }
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    if let siteURL = siteURL {
                        urlRequest.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
                    }
                    if let siteName = siteName {
                        urlRequest.addValue(siteName, forHTTPHeaderField: "X-Title")
                    }
                    
                    let jsonData = try JSONEncoder().encode(request)
                    urlRequest.httpBody = jsonData
                    
                    let (bytes, response) = try await session.bytes(for: urlRequest)
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
                                if let processedLine = processLine(buffer) {
                                    continuation.yield(processedLine)
                                }
                                buffer = ""
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("Error: \(error)")
                    continuation.finish()
                }
            }
        }
    }

    private func processLine(_ line: String) -> String? {
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
    #endif
}

// Define the ErrorResponse type
struct ErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let code: Int
        let message: String
        let metadata: [String: String]?
    }
    let error: ErrorDetail
}

// Define the OpenRouterError struct
public struct OpenRouterError: Error {
    public let type: ErrorType
    public let message: String
    public let metadata: [String: String]?
    
    public enum ErrorType: Sendable {
        case badRequest
        case invalidCredentials
        case insufficientCredits
        case moderationError
        case requestTimeout
        case rateLimited
        case modelDown
        case noAvailableProvider
        case unknownError(Int)
    }

    init(httpStatusCode: Int, errorResponse: ErrorResponse?) {
        self.message = errorResponse?.error.message ?? "Unknown error occurred"
        self.metadata = errorResponse?.error.metadata

        switch httpStatusCode {
        case 400:
            self.type = .badRequest
        case 401:
            self.type = .invalidCredentials
        case 402:
            self.type = .insufficientCredits
        case 403:
            self.type = .moderationError
        case 408:
            self.type = .requestTimeout
        case 429:
            self.type = .rateLimited
        case 502:
            self.type = .modelDown
        case 503:
            self.type = .noAvailableProvider
        default:
            self.type = .unknownError(httpStatusCode)
        }
    }

    var localizedDescription: String {
        switch type {
        case .badRequest:
            return "Bad Request: \(message)"
        case .invalidCredentials:
            return "Invalid Credentials: \(message)"
        case .insufficientCredits:
            return "Insufficient Credits: \(message)"
        case .moderationError:
            return "Moderation Error: \(message)"
        case .requestTimeout:
            return "Request Timeout: \(message)"
        case .rateLimited:
            return "Rate Limited: \(message)"
        case .modelDown:
            return "Model Down: \(message)"
        case .noAvailableProvider:
            return "No Available Provider: \(message)"
        case .unknownError(let code):
            return "Unknown Error (\(code)): \(message)"
        }
    }
}
