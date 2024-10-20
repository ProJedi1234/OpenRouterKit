//
//  OpenRouterRequest.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/17/24.
//

import Foundation

/// Represents a request to the OpenRouter API.
public struct OpenRouterRequest: Codable, Sendable {
    /// Either "messages" or "prompt" is required.
    public var messages: [Message]?
    public var prompt: String?
    
    /// Model parameter.
    public var model: String?
    
    /// Response format.
    public var responseFormat: ResponseFormat?
    
    /// Text indicating where to stop generating.
    public var stop: [String]?
    
    /// Enable streaming.
    public var stream: Bool?
    
    /// Maximum number of tokens to generate.
    public var maxTokens: Int?
    
    /// Sampling temperature; lower values mean more conservative sampling.
    public var temperature: Float?
    
    /// Nucleus sampling parameter.
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
    
    /// List of models to use.
    public var models: [String]?
    
    /// Route option, possible values: 'fallback'.
    public var route: String?
    
    /// Provider-specific preferences.
    public var provider: ProviderPreferences?

    enum CodingKeys: String, CodingKey {
        case messages, prompt, model, responseFormat = "response_format", stop, stream,
             maxTokens = "max_tokens", temperature, topP = "top_p", topK = "top_k",
             frequencyPenalty = "frequency_penalty", presencePenalty = "presence_penalty",
             repetitionPenalty = "repetition_penalty", seed, tools, toolChoice = "tool_choice",
             logitBias = "logit_bias", transforms, models, route, provider
    }
    
    public init(messages: [Message]? = nil, prompt: String? = nil, model: String? = nil, responseFormat: ResponseFormat? = nil, stop: [String]? = nil, stream: Bool? = nil, maxTokens: Int? = nil, temperature: Float? = nil, topP: Float? = nil, topK: Int? = nil, frequencyPenalty: Float? = nil, presencePenalty: Float? = nil, repetitionPenalty: Float? = nil, seed: Int? = nil, tools: [Tool]? = nil, toolChoice: ToolChoice? = nil, logitBias: [Int : Float]? = nil, transforms: [String]? = nil, models: [String]? = nil, route: String? = nil, provider: ProviderPreferences? = nil) {
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
    }
}

/// Represents a message within the OpenRouter request.
public struct Message: Codable, Sendable {
    /// The role of the sender.
    public var role: Role
    
    /// The content of the message.
    public var content: StringOrContentPart

    /// Optional name for identifying the sender.
    public var name: String?

    /// The role enum representing the sender's role.
    public enum Role: String, Codable, Sendable {
        case user, assistant, system, tool
    }
    
    public init(role: Role, content: StringOrContentPart, name: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
    }
}

/// Represents the content of a message, which can be either a string or an array of content parts.
public enum StringOrContentPart: Codable, Sendable {
    case string(String)
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
    case text(TextContent)
    case image(ImageContentPart)

    enum CodingKeys: String, CodingKey {
        case type
    }

    /// Decoder initializer to handle different content types.
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

    /// Encoder to handle different content types.
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

/// Represents text content in the OpenRouter request.
public struct TextContent: Codable, Sendable {
    /// The type of content, should be "text".
    public let type: String
    
    /// The actual text content.
    public let text: String
}

/// Represents image content in the OpenRouter request.
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

/// Represents an image URL and optional detail in the OpenRouter request.
public struct ImageUrl: Codable, Sendable {
    /// The image URL or base64 encoded image data.
    public let url: String
    
    /// Optional detail string for the image.
    public let detail: String?
}

/// Represents a tool available for the OpenRouter request.
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
    
    /// Parameters for the function, now defined more specifically.
    public let parameters: [String: String]
}

/// Represents the choice of tools in the OpenRouter request.
public enum ToolChoice: Codable, Sendable {
    case none
    case auto
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
}

/// Represents provider preferences in the OpenRouter request.
public struct ProviderPreferences: Codable, Sendable {
    // Define properties based on the documentation
}

/// Example of how to create an instance of the request.
public let exampleRequest = OpenRouterRequest(
    messages: [
        Message(role: .user, content: .string("Who are you?"))
    ],
    model: "mistralai/mixtral-8x7b-instruct"
)
