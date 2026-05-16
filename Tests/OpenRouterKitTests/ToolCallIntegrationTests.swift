//
//  ToolCallIntegrationTests.swift
//  OpenRouterKit
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Tool Call Integration Tests",
       .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false))
struct ToolCallIntegrationTests {
    private enum Fixtures {
        static let weatherUserPrompt =
            "What is the current weather in San Francisco? Use the get_weather tool."

        static func weatherTool() -> Tool {
            Tool(function: FunctionDescription(
                name: "get_weather",
                description: "Get the current weather for a given location. "
                    + "Always use this tool when asked about weather.",
                parameters: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "location": .object([
                            "type": .string("string"),
                            "description": .string("The city name, e.g. 'San Francisco'")
                        ])
                    ]),
                    "required": .array([.string("location")])
                ])
            ))
        }
    }

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
            siteName: "Swift OpenRouterKit Tool Call Tests",
            session: session
        )
    }

    @Test("Tool call request and response cycle")
    func testToolCallRequestAndResponse() async throws {
        let weatherTool = Fixtures.weatherTool()

        // Step 1: Send initial request with tool
        let request = ChatRequest(
            messages: [
                Message(role: .user, content: .string(Fixtures.weatherUserPrompt))
            ],
            model: "google/gemini-3-flash-preview",
            maxTokens: 1000,
            tools: [weatherTool],
            toolChoice: .auto
        )

        let response = try await client.chat.send(request: request)

        let choice = try #require(response.choices.first, "Should have at least one choice")

        // The model should have made a tool call
        if choice.finish_reason == "tool_calls" {
            let toolCalls = try #require(choice.message.toolCalls, "Should have tool_calls")
            #expect(toolCalls.count >= 1, "Should have at least one tool call")

            let toolCall = try #require(toolCalls.first)
            #expect(toolCall.function.name == "get_weather", "Should call get_weather")
            #expect(!toolCall.id.isEmpty, "Tool call should have an ID")
            #expect(!toolCall.function.arguments.isEmpty, "Tool call should have arguments")

            print("Tool call ID: \(toolCall.id)")
            print("Function: \(toolCall.function.name)")
            print("Arguments: \(toolCall.function.arguments)")

            // Step 2: Send back the tool result
            var conversationMessages: [Message] = [
                Message(role: .user, content: .string(Fixtures.weatherUserPrompt))
            ]

            // Add the assistant message with tool calls
            conversationMessages.append(Message(
                role: .assistant,
                content: nil,
                toolCalls: toolCalls
            ))

            // Add one tool result per tool call ID (APIs require a matching tool message per id).
            for tc in toolCalls {
                conversationMessages.append(Message(
                    role: .tool,
                    content: .string("{\"temperature\": 65, \"condition\": \"foggy\", \"humidity\": 80}"),
                    toolCallId: tc.id
                ))
            }

            let followUpRequest = ChatRequest(
                messages: conversationMessages,
                model: "google/gemini-3-flash-preview",
                maxTokens: 1000,
                tools: [weatherTool]
            )

            let finalResponse = try await client.chat.send(request: followUpRequest)

            let finalChoice = try #require(finalResponse.choices.first, "Final response should have at least one choice")
            #expect(finalChoice.message.content?.isEmpty == false,
                   "Final response should have text content")
            #expect(finalChoice.finish_reason == "stop",
                   "Final response should finish with stop")

            print("Final response: \(finalChoice.message.content ?? "")")
        } else {
            // Model responded with text instead of a tool call - this can happen
            // Just verify it's a valid response
            #expect(choice.message.content?.isEmpty == false,
                   "If no tool call, should have text content")
            print("Model responded directly without tool call: \(choice.message.content ?? "")")
        }
    }

    @Test("Tool call with required tool_choice")
    func testToolCallWithRequiredChoice() async throws {
        let mathTool = Tool(function: FunctionDescription(
            name: "calculate",
            description: "Perform a mathematical calculation",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "expression": .object([
                        "type": .string("string"),
                        "description": .string("The math expression to evaluate")
                    ])
                ]),
                "required": .array([.string("expression")])
            ])
        ))

        let request = ChatRequest(
            messages: [
                Message(role: .user, content: .string("What is 2 + 2?"))
            ],
            model: "google/gemini-3-flash-preview",
            maxTokens: 500,
            tools: [mathTool],
            toolChoice: .required
        )

        let response = try await client.chat.send(request: request)

        let choice = try #require(response.choices.first, "Should have at least one choice")

        // With tool_choice: required, model must call a tool
        #expect(choice.finish_reason == "tool_calls",
               "With required tool_choice, finish_reason should be tool_calls")
        let toolCalls = try #require(choice.message.toolCalls,
               "With required tool_choice, should have tool_calls")
        #expect(toolCalls.count >= 1)

        let toolCall = try #require(toolCalls.first)
        #expect(toolCall.function.name == "calculate",
               "Should call the calculate function")

        print("Required tool call - Function: \(toolCall.function.name)")
        print("Arguments: \(toolCall.function.arguments)")
    }

    @Test("Streaming tool calls via streamEvents", .enabled(if: isDarwin))
    func testStreamEventsToolCalls() async throws {
        let weatherTool = Tool(function: FunctionDescription(
            name: "get_weather",
            description: "Get the current weather for a given location. Always use this tool when asked about weather.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city name, e.g. 'San Francisco'")
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

        var accumulator = ToolCallAccumulator()
        var receivedToolCallDelta = false
        var finishReason: String?
        var textChunks: [String] = []

        let stream = try await client.chat.streamEvents(request: request)
        for try await event in stream {
            switch event {
            case .text(let text):
                textChunks.append(text)
            case .toolCallDelta(let delta):
                receivedToolCallDelta = true
                accumulator.accumulate(delta)
            case .audio:
                break
            case .finished(let reason, _):
                finishReason = reason
            }
        }

        #expect(receivedToolCallDelta, "Should have received at least one tool call delta")
        #expect(finishReason == "tool_calls", "Finish reason should be tool_calls")

        let toolCalls = accumulator.toolCalls
        #expect(toolCalls.count >= 1, "Should have accumulated at least one tool call")

        let toolCall = try #require(toolCalls.first)
        #expect(toolCall.function.name == "get_weather", "Should call get_weather")
        #expect(!toolCall.id.isEmpty, "Tool call should have an ID")
        #expect(!toolCall.function.arguments.isEmpty, "Tool call should have arguments")

        print("Streaming tool call ID: \(toolCall.id)")
        print("Function: \(toolCall.function.name)")
        print("Arguments: \(toolCall.function.arguments)")
    }

    @Test("Streaming parallel tool calls via streamEvents", .enabled(if: isDarwin))
    func testStreamEventsParallelToolCalls() async throws {
        let weatherTool = Tool(function: FunctionDescription(
            name: "get_weather",
            description: "Get the current weather for a given location. Always use this tool when asked about weather.",
            parameters: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city name, e.g. 'San Francisco'")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        ))

        let request = ChatRequest(
            messages: [
                Message(role: .user, content: .string("What is the weather in both Tokyo and New York? Use the get_weather tool for each city."))
            ],
            model: "google/gemini-3-flash-preview",
            maxTokens: 500,
            tools: [weatherTool],
            toolChoice: .required
        )

        var accumulator = ToolCallAccumulator()
        var finishReason: String?

        let stream = try await client.chat.streamEvents(request: request)
        for try await event in stream {
            switch event {
            case .text:
                break
            case .toolCallDelta(let delta):
                accumulator.accumulate(delta)
            case .audio:
                break
            case .finished(let reason, _):
                finishReason = reason
            }
        }

        #expect(finishReason == "tool_calls", "Finish reason should be tool_calls")

        let toolCalls = accumulator.toolCalls
        #expect(toolCalls.count >= 1, "Should have accumulated at least one tool call")

        for (i, toolCall) in toolCalls.enumerated() {
            #expect(toolCall.function.name == "get_weather", "Tool call \(i) should be get_weather")
            #expect(!toolCall.id.isEmpty, "Tool call \(i) should have an ID")
            #expect(!toolCall.function.arguments.isEmpty, "Tool call \(i) should have arguments")
            print("Tool call \(i): \(toolCall.function.name)(\(toolCall.function.arguments))")
        }
    }
}
