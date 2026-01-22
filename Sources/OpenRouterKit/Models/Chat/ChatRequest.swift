//
//  ChatRequest.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/17/24.
//

import Foundation

/// Represents a request to the OpenRouter chat completions API.
///
/// Use `ChatRequest` to configure a chat completion request with messages,
/// model selection, and various generation parameters.
///
/// Example:
/// ```swift
/// let request = ChatRequest(
///     messages: [Message(role: .user, content: .string("Hello!"))],
///     model: "mistralai/mixtral-8x7b-instruct",
///     temperature: 0.7
/// )
/// ```
public struct ChatRequest: Codable, Sendable {
    /// Either "messages" or "prompt" is required.
    public var messages: [Message]?
    
    /// Alternative to messages - a simple prompt string.
    public var prompt: String?
    
    /// Model identifier to use for the completion.
    public var model: String?
    
    /// Response format configuration.
    public var responseFormat: ResponseFormat?
    
    /// Text indicating where to stop generating.
    public var stop: [String]?
    
    /// Enable streaming responses.
    public var stream: Bool?
    
    /// Maximum number of tokens to generate.
    public var maxTokens: Int?
    
    /// Sampling temperature; lower values mean more conservative sampling.
    /// Range typically 0.0 to 2.0.
    public var temperature: Float?
    
    /// Nucleus sampling parameter. Controls diversity via nucleus sampling.
    public var topP: Float?
    
    /// The total number of tokens to consider (not available for OpenAI models).
    public var topK: Int?
    
    /// Frequency penalty; the higher the value, the less often words will be repeated.
    public var frequencyPenalty: Float?
    
    /// Presence penalty; increases the likelihood of the model talking about new topics.
    public var presencePenalty: Float?
    
    /// Repetition penalty; penalizes repeating phrases.
    public var repetitionPenalty: Float?
    
    /// Seed for random generation (specific to OpenAI).
    public var seed: Int?
    
    /// List of tools available for use.
    public var tools: [Tool]?
    
    /// Choice of tool for the request.
    public var toolChoice: ToolChoice?
    
    /// Logit bias for modifying the generation process.
    public var logitBias: [Int: Float]?
    
    /// Transforms to apply to the input prompt.
    public var transforms: [String]?
    
    /// List of models to use (for routing).
    public var models: [String]?
    
    /// Route option, possible values: 'fallback'.
    public var route: String?
    
    /// Provider-specific preferences.
    public var provider: ProviderPreferences?
    
    /// Reasoning configuration for advanced reasoning capabilities.
    public var reasoning: ReasoningConfiguration?

    enum CodingKeys: String, CodingKey {
        case messages, prompt, model, responseFormat = "response_format", stop, stream,
             maxTokens = "max_tokens", temperature, topP = "top_p", topK = "top_k",
             frequencyPenalty = "frequency_penalty", presencePenalty = "presence_penalty",
             repetitionPenalty = "repetition_penalty", seed, tools, toolChoice = "tool_choice",
             logitBias = "logit_bias", transforms, models, route, provider, reasoning
    }
    
    /// Creates a new chat request.
    ///
    /// - Parameters:
    ///   - messages: Array of messages in the conversation
    ///   - prompt: Alternative to messages - a simple prompt string
    ///   - model: Model identifier to use
    ///   - responseFormat: Response format configuration
    ///   - stop: Stop sequences
    ///   - stream: Enable streaming
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Sampling temperature
    ///   - topP: Nucleus sampling parameter
    ///   - topK: Top-K sampling parameter
    ///   - frequencyPenalty: Frequency penalty value
    ///   - presencePenalty: Presence penalty value
    ///   - repetitionPenalty: Repetition penalty value
    ///   - seed: Random seed
    ///   - tools: Available tools
    ///   - toolChoice: Tool choice configuration
    ///   - logitBias: Logit bias map
    ///   - transforms: Transforms to apply
    ///   - models: List of models for routing
    ///   - route: Route option
    ///   - provider: Provider preferences
    ///   - reasoning: Reasoning configuration
    public init(
        messages: [Message]? = nil,
        prompt: String? = nil,
        model: String? = nil,
        responseFormat: ResponseFormat? = nil,
        stop: [String]? = nil,
        stream: Bool? = nil,
        maxTokens: Int? = nil,
        temperature: Float? = nil,
        topP: Float? = nil,
        topK: Int? = nil,
        frequencyPenalty: Float? = nil,
        presencePenalty: Float? = nil,
        repetitionPenalty: Float? = nil,
        seed: Int? = nil,
        tools: [Tool]? = nil,
        toolChoice: ToolChoice? = nil,
        logitBias: [Int: Float]? = nil,
        transforms: [String]? = nil,
        models: [String]? = nil,
        route: String? = nil,
        provider: ProviderPreferences? = nil,
        reasoning: ReasoningConfiguration? = nil
    ) {
        self.messages = messages
        self.prompt = prompt
        self.model = model
        self.responseFormat = responseFormat
        self.stop = stop
        self.stream = stream
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.repetitionPenalty = repetitionPenalty
        self.seed = seed
        self.tools = tools
        self.toolChoice = toolChoice
        self.logitBias = logitBias
        self.transforms = transforms
        self.models = models
        self.route = route
        self.provider = provider
        self.reasoning = reasoning
    }
}

/// Represents a message within a chat request.
///
/// Messages are the building blocks of a conversation with the model.
public struct Message: Codable, Sendable {
    /// The role of the sender.
    public var role: Role
    
    /// The content of the message.
    public var content: StringOrContentPart

    /// Optional name for identifying the sender.
    public var name: String?

    /// The role enum representing the sender's role.
    public enum Role: String, Codable, Sendable {
        /// User message
        case user
        /// Assistant message
        case assistant
        /// System message
        case system
        /// Tool message
        case tool
    }
    
    /// Creates a new message.
    ///
    /// - Parameters:
    ///   - role: The role of the message sender
    ///   - content: The message content (string or content parts)
    ///   - name: Optional name for the sender
    public init(role: Role, content: StringOrContentPart, name: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
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

/// Represents a tool available for use in a chat request.
public struct Tool: Codable, Sendable {
    /// The type of the tool.
    public let type: String
    
    /// The function associated with the tool.
    public let function: FunctionDescription
}

/// Represents the function description of a tool.
public struct FunctionDescription: Codable, Sendable {
    /// Optional description of the function.
    public let description: String?
    
    /// The name of the function.
    public let name: String
    
    /// Parameters for the function.
    public let parameters: [String: String]
}

/// Represents the choice of tools in a chat request.
public enum ToolChoice: Codable, Sendable {
    /// No tools should be used
    case none
    /// Automatically choose tools
    case auto
    /// Use a specific function
    case function(Function)

    /// Represents a specific function choice.
    public struct Function: Codable, Sendable {
        /// The name of the function.
        public let name: String
    }
}

/// Represents the format of the response from the OpenRouter API.
public struct ResponseFormat: Codable, Sendable {
    /// The type of the response format.
    public let type: String
    
    /// Creates a new response format.
    ///
    /// - Parameter type: The format type (e.g., "json_object")
    public init(type: String) {
        self.type = type
    }
}

/// Represents provider preferences in a chat request.
public struct ProviderPreferences: Codable, Sendable {
    /// Ordered list of preferred providers.
    public let order: [String]
    
    /// Creates new provider preferences.
    ///
    /// - Parameter order: Ordered list of provider names
    public init(order: [String]) {
        self.order = order
    }
}

/// Represents reasoning configuration for advanced reasoning capabilities.
public struct ReasoningConfiguration: Codable, Sendable {
    /// The effort level for reasoning.
    public var effort: ReasoningEffort
    
    /// Creates a new reasoning configuration.
    ///
    /// - Parameter effort: The reasoning effort level
    public init(effort: ReasoningEffort) {
        self.effort = effort
    }
}

/// Represents the effort level for reasoning.
public enum ReasoningEffort: String, Codable, Sendable {
    /// Basic reasoning with minimal computational effort.
    case minimal
    /// Light reasoning for simple problems.
    case low
    /// Balanced reasoning for moderate complexity.
    case medium
    /// Deep reasoning for complex problems.
    case high
}
