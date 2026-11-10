//
//  NIOClientTests.swift
//  OpenRouterKit
//
//  Integration tests for the NIO-backed OpenRouterClient.
//  These tests verify that the AsyncHTTPClient transport works correctly
//  for both standard and streaming requests on all platforms.
//

import Testing
import Foundation
import OpenRouterKitNIO

/// Mirrors `integrationTestModel` in OpenRouterKitTests; test targets cannot share a helper file.
private let integrationTestModel = "z-ai/glm-5.3-flash"

@Suite("NIO Client",
       .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false))
struct NIOClientTests {
    let client: OpenRouterClient

    init() throws {
        let apiKey = try #require(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"])
        client = OpenRouterClient.nio(
            apiKey: apiKey,
            siteURL: "https://github.com",
            siteName: "Swift OpenRouterKit NIO Tests"
        )
    }

    @Test func testNIOChatRequest() async throws {
        let messages: [Message] = [
            .init(role: .user, content: .string("Tell me a joke"))
        ]

        let request = ChatRequest(messages: messages, model: integrationTestModel)
        let response = try await client.chat.send(request: request)

        let choice = try #require(response.choices.first, "Response should contain at least one choice")
        #expect(choice.message.content?.isEmpty == false, "Response should contain a message")
    }

    @Test func testNIOStreamChatRequest() async throws {
        let messages = [Message(role: .user, content: .string("Write me a short paragraph about cats"))]

        var streamedResponse = ""
        var chunkCount = 0

        let request = ChatRequest(messages: messages, model: integrationTestModel, stream: true)
        let stream = try await client.chat.stream(request: request)

        for try await text in stream {
            streamedResponse += text
            chunkCount += 1
        }

        #expect(!streamedResponse.isEmpty, "Streamed response should not be empty")
        #expect(chunkCount > 3, "Should receive multiple chunks of data")

        print("NIO stream: \(chunkCount) chunks, \(streamedResponse.count) chars")
    }

    @Test func testNIOStreamEvents() async throws {
        let messages = [Message(role: .user, content: .string("Say hello"))]

        var textContent = ""
        var gotFinished = false

        let request = ChatRequest(messages: messages, model: integrationTestModel, stream: true)
        let stream = try await client.chat.streamEvents(request: request)

        for try await event in stream {
            switch event {
            case .text(let text):
                textContent += text
            case .finished(let reason, _):
                gotFinished = true
                #expect(reason == "stop", "Finish reason should be 'stop'")
            case .audio, .annotations:
                break
            case .toolCallDelta:
                break
            }
        }

        #expect(!textContent.isEmpty, "Should receive text content")
        #expect(gotFinished, "Should receive a finished event")

        print("NIO streamEvents: \(textContent.count) chars, finished: \(gotFinished)")
    }

    @Test func testNIOListModels() async throws {
        let response = try await client.models.list(filters: ModelsListFilters())

        let firstModel = try #require(response.data.first, "Models list should not be empty")
        #expect(!firstModel.id.isEmpty, "Model id should not be empty")
    }
}

extension NIOClientTests {
    @Test func testNIOStreamServerToolWithFunctionTool() async throws {
        let weatherTool = Tool(function: FunctionDescription(
            name: "get_weather",
            description: "Get the current weather for a city.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object(["location": .object(["type": .string("string")])]),
                "required": .array([.string("location")])
            ])
        ))
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string(
                "First search the web for which city hosted the 2024 Summer Olympics, then call get_weather for that city."
            ))],
            model: "openai/gpt-5-mini",
            tools: [.webSearch(WebSearchParameters(engine: .exa, maxResults: 1)), weatherTool]
        )

        var accumulator = ToolCallAccumulator()
        var citations: [Annotation] = []
        var webSearchRequests = 0
        var finishReason: String?

        for try await event in try await client.chat.streamEvents(request: request) {
            switch event {
            case .annotations(let annotations):
                citations += annotations
            case .toolCallDelta(let delta):
                accumulator.accumulate(delta)
            case .finished(let reason, let usage):
                finishReason = reason ?? finishReason
                webSearchRequests = max(webSearchRequests, usage?.server_tool_use_details?.web_search_requests ?? 0)
            case .text, .audio:
                break
            }
        }

        #expect(citations.contains { $0.urlCitation?.url?.isEmpty == false }, "Should stream url_citation annotations")
        #expect(webSearchRequests >= 1, "Usage should count the web search")
        #expect(accumulator.toolCalls.allSatisfy { $0.function.name == "get_weather" },
                "Server tool calls should never surface as function tool calls")
        if finishReason == "tool_calls" {
            #expect(accumulator.toolCalls.count >= 1)
        }
    }
}
