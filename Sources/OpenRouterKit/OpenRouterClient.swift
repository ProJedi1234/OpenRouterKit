//
//  OpenRouterClient.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

// Define the OpenRouterClient
public final class OpenRouterClient: Sendable {
    private let apiKey: String
    private let baseUrl: String
    private let session: URLSession
    private let siteURL: String?
    private let siteName: String?
    
    public init(baseURL: String = "https://openrouter.ai/api/v1/chat/completions", apiKey: String, siteURL: String? = nil, siteName: String? = nil, session: URLSession = URLSession.shared) {
        self.baseUrl = baseURL
        self.apiKey = apiKey
        self.siteURL = siteURL
        self.siteName = siteName
        self.session = session
    }
    
    // Main async function to make a chat completion request
    public func sendChatRequest(request: OpenRouterRequest) async throws -> OpenRouterResponse {
        // Create the URL request
        var urlRequest = URLRequest(url: URL(string: baseUrl)!)
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
    
    @available(iOS 15.0, *)
    public func streamChatRequest(request: OpenRouterRequest) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                var request = request
                request.stream = true
                do {
                    var urlRequest = URLRequest(url: URL(string: baseUrl)!)
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
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    
                    // Handle errors based on HTTP status code
                    if httpResponse.statusCode != 200 {
                        var collectedData = Data()
                        for try await byte in bytes {
                            collectedData.append(byte)
                        }
                        let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: collectedData)
                        throw OpenRouterError(httpStatusCode: httpResponse.statusCode, errorResponse: errorResponse)
                    }
                    
                    var buffer = ""
                    for try await byte in bytes {
                        if let char = String(bytes: [byte], encoding: .utf8) {
                            buffer += char
                            if char == "\n" {
                                if !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let line = processLine(buffer) {
                                    continuation.yield(line)
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
