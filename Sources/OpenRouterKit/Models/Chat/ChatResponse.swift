//
//  ChatResponse.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Represents a response from the OpenRouter chat completions API.
///
/// Contains the generated completion, model information, and usage statistics.
public struct ChatResponse: Codable, Sendable {
    /// Unique identifier for the completion.
    public var id: String

    /// Array of completion choices.
    public var choices: [Choice]

    /// Model identifier used for the completion.
    public var model: String

    /// Token usage statistics.
    public var usage: Usage?

    /// Represents a single completion choice.
    public struct Choice: Codable, Sendable {
        /// The generated message.
        public var message: Message

        /// Reason why the completion finished.
        /// Will be "tool_calls" when the model wants to call tools.
        public var finish_reason: String?

        /// Represents a message in the response.
        public struct Message: Codable, Sendable {
            /// Role of the message sender.
            public var role: String

            /// Content of the message. May be null when the model makes tool calls.
            public var content: String?

            /// Tool calls requested by the model.
            /// Present when the model decides to call one or more tools.
            public var toolCalls: [ToolCall]?

            /// Generated audio payload, when returned by audio-capable models.
            public var audio: ChatCompletionAudio?

            enum CodingKeys: String, CodingKey {
                case role
                case content
                case toolCalls = "tool_calls"
                case audio
            }
        }
    }

    /// Represents token usage statistics.
    public struct Usage: Codable, Sendable {
        /// Number of tokens in the prompt.
        public var prompt_tokens: Int

        /// Number of tokens in the completion.
        public var completion_tokens: Int

        /// Total number of tokens used.
        public var total_tokens: Int

        /// Cost in credits charged for the request.
        public var cost: Double?

        /// Detailed breakdown of completion tokens.
        public var completion_tokens_details: OutputTokensDetails?

        /// Detailed breakdown of request cost.
        public var cost_details: CostDetails?

        /// Detailed breakdown of prompt tokens.
        public var prompt_tokens_details: PromptTokensDetails?

        /// Detailed breakdown of output tokens.
        public struct OutputTokensDetails: Codable, Sendable {
            /// Number of tokens used for reasoning (if applicable).
            public var reasoning_tokens: Int?

            /// Number of tokens used for generated audio.
            public var audio_tokens: Int?

            /// Number of tokens used for generated images.
            public var image_tokens: Int?
        }

        /// Detailed breakdown of prompt token usage.
        public struct PromptTokensDetails: Codable, Sendable {
            /// Number of tokens read from the cache.
            public var cached_tokens: Int?

            /// Number of tokens written to the cache.
            public var cache_write_tokens: Int?

            /// Number of tokens used for input audio.
            public var audio_tokens: Int?

            /// Number of tokens used for input video.
            public var video_tokens: Int?
        }

        /// Detailed breakdown of request cost.
        public struct CostDetails: Codable, Sendable {
            /// Cost charged by the upstream AI provider.
            public var upstream_inference_cost: Double?

            /// Upstream cost attributed to the prompt.
            public var upstream_inference_prompt_cost: Double?

            /// Upstream cost attributed to completions.
            public var upstream_inference_completions_cost: Double?
        }
    }
}
