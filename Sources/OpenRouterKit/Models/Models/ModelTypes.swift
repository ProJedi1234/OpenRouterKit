//
//  ModelTypes.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/22/24.
//

import Foundation

/// Response containing a list of available models.
public struct ModelsListResponse: Codable, Sendable {
    /// Array of available models.
    public let data: [Model]
}

/// Represents a model available on OpenRouter.
///
/// Contains information about the model including pricing, capabilities, and architecture.
public struct Model: Codable, Sendable {
    /// Unique identifier for the model.
    public let id: String
    
    /// Canonical slug for the model.
    public let canonicalSlug: String
    
    /// Hugging Face identifier (if applicable).
    public let huggingFaceId: String?
    
    /// Display name of the model.
    public let name: String
    
    /// Creation timestamp.
    public let created: Double
    
    /// Description of the model.
    public let description: String?
    
    /// Pricing information.
    public let pricing: PublicPricing
    
    /// Maximum context length.
    public let contextLength: Double?
    
    /// Model architecture information.
    public let architecture: ModelArchitecture
    
    /// Top provider information.
    public let topProvider: TopProviderInfo
    
    /// Per-request limits.
    public let perRequestLimits: PerRequestLimits?
    
    /// Supported parameters.
    public let supportedParameters: [Parameter]
    
    /// Default parameters.
    public let defaultParameters: DefaultParameters?

    enum CodingKeys: String, CodingKey {
        case id
        case canonicalSlug = "canonical_slug"
        case huggingFaceId = "hugging_face_id"
        case name
        case created
        case description
        case pricing
        case contextLength = "context_length"
        case architecture
        case topProvider = "top_provider"
        case perRequestLimits = "per_request_limits"
        case supportedParameters = "supported_parameters"
        case defaultParameters = "default_parameters"
    }
}

/// Represents pricing information for a model.
public struct PublicPricing: Codable, Sendable {
    /// Price per prompt token.
    public let prompt: String
    
    /// Price per completion token.
    public let completion: String
    
    /// Price per request (if applicable).
    public let request: String?
    
    /// Price per image (if applicable).
    public let image: String?
    
    /// Price per image token (if applicable).
    public let imageToken: String?
    
    /// Price per image output (if applicable).
    public let imageOutput: String?
    
    /// Price per audio (if applicable).
    public let audio: String?
    
    /// Price for input audio cache (if applicable).
    public let inputAudioCache: String?
    
    /// Price for web search (if applicable).
    public let webSearch: String?
    
    /// Price for internal reasoning (if applicable).
    public let internalReasoning: String?
    
    /// Price for input cache read (if applicable).
    public let inputCacheRead: String?
    
    /// Price for input cache write (if applicable).
    public let inputCacheWrite: String?
    
    /// Discount percentage (if applicable).
    public let discount: Double?

    enum CodingKeys: String, CodingKey {
        case prompt
        case completion
        case request
        case image
        case imageToken = "image_token"
        case imageOutput = "image_output"
        case audio
        case inputAudioCache = "input_audio_cache"
        case webSearch = "web_search"
        case internalReasoning = "internal_reasoning"
        case inputCacheRead = "input_cache_read"
        case inputCacheWrite = "input_cache_write"
        case discount
    }
}

/// Represents a model group/category.
public enum ModelGroup: String, Codable, Sendable {
    case router = "Router"
    case media = "Media"
    case other = "Other"
    case gpt = "GPT"
    case claude = "Claude"
    case gemini = "Gemini"
    case grok = "Grok"
    case cohere = "Cohere"
    case nova = "Nova"
    case qwen = "Qwen"
    case yi = "Yi"
    case deepSeek = "DeepSeek"
    case mistral = "Mistral"
    case llama2 = "Llama2"
    case llama3 = "Llama3"
    case llama4 = "Llama4"
    case paLM = "PaLM"
    case rwkv = "RWKV"
    case qwen3 = "Qwen3"
}

/// Represents the instruction type for a model architecture.
public enum ModelArchitectureInstructType: String, Codable, Sendable {
    case none
    case airoboros
    case alpaca
    case alpacaModif = "alpaca-modif"
    case chatml
    case claude
    case codeLlama = "code-llama"
    case gemma
    case llama2
    case llama3
    case mistral
    case nemotron
    case neural
    case openchat
    case phi3
    case rwkv
    case vicuna
    case zephyr
    case deepseekR1 = "deepseek-r1"
    case deepseekV31 = "deepseek-v3.1"
    case qwq
    case qwen3
}

/// Represents input modality types.
public enum InputModality: String, Codable, Sendable {
    case text
    case image
    case file
    case audio
    case video
}

/// Represents output modality types.
public enum OutputModality: String, Codable, Sendable {
    case text
    case image
    case embeddings
}

/// Represents model architecture information.
public struct ModelArchitecture: Codable, Sendable {
    /// Tokenizer group.
    public let tokenizer: ModelGroup?
    
    /// Instruction type.
    public let instructType: ModelArchitectureInstructType?
    
    /// Modality string.
    public let modality: String?
    
    /// Supported input modalities.
    public let inputModalities: [InputModality]
    
    /// Supported output modalities.
    public let outputModalities: [OutputModality]

    enum CodingKeys: String, CodingKey {
        case tokenizer
        case instructType = "instruct_type"
        case modality
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
    }
}

/// Represents top provider information.
public struct TopProviderInfo: Codable, Sendable {
    /// Maximum context length.
    public let contextLength: Double?
    
    /// Maximum completion tokens.
    public let maxCompletionTokens: Double?
    
    /// Whether the provider is moderated.
    public let isModerated: Bool

    enum CodingKeys: String, CodingKey {
        case contextLength = "context_length"
        case maxCompletionTokens = "max_completion_tokens"
        case isModerated = "is_moderated"
    }
}

/// Represents per-request limits.
public struct PerRequestLimits: Codable, Sendable {
    /// Maximum prompt tokens.
    public let promptTokens: Double
    
    /// Maximum completion tokens.
    public let completionTokens: Double

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
    }
}

/// Represents a supported parameter.
public enum Parameter: String, Codable, Sendable {
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case minP = "min_p"
    case topA = "top_a"
    case frequencyPenalty = "frequency_penalty"
    case presencePenalty = "presence_penalty"
    case repetitionPenalty = "repetition_penalty"
    case maxTokens = "max_tokens"
    case logitBias = "logit_bias"
    case logprobs
    case topLogprobs = "top_logprobs"
    case seed
    case responseFormat = "response_format"
    case structuredOutputs = "structured_outputs"
    case stop
    case tools
    case toolChoice = "tool_choice"
    case parallelToolCalls = "parallel_tool_calls"
    case includeReasoning = "include_reasoning"
    case reasoning
    case reasoningEffort = "reasoning_effort"
    case webSearchOptions = "web_search_options"
    case verbosity
}

/// Represents default parameters for a model.
public struct DefaultParameters: Codable, Sendable {
    /// Default temperature.
    public let temperature: Double?
    
    /// Default top-p value.
    public let topP: Double?
    
    /// Default frequency penalty.
    public let frequencyPenalty: Double?

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
    }
}
