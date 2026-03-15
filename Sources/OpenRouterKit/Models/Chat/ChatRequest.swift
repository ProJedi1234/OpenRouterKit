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

    /// Maximum number of completion tokens to generate (replacement for deprecated `maxTokens`).
    public var maxCompletionTokens: Int?

    /// Options for streaming responses (e.g., include usage statistics).
    public var streamOptions: StreamOptions?

    /// Whether to return log probabilities of the output tokens.
    public var logprobs: Bool?

    /// Number of most likely tokens to return at each position (0-20). Requires `logprobs` to be true.
    public var topLogprobs: Int?

    /// Whether to allow parallel tool calls.
    public var parallelToolCalls: Bool?

    /// Output modalities to generate (e.g., text, image, audio).
    public var modalities: [String]?

    /// A unique identifier representing the end-user.
    public var user: String?

    /// Key-value metadata pairs for the request (max 16 pairs).
    public var metadata: [String: String]?

    /// Session ID to group related requests.
    public var sessionId: String?

    /// Observability trace configuration.
    public var trace: Trace?

    /// Prompt caching configuration.
    public var cacheControl: CacheControl?

    /// Debug options (streaming only).
    public var debug: DebugOptions?

    /// Provider-specific image generation options.
    public var imageConfig: ImageConfig?

    enum CodingKeys: String, CodingKey {
        case messages, prompt, model, responseFormat = "response_format", stop, stream,
             maxTokens = "max_tokens", temperature, topP = "top_p", topK = "top_k",
             frequencyPenalty = "frequency_penalty", presencePenalty = "presence_penalty",
             repetitionPenalty = "repetition_penalty", seed, tools, toolChoice = "tool_choice",
             logitBias = "logit_bias", transforms, models, route, provider, reasoning,
             maxCompletionTokens = "max_completion_tokens",
             streamOptions = "stream_options", logprobs,
             topLogprobs = "top_logprobs",
             parallelToolCalls = "parallel_tool_calls",
             modalities, user, metadata,
             sessionId = "session_id", trace,
             cacheControl = "cache_control", debug,
             imageConfig = "image_config"
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
    ///   - maxCompletionTokens: Maximum completion tokens (replacement for deprecated maxTokens)
    ///   - streamOptions: Options for streaming responses
    ///   - logprobs: Whether to return log probabilities
    ///   - topLogprobs: Number of most likely tokens to return (0-20)
    ///   - parallelToolCalls: Whether to allow parallel tool calls
    ///   - modalities: Output modalities to generate
    ///   - user: End-user identifier
    ///   - metadata: Key-value metadata pairs (max 16 pairs)
    ///   - sessionId: Session ID to group related requests
    ///   - trace: Observability trace configuration
    ///   - cacheControl: Prompt caching configuration
    ///   - debug: Debug options (streaming only)
    ///   - imageConfig: Provider-specific image generation options
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
        reasoning: ReasoningConfiguration? = nil,
        maxCompletionTokens: Int? = nil,
        streamOptions: StreamOptions? = nil,
        logprobs: Bool? = nil,
        topLogprobs: Int? = nil,
        parallelToolCalls: Bool? = nil,
        modalities: [String]? = nil,
        user: String? = nil,
        metadata: [String: String]? = nil,
        sessionId: String? = nil,
        trace: Trace? = nil,
        cacheControl: CacheControl? = nil,
        debug: DebugOptions? = nil,
        imageConfig: ImageConfig? = nil
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
        self.maxCompletionTokens = maxCompletionTokens
        self.streamOptions = streamOptions
        self.logprobs = logprobs
        self.topLogprobs = topLogprobs
        self.parallelToolCalls = parallelToolCalls
        self.modalities = modalities
        self.user = user
        self.metadata = metadata
        self.sessionId = sessionId
        self.trace = trace
        self.cacheControl = cacheControl
        self.debug = debug
        self.imageConfig = imageConfig
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

/// Options for streaming responses.
public struct StreamOptions: Codable, Sendable {
    /// Whether to include usage statistics in the streaming response.
    public var includeUsage: Bool

    enum CodingKeys: String, CodingKey {
        case includeUsage = "include_usage"
    }

    /// Creates new stream options.
    ///
    /// - Parameter includeUsage: Whether to include usage statistics
    public init(includeUsage: Bool) {
        self.includeUsage = includeUsage
    }
}

/// Observability trace configuration for grouping and labeling requests.
public struct Trace: Codable, Sendable {
    /// Unique identifier for the trace.
    public var traceId: String?

    /// Name for the trace.
    public var traceName: String?

    /// Name for the span.
    public var spanName: String?

    /// Name for the generation.
    public var generationName: String?

    /// Parent span identifier.
    public var parentSpanId: String?

    enum CodingKeys: String, CodingKey {
        case traceId = "trace_id"
        case traceName = "trace_name"
        case spanName = "span_name"
        case generationName = "generation_name"
        case parentSpanId = "parent_span_id"
    }

    /// Creates a new trace configuration.
    ///
    /// - Parameters:
    ///   - traceId: Unique identifier for the trace
    ///   - traceName: Name for the trace
    ///   - spanName: Name for the span
    ///   - generationName: Name for the generation
    ///   - parentSpanId: Parent span identifier
    public init(
        traceId: String? = nil,
        traceName: String? = nil,
        spanName: String? = nil,
        generationName: String? = nil,
        parentSpanId: String? = nil
    ) {
        self.traceId = traceId
        self.traceName = traceName
        self.spanName = spanName
        self.generationName = generationName
        self.parentSpanId = parentSpanId
    }
}

/// Prompt caching configuration.
public struct CacheControl: Codable, Sendable {
    /// The type of cache control (e.g., "ephemeral").
    public var type: String

    /// Creates a new cache control configuration.
    ///
    /// - Parameter type: The cache control type
    public init(type: String) {
        self.type = type
    }
}

/// Debug options for streaming requests.
public struct DebugOptions: Codable, Sendable {
    /// Whether to echo the upstream request body in the response.
    public var echoUpstreamBody: Bool?

    enum CodingKeys: String, CodingKey {
        case echoUpstreamBody = "echo_upstream_body"
    }

    /// Creates new debug options.
    ///
    /// - Parameter echoUpstreamBody: Whether to echo the upstream body
    public init(echoUpstreamBody: Bool? = nil) {
        self.echoUpstreamBody = echoUpstreamBody
    }
}

/// Provider-specific image generation options.
public struct ImageConfig: Codable, Sendable {
    /// Image width.
    public var width: Int?

    /// Image height.
    public var height: Int?

    /// Number of inference steps.
    public var steps: Int?

    /// Classifier-free guidance scale.
    public var guidanceScale: Float?

    /// Seed for image generation.
    public var seed: Int?

    enum CodingKeys: String, CodingKey {
        case width, height, steps
        case guidanceScale = "guidance_scale"
        case seed
    }

    /// Creates a new image configuration.
    ///
    /// - Parameters:
    ///   - width: Image width
    ///   - height: Image height
    ///   - steps: Number of inference steps
    ///   - guidanceScale: Classifier-free guidance scale
    ///   - seed: Seed for image generation
    public init(
        width: Int? = nil,
        height: Int? = nil,
        steps: Int? = nil,
        guidanceScale: Float? = nil,
        seed: Int? = nil
    ) {
        self.width = width
        self.height = height
        self.steps = steps
        self.guidanceScale = guidanceScale
        self.seed = seed
    }
}
