//
//  Tool.swift
//  OpenRouterKit
//
//  Request-side tool definitions for the OpenRouter chat API.
//

import Foundation

/// Represents a tool available for use in a chat request.
///
/// Example:
/// ```swift
/// let tool = Tool(function: FunctionDescription(
///     name: "get_weather",
///     description: "Get the current weather for a location",
///     parameters: .object([
///         "type": .string("object"),
///         "properties": .object([
///             "location": .object([
///                 "type": .string("string"),
///                 "description": .string("The city and state")
///             ])
///         ]),
///         "required": .array([.string("location")])
///     ])
/// ))
/// ```
public struct Tool: Codable, Sendable {
    /// The type of the tool. Currently always "function".
    public let type: String

    /// The function associated with the tool.
    public let function: FunctionDescription

    /// Creates a new tool.
    ///
    /// - Parameters:
    ///   - type: The type of tool (default: "function")
    ///   - function: The function description
    public init(type: String = "function", function: FunctionDescription) {
        self.type = type
        self.function = function
    }
}

/// Represents the function description of a tool.
///
/// The `parameters` field should be a JSON Schema object describing the function's parameters.
public struct FunctionDescription: Codable, Sendable {
    /// The name of the function.
    public let name: String

    /// Optional description of what the function does.
    public let description: String?

    /// JSON Schema describing the function's parameters.
    public let parameters: JSONValue

    /// Whether to enable strict schema adherence (optional).
    public let strict: Bool?

    /// Creates a new function description.
    ///
    /// - Parameters:
    ///   - name: The function name
    ///   - description: Optional description of the function
    ///   - parameters: JSON Schema for the function parameters
    ///   - strict: Whether to enable strict schema adherence
    public init(name: String, description: String? = nil, parameters: JSONValue, strict: Bool? = nil) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.strict = strict
    }
}

/// Represents the choice of tools in a chat request.
///
/// Controls how the model selects tools:
/// - `.none`: The model will not call any tools
/// - `.auto`: The model decides whether to call tools (default behavior)
/// - `.required`: The model must call at least one tool
/// - `.function(name:)`: The model must call the specified function
public enum ToolChoice: Codable, Sendable {
    /// No tools should be used.
    case none
    /// Automatically choose tools (default).
    case auto
    /// The model must call at least one tool.
    case required
    /// Use a specific function by name.
    case function(name: String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as a string first ("none", "auto", "required")
        if let stringValue = try? container.decode(String.self) {
            switch stringValue {
            case "none":
                self = .none
            case "auto":
                self = .auto
            case "required":
                self = .required
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid tool choice string: \(stringValue)"
                )
            }
            return
        }

        // Try decoding as an object {"type": "function", "function": {"name": "..."}}
        let objectContainer = try decoder.container(keyedBy: ToolChoiceCodingKeys.self)
        let type = try objectContainer.decode(String.self, forKey: .type)
        if type == "function" {
            let functionObj = try objectContainer.decode(ToolChoiceFunction.self, forKey: .function)
            self = .function(name: functionObj.name)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: objectContainer,
                debugDescription: "Invalid tool choice type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .none:
            var container = encoder.singleValueContainer()
            try container.encode("none")
        case .auto:
            var container = encoder.singleValueContainer()
            try container.encode("auto")
        case .required:
            var container = encoder.singleValueContainer()
            try container.encode("required")
        case .function(let name):
            var container = encoder.container(keyedBy: ToolChoiceCodingKeys.self)
            try container.encode("function", forKey: .type)
            try container.encode(ToolChoiceFunction(name: name), forKey: .function)
        }
    }

    private enum ToolChoiceCodingKeys: String, CodingKey {
        case type
        case function
    }

    private struct ToolChoiceFunction: Codable, Sendable {
        let name: String
    }
}
