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
        public var finish_reason: String?
        
        /// Represents a message in the response.
        public struct Message: Codable, Sendable {
            /// Role of the message sender.
            public var role: String
            
            /// Content of the message.
            public var content: String
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
        
        /// Detailed breakdown of output tokens.
        public var output_tokens_details: OutputTokensDetails?
        
        /// Detailed breakdown of output tokens.
        public struct OutputTokensDetails: Codable, Sendable {
            /// Number of tokens used for reasoning (if applicable).
            public var reasoning_tokens: Int?
        }
    }
}
