//
//  JSONValue.swift
//  OpenRouterKit
//
//  Represents arbitrary JSON values for tool parameters and arguments.
//

import Foundation

/// A type that can represent any JSON value.
///
/// Used primarily for encoding/decoding tool function parameters (JSON Schema)
/// and other arbitrary JSON structures in the OpenRouter API.
///
/// Example:
/// ```swift
/// let schema: JSONValue = .object([
///     "type": .string("object"),
///     "properties": .object([
///         "location": .object([
///             "type": .string("string"),
///             "description": .string("The city name")
///         ])
///     ]),
///     "required": .array([.string("location")])
/// ])
/// ```
public enum JSONValue: Codable, Sendable, Equatable {
    /// A JSON string value.
    case string(String)
    /// A JSON number value (integer).
    case int(Int)
    /// A JSON number value (floating point).
    case double(Double)
    /// A JSON boolean value.
    case bool(Bool)
    /// A JSON null value.
    case null
    /// A JSON array value.
    case array([JSONValue])
    /// A JSON object value.
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: JSONValue].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Failed to decode JSONValue"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}
