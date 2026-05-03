//
//  EmbeddingTypes.swift
//  OpenRouterKit
//
//  Request and response types for the OpenRouter embeddings API.
//

import Foundation

// MARK: - Request

/// Output format for embedding vectors.
public enum EmbeddingEncodingFormat: String, Codable, Sendable {
    case float
    case base64
}

/// A single multimodal input block for embeddings (`{ "content": [...] }`).
public struct EmbeddingMultimodalBlock: Codable, Sendable {
    /// Content parts (text and/or image URL), same shape as chat multimodal messages.
    public var content: [ContentPart]

    public init(content: [ContentPart]) {
        self.content = content
    }
}

/// Input payload for an embeddings request.
///
/// Supports a plain string, a batch of strings, token id sequences, and multimodal
/// blocks per OpenRouter’s embeddings schema.
public enum EmbeddingInput: Sendable {
    case string(String)
    case strings([String])
    case tokenIds([Double])
    case tokenBatches([[Double]])
    case multimodalBlocks([EmbeddingMultimodalBlock])
}

extension EmbeddingInput: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .string(text)
            return
        }
        if let strs = try? container.decode([String].self) {
            self = .strings(strs)
            return
        }
        if let blocks = try? container.decode([EmbeddingMultimodalBlock].self) {
            self = .multimodalBlocks(blocks)
            return
        }
        if let batches = try? container.decode([[Double]].self) {
            self = .tokenBatches(batches)
            return
        }
        if let ids = try? container.decode([Double].self) {
            self = .tokenIds(ids)
            return
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "EmbeddingInput: unsupported JSON shape"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let text):
            try container.encode(text)
        case .strings(let arr):
            try container.encode(arr)
        case .tokenIds(let ids):
            try container.encode(ids)
        case .tokenBatches(let batches):
            try container.encode(batches)
        case .multimodalBlocks(let blocks):
            try container.encode(blocks)
        }
    }
}

/// Request body for `POST /embeddings`.
public struct EmbeddingRequest: Codable, Sendable {
    /// Model id (e.g. `openai/text-embedding-3-small`).
    public var model: String
    /// Input text, tokens, or multimodal blocks.
    public var input: EmbeddingInput
    /// Optional number of dimensions for the output embedding.
    public var dimensions: Int?
    /// Encoding format for vectors (`float` or `base64`).
    public var encodingFormat: EmbeddingEncodingFormat?
    /// Optional input type hint (e.g. search query vs document), provider-specific.
    public var inputType: String?
    /// Provider routing preferences.
    public var provider: ProviderPreferences?
    /// Optional end-user identifier.
    public var user: String?

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case dimensions
        case encodingFormat = "encoding_format"
        case inputType = "input_type"
        case provider
        case user
    }

    public init(
        model: String,
        input: EmbeddingInput,
        dimensions: Int? = nil,
        encodingFormat: EmbeddingEncodingFormat? = nil,
        inputType: String? = nil,
        provider: ProviderPreferences? = nil,
        user: String? = nil
    ) {
        self.model = model
        self.input = input
        self.dimensions = dimensions
        self.encodingFormat = encodingFormat
        self.inputType = inputType
        self.provider = provider
        self.user = user
    }
}

// MARK: - Response

/// One embedding vector: floats or a base64 string.
public enum EmbeddingVector: Sendable {
    case floats([Double])
    case base64(String)
}

extension EmbeddingVector: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([Double].self) {
            self = .floats(arr)
            return
        }
        if let encoded = try? container.decode(String.self) {
            self = .base64(encoded)
            return
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "EmbeddingVector: expected [Double] or String"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .floats(let arr):
            try container.encode(arr)
        case .base64(let encoded):
            try container.encode(encoded)
        }
    }
}

/// Per-modality token counts in embedding usage (when present).
public struct EmbeddingUsagePromptTokensDetails: Codable, Sendable {
    public var audioTokens: Int?
    public var imageTokens: Int?
    public var textTokens: Int?
    public var videoTokens: Int?

    enum CodingKeys: String, CodingKey {
        case audioTokens = "audio_tokens"
        case imageTokens = "image_tokens"
        case textTokens = "text_tokens"
        case videoTokens = "video_tokens"
    }
}

/// Token usage for an embeddings response.
public struct EmbeddingUsage: Codable, Sendable {
    public var cost: Double?
    public var promptTokens: Int
    public var promptTokensDetails: EmbeddingUsagePromptTokensDetails?
    public var totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case cost
        case promptTokens = "prompt_tokens"
        case promptTokensDetails = "prompt_tokens_details"
        case totalTokens = "total_tokens"
    }
}

/// One row in the `data` array of an embeddings response.
public struct EmbeddingData: Codable, Sendable {
    public var embedding: EmbeddingVector
    public var index: Int?
    public var object: String?
}

/// Top-level response from `POST /embeddings`.
public struct EmbeddingResponse: Codable, Sendable {
    public var data: [EmbeddingData]
    public var id: String?
    public var model: String
    public var object: String
    public var usage: EmbeddingUsage?
}
