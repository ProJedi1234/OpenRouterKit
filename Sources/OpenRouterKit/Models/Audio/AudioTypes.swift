//
//  AudioTypes.swift
//  OpenRouterKit
//
//  Request and response types for OpenRouter audio APIs.
//

import Foundation

/// Audio file format identifier.
///
/// OpenRouter providers support different format sets, so this type accepts
/// custom raw values in addition to the common formats documented by OpenRouter.
public struct AudioFormat: RawRepresentable, Codable, Sendable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let wav = Self(rawValue: "wav")
    public static let mp3 = Self(rawValue: "mp3")
    public static let aiff = Self(rawValue: "aiff")
    public static let aac = Self(rawValue: "aac")
    public static let ogg = Self(rawValue: "ogg")
    public static let flac = Self(rawValue: "flac")
    public static let m4a = Self(rawValue: "m4a")
    public static let webm = Self(rawValue: "webm")
    public static let pcm16 = Self(rawValue: "pcm16")
    public static let pcm24 = Self(rawValue: "pcm24")
    public static let opus = Self(rawValue: "opus")
}

/// Base64-encoded audio payload.
public struct InputAudio: Codable, Sendable, Equatable {
    /// Base64-encoded raw audio bytes. Data URIs are not supported by OpenRouter.
    public var data: String

    /// Format of the encoded audio data.
    public var format: AudioFormat

    public init(data: String, format: AudioFormat) {
        self.data = data
        self.format = format
    }
}

/// A chat content part that sends base64-encoded audio to a multimodal model.
public struct InputAudioContentPart: Codable, Sendable, Equatable {
    /// The type of content, always `input_audio`.
    public var type: String

    /// The base64-encoded audio payload.
    public var inputAudio: InputAudio

    enum CodingKeys: String, CodingKey {
        case type
        case inputAudio = "input_audio"
    }

    public init(type: String = "input_audio", inputAudio: InputAudio) {
        self.type = type
        self.inputAudio = inputAudio
    }
}

/// Chat response modality requested from an audio-capable model.
public struct ChatResponseModality: RawRepresentable, Codable, Sendable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let text = Self(rawValue: "text")
    public static let audio = Self(rawValue: "audio")
}

/// Audio generation options for chat completions.
public struct ChatAudioConfiguration: Codable, Sendable, Equatable {
    /// Voice to use for generated audio, such as `alloy`, `echo`, or `nova`.
    public var voice: String

    /// Format for generated audio.
    public var format: AudioFormat

    public init(voice: String, format: AudioFormat) {
        self.voice = voice
        self.format = format
    }
}

/// Audio data emitted by a streaming chat completion delta.
public struct AudioDelta: Codable, Sendable, Equatable {
    /// Base64-encoded audio chunk.
    public var data: String?

    /// Transcript text for this audio chunk.
    public var transcript: String?

    public init(data: String? = nil, transcript: String? = nil) {
        self.data = data
        self.transcript = transcript
    }
}

/// Audio payload returned on a chat completion message when a provider includes non-streaming audio metadata.
public struct ChatCompletionAudio: Codable, Sendable, Equatable {
    /// Provider audio identifier.
    public var id: String?

    /// Base64-encoded generated audio.
    public var data: String?

    /// Transcript of the generated audio.
    public var transcript: String?

    /// Unix timestamp for when the audio reference expires, when provided.
    public var expiresAt: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case data
        case transcript
        case expiresAt = "expires_at"
    }

    public init(id: String? = nil, data: String? = nil, transcript: String? = nil, expiresAt: Int? = nil) {
        self.id = id
        self.data = data
        self.transcript = transcript
        self.expiresAt = expiresAt
    }
}

/// Provider-specific passthrough options for audio transcription.
public struct AudioProviderOptions: Codable, Sendable, Equatable {
    /// Provider options keyed by provider slug, for example `groq`.
    public var options: [String: [String: JSONValue]]?

    public init(options: [String: [String: JSONValue]]? = nil) {
        self.options = options
    }
}

/// Request body for `POST /audio/transcriptions`.
public struct AudioTranscriptionRequest: Codable, Sendable, Equatable {
    /// STT model id, for example `openai/whisper-1`.
    public var model: String

    /// Base64-encoded audio to transcribe.
    public var inputAudio: InputAudio

    /// Optional ISO-639-1 language code. Omit to auto-detect.
    public var language: String?

    /// Sampling temperature between 0 and 1.
    public var temperature: Double?

    /// Provider-specific passthrough configuration.
    public var provider: AudioProviderOptions?

    enum CodingKeys: String, CodingKey {
        case model
        case inputAudio = "input_audio"
        case language
        case temperature
        case provider
    }

    public init(
        model: String,
        inputAudio: InputAudio,
        language: String? = nil,
        temperature: Double? = nil,
        provider: AudioProviderOptions? = nil
    ) {
        self.model = model
        self.inputAudio = inputAudio
        self.language = language
        self.temperature = temperature
        self.provider = provider
    }
}

/// Usage statistics returned by the audio transcription endpoint.
public struct AudioTranscriptionUsage: Codable, Sendable, Equatable {
    /// Duration of the input audio in seconds.
    public var seconds: Double?

    /// Total number of tokens used.
    public var totalTokens: Int?

    /// Number of input tokens billed.
    public var inputTokens: Int?

    /// Number of output tokens generated.
    public var outputTokens: Int?

    /// Total request cost in USD.
    public var cost: Double?

    enum CodingKeys: String, CodingKey {
        case seconds
        case totalTokens = "total_tokens"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cost
    }
}

/// Response from `POST /audio/transcriptions`.
public struct AudioTranscriptionResponse: Codable, Sendable, Equatable {
    /// Transcribed text.
    public var text: String

    /// Optional usage statistics.
    public var usage: AudioTranscriptionUsage?

    public init(text: String, usage: AudioTranscriptionUsage? = nil) {
        self.text = text
        self.usage = usage
    }
}
