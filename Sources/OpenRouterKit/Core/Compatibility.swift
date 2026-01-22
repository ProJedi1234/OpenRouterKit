//
//  Compatibility.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

// MARK: - Type Aliases for Backward Compatibility

/// Type alias for backward compatibility.
/// Use `ChatRequest` instead.
public typealias OpenRouterRequest = ChatRequest

/// Type alias for backward compatibility.
/// Use `ChatResponse` instead.
public typealias OpenRouterResponse = ChatResponse

/// Example of how to create an instance of the request.
///
/// ```swift
/// let request = exampleRequest
/// let response = try await client.chat.send(request: request)
/// ```
public let exampleRequest = ChatRequest(
    messages: [
        Message(role: .user, content: .string("Who are you?"))
    ],
    model: "mistralai/mixtral-8x7b-instruct"
)
