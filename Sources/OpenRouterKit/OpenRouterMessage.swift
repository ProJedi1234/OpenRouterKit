//
//  OpenRouterMessage.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//


import Foundation

public struct OpenRouterMessage: Codable, Sendable {
    public var role: String // "user", "assistant", or "system"
    public var content: String
    public var name: String?
    
    public init(role: String, content: String, name: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "role": role,
            "content": content
        ]
        if let name = name {
            dict["name"] = name
        }
        return dict
    }
}
