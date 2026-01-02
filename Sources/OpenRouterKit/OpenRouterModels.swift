//
//  OpenRouterModels.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/22/24.
//

import Foundation

public struct ModelsListResponse: Codable, Sendable {
    public let data: [Model]
}

public struct Model: Codable, Sendable {
    public let id: String
    public let canonicalSlug: String
    public let huggingFaceId: String?
    public let name: String
    public let created: Double
    public let description: String?
    public let pricing: PublicPricing
    public let contextLength: Double?
    public let architecture: ModelArchitecture
    public let topProvider: TopProviderInfo
    public let perRequestLimits: PerRequestLimits?
    public let supportedParameters: [Parameter]
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

public struct PublicPricing: Codable, Sendable {
    public let prompt: String
    public let completion: String
    public let request: String?
    public let image: String?
    public let imageToken: String?
    public let imageOutput: String?
    public let audio: String?
    public let inputAudioCache: String?
    public let webSearch: String?
    public let internalReasoning: String?
    public let inputCacheRead: String?
    public let inputCacheWrite: String?
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

public enum InputModality: String, Codable, Sendable {
    case text
    case image
    case file
    case audio
    case video
}

public enum OutputModality: String, Codable, Sendable {
    case text
    case image
    case embeddings
}

public struct ModelArchitecture: Codable, Sendable {
    public let tokenizer: ModelGroup?
    public let instructType: ModelArchitectureInstructType?
    public let modality: String?
    public let inputModalities: [InputModality]
    public let outputModalities: [OutputModality]

    enum CodingKeys: String, CodingKey {
        case tokenizer
        case instructType = "instruct_type"
        case modality
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
    }
}

public struct TopProviderInfo: Codable, Sendable {
    public let contextLength: Double?
    public let maxCompletionTokens: Double?
    public let isModerated: Bool

    enum CodingKeys: String, CodingKey {
        case contextLength = "context_length"
        case maxCompletionTokens = "max_completion_tokens"
        case isModerated = "is_moderated"
    }
}

public struct PerRequestLimits: Codable, Sendable {
    public let promptTokens: Double
    public let completionTokens: Double

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
    }
}

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

public struct DefaultParameters: Codable, Sendable {
    public let temperature: Double?
    public let topP: Double?
    public let frequencyPenalty: Double?

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
    }
}
