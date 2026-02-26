//
//  ToolCall.swift
//  OpenRouterKit
//
//  Types for tool call support in the OpenRouter API.
//

import Foundation

/// Represents a tool call made by the model in a response.
///
/// When the model decides to call a tool, it returns one or more `ToolCall` objects
/// in the assistant message. Each tool call has a unique ID that must be referenced
/// when sending the tool result back.
///
/// Example response tool call:
/// ```swift
/// let toolCall = response.choices[0].message.toolCalls?[0]
/// print(toolCall?.id)             // "call_abc123"
/// print(toolCall?.function.name)  // "get_weather"
/// print(toolCall?.function.arguments) // "{\"location\":\"New York\"}"
/// ```
public struct ToolCall: Codable, Sendable, Equatable {
    /// Unique identifier for this tool call.
    /// Must be referenced when sending the tool result back.
    public let id: String

    /// The type of tool call. Currently always "function".
    public let type: String

    /// The function the model wants to call.
    public let function: ToolCallFunction

    /// Creates a new tool call.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this tool call
    ///   - type: The type of tool call (default: "function")
    ///   - function: The function to call
    public init(id: String, type: String = "function", function: ToolCallFunction) {
        self.id = id
        self.type = type
        self.function = function
    }
}

/// Represents the function details within a tool call.
///
/// Contains the function name and arguments as a JSON string.
public struct ToolCallFunction: Codable, Sendable, Equatable {
    /// The name of the function to call.
    public let name: String

    /// The arguments to pass to the function, as a JSON string.
    public let arguments: String

    /// Creates a new tool call function.
    ///
    /// - Parameters:
    ///   - name: The function name
    ///   - arguments: The arguments as a JSON string
    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }
}

/// Represents a partial tool call in a streaming delta.
///
/// During streaming, tool calls arrive incrementally. The index identifies
/// which tool call is being updated, and the function name and arguments
/// may arrive across multiple deltas.
public struct ToolCallDelta: Codable, Sendable {
    /// Index of this tool call in the tool_calls array.
    public let index: Int

    /// Unique identifier for this tool call (present in the first delta).
    public let id: String?

    /// The type of tool call (present in the first delta).
    public let type: String?

    /// Partial function information.
    public let function: ToolCallFunctionDelta?

    /// Creates a new tool call delta.
    ///
    /// - Parameters:
    ///   - index: Index of this tool call
    ///   - id: Optional tool call ID
    ///   - type: Optional tool call type
    ///   - function: Optional partial function info
    public init(index: Int, id: String? = nil, type: String? = nil, function: ToolCallFunctionDelta? = nil) {
        self.index = index
        self.id = id
        self.type = type
        self.function = function
    }
}

/// Represents partial function information in a streaming tool call delta.
public struct ToolCallFunctionDelta: Codable, Sendable {
    /// The function name (may only be present in the first delta).
    public let name: String?

    /// A chunk of the function arguments string.
    public let arguments: String?

    /// Creates a new tool call function delta.
    ///
    /// - Parameters:
    ///   - name: Optional function name
    ///   - arguments: Optional arguments chunk
    public init(name: String? = nil, arguments: String? = nil) {
        self.name = name
        self.arguments = arguments
    }
}
