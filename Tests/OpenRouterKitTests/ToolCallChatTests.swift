//
//  ToolCallChatTests.swift
//  OpenRouterKit
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Tool Call Unit Tests — chat payloads")
struct ToolCallChatTests {

    @Test("ChatResponse decoding with tool_calls")
    func testChatResponseWithToolCalls() throws {
        let jsonString = """
        {
          "id": "gen-abc123",
          "model": "google/gemini-3-flash-preview",
          "choices": [
            {
              "finish_reason": "tool_calls",
              "message": {
                "role": "assistant",
                "content": null,
                "tool_calls": [
                  {
                    "id": "call_abc123",
                    "type": "function",
                    "function": {
                      "name": "get_weather",
                      "arguments": "{\\"location\\": \\"New York\\"}"
                    }
                  }
                ]
              }
            }
          ],
          "usage": {
            "prompt_tokens": 150,
            "completion_tokens": 25,
            "total_tokens": 175
          }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)

        #expect(response.id == "gen-abc123")
        #expect(response.choices.count == 1)
        #expect(response.choices[0].finish_reason == "tool_calls")
        #expect(response.choices[0].message.content == nil, "Content should be null for tool calls")
        let toolCalls = try #require(response.choices[0].message.toolCalls)
        #expect(toolCalls.count == 1)

        let toolCall = try #require(toolCalls.first)
        #expect(toolCall.id == "call_abc123")
        #expect(toolCall.type == "function")
        #expect(toolCall.function.name == "get_weather")
        #expect(toolCall.function.arguments.contains("New York"))
    }

    @Test("ChatResponse decoding with multiple tool_calls")
    func testChatResponseWithMultipleToolCalls() throws {
        let jsonString = """
        {
          "id": "gen-multi",
          "model": "test-model",
          "choices": [
            {
              "finish_reason": "tool_calls",
              "message": {
                "role": "assistant",
                "content": null,
                "tool_calls": [
                  {
                    "id": "call_1",
                    "type": "function",
                    "function": {
                      "name": "get_weather",
                      "arguments": "{\\"location\\": \\"NYC\\"}"
                    }
                  },
                  {
                    "id": "call_2",
                    "type": "function",
                    "function": {
                      "name": "get_weather",
                      "arguments": "{\\"location\\": \\"London\\"}"
                    }
                  }
                ]
              }
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)

        #expect(response.choices[0].message.toolCalls?.count == 2)
        #expect(response.choices[0].message.toolCalls?[0].id == "call_1")
        #expect(response.choices[0].message.toolCalls?[1].id == "call_2")
    }

    @Test("ChatResponse decoding without tool_calls (regular response)")
    func testChatResponseWithoutToolCalls() throws {
        let jsonString = """
        {
          "id": "gen-normal",
          "model": "test-model",
          "choices": [
            {
              "finish_reason": "stop",
              "message": {
                "role": "assistant",
                "content": "Hello! How can I help you?"
              }
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)

        #expect(response.choices[0].message.content == "Hello! How can I help you?")
        #expect(response.choices[0].message.toolCalls == nil)
        #expect(response.choices[0].finish_reason == "stop")
    }

    // MARK: - ChatRequest with Tools Encoding Tests

    @Test("Full ChatRequest with tools encoding")
    func testFullChatRequestWithToolsEncoding() throws {
        let tool = Tool(function: FunctionDescription(
            name: "get_weather",
            description: "Get weather for a location",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("City name")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        ))

        let request = ChatRequest(
            messages: [
                Message(role: .user, content: .string("What's the weather in NYC?"))
            ],
            model: "google/gemini-3-flash-preview",
            tools: [tool],
            toolChoice: .auto
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["model"] as? String == "google/gemini-3-flash-preview")
        #expect(json?["tool_choice"] as? String == "auto")

        let tools = json?["tools"] as? [[String: Any]]
        #expect(tools?.count == 1)
        #expect(tools?[0]["type"] as? String == "function")
    }

    @Test("ChatRequest with tool result messages encoding")
    func testChatRequestWithToolResultEncoding() throws {
        // Simulate a full conversation with tool calls
        let messages: [Message] = [
            Message(role: .user, content: .string("What's the weather?")),
            Message(
                role: .assistant,
                content: nil,
                toolCalls: [
                    ToolCall(
                        id: "call_abc",
                        function: ToolCallFunction(
                            name: "get_weather",
                            arguments: "{\"location\":\"NYC\"}"
                        )
                    )
                ]
            ),
            Message(
                role: .tool,
                content: .string("{\"temp\": 72}"),
                toolCallId: "call_abc"
            )
        ]

        let request = ChatRequest(
            messages: messages,
            model: "test-model",
            tools: [Tool(function: FunctionDescription(
                name: "get_weather",
                parameters: .object(["type": .string("object")])
            ))]
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let msgsArray = json?["messages"] as? [[String: Any]]

        #expect(msgsArray?.count == 3)

        // Check user message
        #expect(msgsArray?[0]["role"] as? String == "user")

        // Check assistant message with tool_calls
        #expect(msgsArray?[1]["role"] as? String == "assistant")
        let toolCalls = msgsArray?[1]["tool_calls"] as? [[String: Any]]
        #expect(toolCalls?.count == 1)
        #expect(toolCalls?[0]["id"] as? String == "call_abc")

        // Check tool result message
        #expect(msgsArray?[2]["role"] as? String == "tool")
        #expect(msgsArray?[2]["tool_call_id"] as? String == "call_abc")
        #expect(msgsArray?[2]["content"] as? String == "{\"temp\": 72}")
    }
}
