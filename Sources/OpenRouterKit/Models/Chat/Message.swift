//
//  Message.swift
//  OpenRouterKit
//
//  Message and content types for the OpenRouter chat API.
//

import Foundation

/// Represents a message within a chat request.
///
/// Messages are the building blocks of a conversation with the model.
/// Supports regular text messages, assistant messages with tool calls,
/// and tool result messages.
///
/// Example - regular message:
/// ```swift
/// Message(role: .user, content: .string("What's the weather?"))
/// ```
///
/// Example - tool result message:
/// ```swift
/// Message(role: .tool, content: .string("{\"temp\": 72}"), toolCallId: "call_abc123")
/// ```
public struct Message: Codable, Sendable {
    /// The role of the sender.
    public var role: Role

    /// The content of the message. Optional for assistant messages with tool calls.
    public var content: StringOrContentPart?

    /// Optional name for identifying the sender.
    public var name: String?

    /// Tool calls made by the assistant. Present in assistant messages
    /// when the model decides to call one or more tools.
    public var toolCalls: [ToolCall]?

    /// The ID of the tool call this message is responding to.
    /// Required for messages with role `.tool`.
    public var toolCallId: String?

    /// The role enum representing the sender's role.
    public enum Role: String, Codable, Sendable {
        /// User message
        case user
        /// Assistant message
        case assistant
        /// System message
        case system
        /// Tool result message
        case tool
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case name
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }

    /// Creates a new message.
    ///
    /// - Parameters:
    ///   - role: The role of the message sender
    ///   - content: The message content (string or content parts)
    ///   - name: Optional name for the sender
    ///   - toolCalls: Optional tool calls (for assistant messages)
    ///   - toolCallId: Optional tool call ID (for tool result messages)
    public init(
        role: Role,
        content: StringOrContentPart? = nil,
        name: String? = nil,
        toolCalls: [ToolCall]? = nil,
        toolCallId: String? = nil
    ) {
        self.role = role
        self.content = content
        self.name = name
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }
}

/// Represents the content of a message, which can be either a string or an array of content parts.
public enum StringOrContentPart: Codable, Sendable {
    /// Simple string content
    case string(String)
    /// Array of content parts (text, images, etc.)
    case contentParts([ContentPart])

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let contentPartsValue = try? container.decode([ContentPart].self) {
            self = .contentParts(contentPartsValue)
        } else {
            throw DecodingError.typeMismatch(StringOrContentPart.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to decode StringOrContentPart"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .contentParts(let value):
            try container.encode(value)
        }
    }
}

/// Represents the content of a message, which can be either text or an image.
public enum ContentPart: Codable, Sendable {
    /// Text content
    case text(TextContent)
    /// Image content
    case image(ImageContentPart)

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let textContent = try TextContent(from: decoder)
            self = .text(textContent)
        case "image_url":
            let imageContent = try ImageContentPart(from: decoder)
            self = .image(imageContent)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container,
                debugDescription: "Invalid type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let textContent):
            try container.encode("text", forKey: .type)
            try textContent.encode(to: encoder)
        case .image(let imageContent):
            try container.encode("image_url", forKey: .type)
            try imageContent.encode(to: encoder)
        }
    }
}

/// Represents text content in a chat request.
public struct TextContent: Codable, Sendable {
    /// The type of content, should be "text".
    public let type: String

    /// The actual text content.
    public let text: String
}

/// Represents image content in a chat request.
public struct ImageContentPart: Codable, Sendable {
    /// The type of content, should be "image_url".
    public let type: String

    /// The URL of the image.
    public let imageURL: ImageUrl

    enum CodingKeys: String, CodingKey {
        case type
        case imageURL = "image_url"
    }
}

/// Represents an image URL and optional detail in a chat request.
public struct ImageUrl: Codable, Sendable {
    /// The image URL or base64 encoded image data.
    public let url: String

    /// Optional detail string for the image.
    public let detail: String?
}
