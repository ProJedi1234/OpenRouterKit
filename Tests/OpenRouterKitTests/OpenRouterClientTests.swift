//
//  OpenRouterClientTests.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//


import Testing
import Foundation
@testable import OpenRouterKit

@Suite("Client Testing")
struct OpenRouterClientTests {
    var client: OpenRouterClient!
    
    init() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] else {
            fatalError("API key not found in environment variables")
        }
        
        client = OpenRouterClient(apiKey: apiKey, siteURL: "www.github.com", siteName: "Swift OpenRouterKit Tests", session: URLSession.shared)
    }
    
    @Test func testChatRequest() async throws {
        let messages: [Message] = [
            .init(role: .user, content: .string("Tell me a joke"))
        ]
        
        let request = OpenRouterRequest(messages: messages, model: "meta-llama/llama-3.2-1b-instruct:free")
        let response = try await client.sendChatRequest(request: request)
        
        #expect(response.choices.count == 1, "Response should contain one choice")
        #expect(!response.choices[0].message.content.isEmpty, "Response should contain a message")
    }
    
    @Test func testStreamChatRequest() async throws {
        let messages = [Message(role: .user, content: .string("Tell me a joke"))]
        
        var streamedResponse: String = ""
        
        // Collect the streamed response
        let request = OpenRouterRequest(messages: messages, model: "meta-llama/llama-3.2-1b-instruct:free", stream: true)
        let stream = client.streamChatRequest(request: request)
        for await text in stream {
            streamedResponse += text
        }
        
        // Check if we got a non-empty streamed response
        #expect(!streamedResponse.isEmpty, "Streamed response should not be empty.")
        print("Streamed Response: \(streamedResponse)")
    }
}
