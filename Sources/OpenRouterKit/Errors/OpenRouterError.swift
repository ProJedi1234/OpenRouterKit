//
//  OpenRouterError.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Internal error response structure from the OpenRouter API
package struct ErrorResponse: Decodable {
    package struct ErrorDetail: Decodable {
        package let code: Int
        package let message: String
        package let metadata: [String: String]?
    }
    package let error: ErrorDetail
}

/// Errors that can occur when interacting with the OpenRouter API.
///
/// `OpenRouterError` provides detailed error information including the error type,
/// message, and optional metadata returned from the API.
public struct OpenRouterError: Error {
    /// The type of error that occurred
    public let type: ErrorType
    
    /// Human-readable error message
    public let message: String
    
    /// Optional metadata associated with the error
    public let metadata: [String: String]?
    
    /// Enumeration of error types that can occur
    public enum ErrorType: Sendable {
        /// Bad request (400)
        case badRequest
        /// Invalid credentials (401)
        case invalidCredentials
        /// Insufficient credits (402)
        case insufficientCredits
        /// Moderation error (403)
        case moderationError
        /// Request timeout (408)
        case requestTimeout
        /// Rate limited (429)
        case rateLimited
        /// Model down (502)
        case modelDown
        /// No available provider (503)
        case noAvailableProvider
        /// Unknown error with HTTP status code
        case unknownError(Int)
        /// Streaming is not available with URLSession on this platform.
        /// Use OpenRouterKitNIO for cross-platform streaming support.
        case streamingUnavailable
    }

    /// Creates a streaming-unavailable error for non-Darwin platforms.
    static let streamingUnavailable = OpenRouterError(
        type: .streamingUnavailable,
        message: "Streaming requires Darwin (macOS/iOS) or OpenRouterKitNIO. Import OpenRouterKitNIO and use OpenRouterClient.nio(apiKey:) for cross-platform streaming.",
        metadata: nil
    )

    package init(httpStatusCode: Int, errorResponse: ErrorResponse?) {
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

    /// A localized description of the error
    public var localizedDescription: String {
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
        case .streamingUnavailable:
            return "Streaming Unavailable: \(message)"
        }
    }
}
