//
//  ReasoningTests.swift
//  OpenRouterKit
//
//  Tests for reasoning token support
//

import Testing
import Foundation
@testable import OpenRouterKit

@Suite("Reasoning Token Support Tests")
struct ReasoningTests {
    
    // MARK: - Unit Tests (No API Calls)
    
    @Test("Reasoning request encoding")
    func testReasoningRequestEncoding() throws {
        let request = OpenRouterRequest(
            messages: [
                Message(role: .user, content: .string("What is 2+2?"))
            ],
            model: "openai/gpt-oss-20b:free",
            reasoning: ReasoningConfiguration(effort: .high)
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(request)
        
        // Decode as dictionary to verify structure
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        #expect(json != nil, "Should encode to valid JSON")
        #expect(json?["reasoning"] != nil, "Should contain reasoning field")
        
        let reasoning = json?["reasoning"] as? [String: Any]
        #expect(reasoning?["effort"] as? String == "high", "Reasoning effort should be 'high'")
    }
    
    @Test("All reasoning effort levels encoding")
    func testAllReasoningEffortLevels() throws {
        let efforts: [ReasoningEffort] = [.minimal, .low, .medium, .high]
        let expectedStrings = ["minimal", "low", "medium", "high"]
        
        for (effort, expectedString) in zip(efforts, expectedStrings) {
            let request = OpenRouterRequest(
                messages: [Message(role: .user, content: .string("test"))],
                model: "test-model",
                reasoning: ReasoningConfiguration(effort: effort)
            )
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(request)
            let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            let reasoning = json?["reasoning"] as? [String: Any]
            
            #expect(reasoning?["effort"] as? String == expectedString, 
                   "Effort level \(effort) should encode as '\(expectedString)'")
        }
    }
    
    @Test("Response decoding with reasoning tokens")
    func testResponseDecodingWithReasoningTokens() throws {
        let jsonString = """
        {
          "id": "gen-test123",
          "model": "openai/gpt-oss-20b:free",
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "The answer is 4."
              },
              "finish_reason": "stop"
            }
          ],
          "usage": {
            "prompt_tokens": 15,
            "completion_tokens": 85,
            "total_tokens": 100,
            "output_tokens_details": {
              "reasoning_tokens": 45
            }
          }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenRouterResponse.self, from: jsonData)
        
        #expect(response.id == "gen-test123", "Should decode response ID")
        #expect(response.usage != nil, "Should have usage information")
        #expect(response.usage?.output_tokens_details != nil, "Should have output token details")
        #expect(response.usage?.output_tokens_details?.reasoning_tokens == 45, 
               "Should decode reasoning tokens correctly")
        #expect(response.usage?.total_tokens == 100, "Should decode total tokens")
    }
    
    @Test("Response decoding without reasoning tokens")
    func testResponseDecodingWithoutReasoningTokens() throws {
        let jsonString = """
        {
          "id": "gen-test456",
          "model": "test-model",
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "Response without reasoning."
              },
              "finish_reason": "stop"
            }
          ],
          "usage": {
            "prompt_tokens": 10,
            "completion_tokens": 20,
            "total_tokens": 30
          }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenRouterResponse.self, from: jsonData)
        
        #expect(response.usage != nil, "Should have usage information")
        #expect(response.usage?.output_tokens_details == nil, 
               "Should handle missing output token details")
        #expect(response.usage?.total_tokens == 30, "Should decode total tokens")
    }
    
    @Test("StreamingDelta decoding with reasoning tokens")
    func testStreamingDeltaDecodingWithReasoningTokens() throws {
        let jsonString = """
        {
          "id": "gen-stream123",
          "object": "chat.completion.chunk",
          "created": 1234567890,
          "model": "openai/gpt-oss-20b:free",
          "choices": [
            {
              "delta": {
                "role": "assistant",
                "content": "The answer"
              },
              "index": 0,
              "finish_reason": null
            }
          ],
          "usage": {
            "prompt_tokens": 15,
            "completion_tokens": 50,
            "total_tokens": 65,
            "output_tokens_details": {
              "reasoning_tokens": 30
            }
          }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let delta = try decoder.decode(StreamingDelta.self, from: jsonData)
        
        #expect(delta.id == "gen-stream123", "Should decode delta ID")
        #expect(delta.usage != nil, "Should have usage information")
        #expect(delta.usage?.output_tokens_details != nil, "Should have output token details")
        #expect(delta.usage?.output_tokens_details?.reasoning_tokens == 30, 
               "Should decode reasoning tokens in streaming delta")
    }
}

@Suite("Reasoning Integration Tests")
struct ReasoningIntegrationTests {
    var client: OpenRouterClient!
    
    init() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] else {
            fatalError("API key not found in environment variables")
        }
        
        client = OpenRouterClient(
            apiKey: apiKey,
            siteURL: "www.github.com",
            siteName: "Swift OpenRouterKit Reasoning Tests",
            session: URLSession.shared
        )
    }
    
    // MARK: - Integration Tests (Real API Calls with Free Model)
    
    @Test("Chat request with reasoning - minimal effort")
    func testChatRequestWithReasoningMinimal() async throws {
        let messages: [Message] = [
            .init(role: .user, content: .string("What is 2+2? Show your work."))
        ]
        
        let request = OpenRouterRequest(
            messages: messages,
            model: "openai/gpt-oss-20b:free",
            maxTokens: 1000,
            reasoning: ReasoningConfiguration(effort: .minimal)
        )
        
        let response = try await client.sendChatRequest(request: request)
        
        #expect(response.choices.count == 1, "Response should contain one choice")
        #expect(!response.choices[0].message.content.isEmpty, "Response should contain a message")
        
        // Verify usage information is present
        #expect(response.usage != nil, "Response should contain usage information")
        if let usage = response.usage {
            #expect(usage.total_tokens > 0, "Should have token usage")
            
            // Note: reasoning_tokens may or may not be present depending on model response
            // This is expected behavior - some models may not return reasoning tokens
            print("Usage: \(usage.prompt_tokens) prompt + \(usage.completion_tokens) completion = \(usage.total_tokens) total")
            if let reasoningTokens = usage.output_tokens_details?.reasoning_tokens {
                print("Reasoning tokens used: \(reasoningTokens)")
            }
        }
    }
    
    @Test("Chat request with reasoning - high effort")
    func testChatRequestWithReasoningHigh() async throws {
        let messages: [Message] = [
            .init(role: .user, content: .string("Calculate 15 * 23. Explain each step."))
        ]
        
        let request = OpenRouterRequest(
            messages: messages,
            model: "openai/gpt-oss-20b:free",
            maxTokens: 1500,
            reasoning: ReasoningConfiguration(effort: .high)
        )
        
        let response = try await client.sendChatRequest(request: request)
        
        #expect(response.choices.count == 1, "Response should contain one choice")
        #expect(!response.choices[0].message.content.isEmpty, "Response should contain a message")
        #expect(response.usage != nil, "Response should contain usage information")
        
        print("Response with high effort reasoning:")
        print(response.choices[0].message.content)
        
        if let usage = response.usage {
            print("\nToken usage - Total: \(usage.total_tokens)")
            if let reasoningTokens = usage.output_tokens_details?.reasoning_tokens {
                print("Reasoning tokens: \(reasoningTokens)")
            }
        }
    }
    
    @Test("Stream chat request with reasoning")
    func testStreamChatRequestWithReasoning() async throws {
        let messages = [
            Message(role: .user, content: .string("Count from 1 to 5 and explain why you're counting."))
        ]
        
        var streamedResponse = ""
        
        let request = OpenRouterRequest(
            messages: messages,
            model: "openai/gpt-oss-20b:free",
            maxTokens: 1000,
            stream: true,
            reasoning: ReasoningConfiguration(effort: .medium)
        )
        
        let stream = client.streamChatRequest(request: request)
        
        var chunkCount = 0
        for await text in stream {
            streamedResponse += text
            chunkCount += 1
        }
        
        // Verify we got a response
        #expect(!streamedResponse.isEmpty, "Streamed response should not be empty")
        #expect(chunkCount > 0, "Should receive at least one chunk of data")
        
        print("Streamed \(chunkCount) chunks with reasoning (medium effort)")
        print("Final response length: \(streamedResponse.count) characters")
        print("Response: \(streamedResponse)")
    }
    
    @Test("Test all reasoning effort levels")
    func testAllReasoningEffortLevelsAPI() async throws {
        let efforts: [(ReasoningEffort, String)] = [
            (.minimal, "minimal"),
            (.low, "low"),
            (.medium, "medium"),
            (.high, "high")
        ]
        
        for (effort, name) in efforts {
            let messages: [Message] = [
                .init(role: .user, content: .string("What is 3+3?"))
            ]
            
            let request = OpenRouterRequest(
                messages: messages,
                model: "openai/gpt-oss-20b:free",
                maxTokens: 500,
                reasoning: ReasoningConfiguration(effort: effort)
            )
            
            let response = try await client.sendChatRequest(request: request)
            
            #expect(response.choices.count == 1, "Response with \(name) effort should contain one choice")
            #expect(!response.choices[0].message.content.isEmpty, "Response should contain content")
            
            print("\nEffort level: \(name)")
            print("Response: \(response.choices[0].message.content)")
            if let usage = response.usage {
                print("Tokens: \(usage.total_tokens)")
                if let reasoningTokens = usage.output_tokens_details?.reasoning_tokens {
                    print("Reasoning tokens: \(reasoningTokens)")
                }
            }
        }
    }
    
    @Test("Request without reasoning still works")
    func testRequestWithoutReasoning() async throws {
        let messages: [Message] = [
            .init(role: .user, content: .string("Say hello."))
        ]
        
        let request = OpenRouterRequest(
            messages: messages,
            model: "openai/gpt-oss-20b:free",
            maxTokens: 100
            // No reasoning parameter
        )
        
        let response = try await client.sendChatRequest(request: request)
        
        #expect(response.choices.count == 1, "Response should work without reasoning")
        #expect(!response.choices[0].message.content.isEmpty, "Response should contain a message")
        
        print("Response without reasoning: \(response.choices[0].message.content)")
    }
}
