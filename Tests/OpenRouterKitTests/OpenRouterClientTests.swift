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
        
        let request = OpenRouterRequest(messages: messages, model: "google/gemini-3-flash-preview")
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
    
    /// URLSession streaming only works on Darwin. On non-Darwin platforms, use OpenRouterKitNIO instead.
    @Test(.enabled(if: isDarwin))
    func testStreamChatRequest() async throws {
        let messages = [Message(role: .user, content: .string("Write me a long paragraph about cats"))]

        var streamedResponse = ""
        var chunkCount = 0

        let request = OpenRouterRequest(messages: messages, model: "google/gemini-3-flash-preview", stream: true)
        let stream = try await client.chat.stream(request: request)

        for try await text in stream {
            streamedResponse += text
            chunkCount += 1
        }

        #expect(!streamedResponse.isEmpty, "Streamed response should not be empty")
        #expect(chunkCount >= 2, "Should receive multiple chunks of data")

        print("Number of chunks received: \(chunkCount)")
        print("Final response length: \(streamedResponse.count) characters")
    }

    @Test(.enabled(if: isDarwin))
    func testStreamEventsIncludesUsage() async throws {
        let request = OpenRouterRequest(
            messages: [Message(role: .user, content: .string("Say hi"))],
            model: "google/gemini-3-flash-preview",
            stream: true,
            maxTokens: 5
        )

        var finishedUsage: StreamingDelta.Usage?
        let stream = try await client.chat.streamEvents(request: request)
        for try await event in stream {
            if case .finished(_, let usage) = event {
                if usage != nil {
                    finishedUsage = usage
                }
            }
        }

        let usage = try #require(finishedUsage, "Should receive a .finished event with non-nil usage")
        #expect(usage.prompt_tokens > 0, "prompt_tokens should be > 0")
        #expect(usage.completion_tokens > 0, "completion_tokens should be > 0")
        #expect(usage.total_tokens == usage.prompt_tokens + usage.completion_tokens,
                "total_tokens should equal prompt + completion")
        print("Usage: prompt=\(usage.prompt_tokens), completion=\(usage.completion_tokens), total=\(usage.total_tokens)")
    }

    @Test(.enabled(if: isDarwin))
    func testStreamEventsToolCallIncludesUsage() async throws {
        let weatherTool = Tool(function: FunctionDescription(
            name: "get_weather",
            description: "Get the current weather for a given location.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city name")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        ))

        let request = ChatRequest(
            messages: [
                Message(role: .user, content: .string("What is the weather in Tokyo? Use the get_weather tool."))
            ],
            model: "google/gemini-3-flash-preview",
            maxTokens: 500,
            tools: [weatherTool],
            toolChoice: .required
        )

        var finishedUsage: StreamingDelta.Usage?
        let stream = try await client.chat.streamEvents(request: request)
        for try await event in stream {
            if case .finished(_, let usage) = event {
                if usage != nil {
                    finishedUsage = usage
                }
            }
        }

        let usage = try #require(finishedUsage, "Should receive a .finished event with non-nil usage for tool calls")
        #expect(usage.prompt_tokens > 0, "prompt_tokens should be > 0")
        #expect(usage.completion_tokens > 0, "completion_tokens should be > 0")
        print("Tool call usage: prompt=\(usage.prompt_tokens), completion=\(usage.completion_tokens), total=\(usage.total_tokens)")
    }
}
