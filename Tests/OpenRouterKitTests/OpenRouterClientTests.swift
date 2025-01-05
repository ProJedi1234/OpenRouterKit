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
        let messages = [Message(role: .user, content: .string("Write me a long paragraph about cats"))]
        
        var streamedResponse = ""
        var lastChunkTime = Date()
        var timesBetweenChunks: [TimeInterval] = []
        
        let request = OpenRouterRequest(messages: messages, model: "meta-llama/llama-3.2-1b-instruct:free", stream: true)
        let stream = client.streamChatRequest(request: request)
        
        for await text in stream {
            let now = Date()
            let timeSinceLastChunk = now.timeIntervalSince(lastChunkTime)
            timesBetweenChunks.append(timeSinceLastChunk)
            lastChunkTime = now
            
            streamedResponse += text
        }
        
        // Remove the first timing since it includes request setup
        if !timesBetweenChunks.isEmpty {
            timesBetweenChunks.removeFirst()
        }
        
        // Verify we got a response
        #expect(!streamedResponse.isEmpty, "Streamed response should not be empty")
        
        // Verify we got multiple chunks
        #expect(timesBetweenChunks.count > 3, "Should receive at least 4 chunks of data")
        
        // Verify chunks didn't all arrive simultaneously
        let averageTimeBetweenChunks = timesBetweenChunks.reduce(0, +) / Double(timesBetweenChunks.count)
        #expect(averageTimeBetweenChunks > 0.001, "Average time between chunks should be greater than 0.01 seconds")
        
        print("Average time between chunks: \(averageTimeBetweenChunks) seconds")
        print("Number of chunks received: \(timesBetweenChunks.count + 1)")
        print("Final response length: \(streamedResponse.count) characters")
    }
}
