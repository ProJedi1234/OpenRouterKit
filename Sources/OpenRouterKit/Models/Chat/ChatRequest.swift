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
