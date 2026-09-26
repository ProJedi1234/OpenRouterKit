//
//  ChatResponseProviderTests.swift
//  OpenRouterKit
//
//  Tests for decoding the upstream provider on chat responses
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Chat Response Provider Decoding Tests")
struct ChatResponseProviderTests {

    @Test("Decodes top-level provider")
    func decodesProvider() throws {
        let jsonString = """
        {
          "id": "gen-provider123",
          "provider": "Groq",
          "model": "openai/gpt-oss-120b",
          "object": "chat.completion",
          "created": 1758900000,
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "Hello!"
              },
              "finish_reason": "stop"
            }
          ]
        }
        """

        let jsonData = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponse.self, from: jsonData)

        #expect(response.provider == "Groq")
        #expect(response.model == "openai/gpt-oss-120b")
    }

    @Test("Decodes response without provider")
    func decodesWithoutProvider() throws {
        let jsonString = """
        {
          "id": "gen-provider456",
          "model": "test-model",
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "No provider here."
              },
              "finish_reason": "stop"
            }
          ]
        }
        """

        let jsonData = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponse.self, from: jsonData)

        #expect(response.provider == nil)
    }
}

@Suite("Chat Response Provider Integration Tests",
       .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false))
struct ChatResponseProviderIntegrationTests {
    let client: OpenRouterClient

    init() throws {
        let apiKey = try #require(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"])

        #if canImport(FoundationNetworking)
        let session = URLSession(configuration: .default)
        #else
        let session = URLSession.shared
        #endif

        client = OpenRouterClient(
            apiKey: apiKey,
            siteURL: "https://github.com",
            siteName: "Swift OpenRouterKit Tests",
            session: session
        )
    }

    @Test("Non-streaming chat completion reports the upstream provider")
    func chatCompletionIncludesProvider() async throws {
        let request = OpenRouterRequest(
            messages: [Message(role: .user, content: .string("Reply with one word: ok"))],
            model: "google/gemini-3-flash-preview",
            maxTokens: 5
        )

        let response = try await client.chat.send(request: request)
        let provider = try #require(response.provider, "OpenRouter should return the serving provider")

        #expect(!provider.isEmpty)
        print("Served by provider: \(provider)")
    }
}
