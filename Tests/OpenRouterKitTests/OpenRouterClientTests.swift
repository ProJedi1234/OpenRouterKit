//
//  OpenRouterClientTests.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//


import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Client Testing",
       .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false))
struct OpenRouterClientTests {
    let client: OpenRouterClient

    init() throws {
        let apiKey = try #require(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"])

        #if canImport(FoundationNetworking)
        let session = URLSession(configuration: .default)
        #else
        let session = URLSession.shared
        #endif

        client = OpenRouterClient(apiKey: apiKey, siteURL: "https://github.com", siteName: "Swift OpenRouterKit Tests", session: session)
    }
    
    @Test func testChatRequest() async throws {
        let messages: [Message] = [
            .init(role: .user, content: .string("Tell me a joke"))
        ]
        
        let request = OpenRouterRequest(messages: messages, model: "mistralai/mistral-7b-instruct:free")
        let response = try await client.chat.send(request: request)

        let choice = try #require(response.choices.first, "Response should contain at least one choice")
        #expect(choice.message.content?.isEmpty == false, "Response should contain a message")
    }

    @Test func testListModels() async throws {
        let response = try await client.models.list(category: nil, supportedParameters: nil, useRSS: nil, useRSSChatLinks: nil)

        let firstModel = try #require(response.data.first, "Models list should not be empty")
        #expect(!firstModel.id.isEmpty, "Model id should not be empty")
        #expect(!firstModel.name.isEmpty, "Model name should not be empty")
    }

    @Test func testListModelsForUser() async throws {
        let response = try await client.models.listForUser()

        let firstModel = try #require(response.data.first, "User models list should not be empty")
        #expect(!firstModel.id.isEmpty, "Model id should not be empty")
        #expect(!firstModel.name.isEmpty, "Model name should not be empty")
    }
    
    #if canImport(Darwin)
    @available(iOS 15.0, macOS 12.0, *)
    @Test func testStreamChatRequest() async throws {
        let messages = [Message(role: .user, content: .string("Write me a long paragraph about cats"))]
        
        var streamedResponse = ""
        var lastChunkTime = Date()
        var timesBetweenChunks: [TimeInterval] = []
        
        let request = OpenRouterRequest(messages: messages, model: "mistralai/mistral-7b-instruct:free", stream: true)
        let stream = client.chat.stream(request: request)
        
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
        #expect(averageTimeBetweenChunks > 0.001, "Average time between chunks should be greater than 0.001 seconds")
        
        print("Average time between chunks: \(averageTimeBetweenChunks) seconds")
        print("Number of chunks received: \(timesBetweenChunks.count + 1)")
        print("Final response length: \(streamedResponse.count) characters")
    }
    #endif
}
