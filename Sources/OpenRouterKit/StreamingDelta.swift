//
//  StreamingDelta.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//


import Foundation

public struct StreamingDelta: Codable {
    public struct Choice: Codable {
        public struct Delta: Codable {
            public var role: String?
            public var content: String?
        }
        public var delta: Delta
        public var index: Int
        public var finish_reason: String?
        public var logprobs: String?  // Can also be null, so use String?
    }
    
    public var id: String
    public var provider: String?
    public var model: String?
    public var object: String?
    public var created: Int?
    public var choices: [Choice]
    public var usage: Usage?
    
    public struct Usage: Codable {
        public var prompt_tokens: Int
        public var completion_tokens: Int
        public var total_tokens: Int
    }
}
