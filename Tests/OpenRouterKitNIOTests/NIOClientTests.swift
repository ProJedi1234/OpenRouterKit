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

        let request = ChatRequest(messages: messages, model: "google/gemini-3-flash-preview")
        let response = try await client.chat.send(request: request)

        let choice = try #require(response.choices.first, "Response should contain at least one choice")
        #expect(choice.message.content?.isEmpty == false, "Response should contain a message")
    }

    @Test func testNIOStreamChatRequest() async throws {
        let messages = [Message(role: .user, content: .string("Write me a short paragraph about cats"))]

        var streamedResponse = ""
        var chunkCount = 0

        let request = ChatRequest(messages: messages, model: "google/gemini-3-flash-preview", stream: true)
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

        let request = ChatRequest(messages: messages, model: "google/gemini-3-flash-preview", stream: true)
        let stream = try await client.chat.streamEvents(request: request)

        for try await event in stream {
            switch event {
            case .text(let text):
                textContent += text
            case .finished(let reason, _):
                gotFinished = true
                #expect(reason == "stop", "Finish reason should be 'stop'")
            case .toolCallDelta:
                break
            }
        }

        #expect(!textContent.isEmpty, "Should receive text content")
        #expect(gotFinished, "Should receive a finished event")

        print("NIO streamEvents: \(textContent.count) chars, finished: \(gotFinished)")
    }

    @Test func testNIOListModels() async throws {
        let response = try await client.models.list(
            category: nil,
            supportedParameters: nil,
            useRSS: nil,
            useRSSChatLinks: nil
        )

        let firstModel = try #require(response.data.first, "Models list should not be empty")
        #expect(!firstModel.id.isEmpty, "Model id should not be empty")
    }
}
