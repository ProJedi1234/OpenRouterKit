//
//  StreamingDelta.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Represents a delta update in a streaming chat completion response.
///
/// Used internally for parsing streaming responses from the OpenRouter API.
public struct StreamingDelta: Codable {
    /// Unique identifier for the completion.
    public var id: String
    
    /// Provider identifier.
    public var provider: String?
    
    /// Model identifier.
    public var model: String?
    
    /// Object type.
    public var object: String?
    
    /// Creation timestamp.
    public var created: Int?
    
    /// Array of completion choices.
    public var choices: [Choice]
    
    /// Token usage statistics.
    public var usage: Usage?
    
    /// Represents a single choice in a streaming delta.
    public struct Choice: Codable {
        /// The delta update for this choice.
        public var delta: Delta
        
        /// Index of this choice.
        public var index: Int
        
        /// Reason why the completion finished (if finished).
        public var finish_reason: String?
        
        /// Log probabilities (if requested).
        public var logprobs: String?
        
        /// Represents a delta update for a choice.
        public struct Delta: Codable {
            /// Role of the message (if present).
            public var role: String?
            
            /// Content delta (new text chunk).
            public var content: String?
        }
    }
    
    /// Represents token usage statistics.
    public struct Usage: Codable {
        /// Number of tokens in the prompt.
        public var prompt_tokens: Int
        
        /// Number of tokens in the completion.
        public var completion_tokens: Int
        
        /// Total number of tokens used.
        public var total_tokens: Int
        
        /// Detailed breakdown of output tokens.
        public var output_tokens_details: OutputTokensDetails?
        
        /// Detailed breakdown of output tokens.
        public struct OutputTokensDetails: Codable {
            /// Number of tokens used for reasoning (if applicable).
            public var reasoning_tokens: Int?
        }
    }
}
