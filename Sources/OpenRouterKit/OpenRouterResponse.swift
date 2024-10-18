//
//  OpenRouterResponse.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//


import Foundation

public struct OpenRouterResponse: Codable, Sendable {
    public struct Choice: Codable, Sendable {
        public struct Message: Codable, Sendable {
            public var role: String
            public var content: String
        }
        public var message: Message
        public var finish_reason: String?
    }
    
    public var id: String
    public var choices: [Choice]
    public var model: String
    public var usage: Usage?
    
    public struct Usage: Codable, Sendable {
        public var prompt_tokens: Int
        public var completion_tokens: Int
        public var total_tokens: Int
    }
}
