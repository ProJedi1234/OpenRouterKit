//
//  ToolCallTests.swift
//  OpenRouterKit
//
//  Tests for tool call support
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Tool Call Unit Tests")
struct ToolCallUnitTests {

    // MARK: - JSONValue Tests

    @Test("JSONValue encoding and decoding")
    func testJSONValueRoundTrip() throws {
        let schema: JSONValue = .object([
            "type": .string("object"),
            "properties": .object([
                "location": .object([
                    "type": .string("string"),
                    "description": .string("The city name")
                ]),
                "units": .object([
                    "type": .string("string"),
                    "enum": .array([.string("celsius"), .string("fahrenheit")])
                ])
            ]),
            "required": .array([.string("location")])
        ])

        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == schema, "JSONValue should round-trip correctly")
    }

    @Test("JSONValue all types")
    func testJSONValueAllTypes() throws {
        let values: [JSONValue] = [
            .string("hello"),
            .int(42),
            .double(3.14),
            .bool(true),
            .bool(false),
            .null,
            .array([.int(1), .string("two"), .bool(true)]),
            .object(["key": .string("value")])
        ]

        for value in values {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
            #expect(decoded == value, "JSONValue \(value) should round-trip correctly")
        }
    }

    // MARK: - Tool Definition Tests

    @Test("Tool encoding")
    func testToolEncoding() throws {
        let tool = Tool(function: FunctionDescription(
            name: "get_weather",
            description: "Get current weather for a location",
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

        let data = try JSONEncoder().encode(tool)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "function", "Tool type should be 'function'")
        let function = json?["function"] as? [String: Any]
        #expect(function?["name"] as? String == "get_weather", "Function name should match")
        #expect(function?["description"] as? String == "Get current weather for a location", "Description should match")
        let parameters = function?["parameters"] as? [String: Any]
        #expect(parameters?["type"] as? String == "object", "Parameters should have type 'object'")
    }

    @Test("Tool decoding")
    func testToolDecoding() throws {
        let jsonString = """
        {
          "type": "function",
          "function": {
            "name": "search_books",
            "description": "Search for books",
            "parameters": {
              "type": "object",
              "properties": {
                "query": {
                  "type": "string",
                  "description": "Search query"
                },
                "limit": {
                  "type": "integer",
                  "description": "Max results"
                }
              },
              "required": ["query"]
            }
          }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let tool = try JSONDecoder().decode(Tool.self, from: data)

        #expect(tool.type == "function")
        #expect(tool.function.name == "search_books")
        #expect(tool.function.description == "Search for books")
    }

    // MARK: - ToolChoice Tests

    @Test("ToolChoice none encoding")
    func testToolChoiceNoneEncoding() throws {
        let choice = ToolChoice.none
        let data = try JSONEncoder().encode(choice)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "\"none\"", "ToolChoice.none should encode as \"none\"")
    }

    @Test("ToolChoice auto encoding")
    func testToolChoiceAutoEncoding() throws {
        let choice = ToolChoice.auto
        let data = try JSONEncoder().encode(choice)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "\"auto\"", "ToolChoice.auto should encode as \"auto\"")
    }

    @Test("ToolChoice required encoding")
    func testToolChoiceRequiredEncoding() throws {
        let choice = ToolChoice.required
        let data = try JSONEncoder().encode(choice)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "\"required\"", "ToolChoice.required should encode as \"required\"")
    }

    @Test("ToolChoice function encoding")
    func testToolChoiceFunctionEncoding() throws {
        let choice = ToolChoice.function(name: "get_weather")
        let data = try JSONEncoder().encode(choice)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "function")
        let function = json?["function"] as? [String: Any]
        #expect(function?["name"] as? String == "get_weather")
    }

    @Test("ToolChoice decoding all variants")
    func testToolChoiceDecoding() throws {
        // String variants
        for (jsonStr, expected) in [
            ("\"none\"", ToolChoice.none),
            ("\"auto\"", ToolChoice.auto),
            ("\"required\"", ToolChoice.required)
        ] {
            let data = jsonStr.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(ToolChoice.self, from: data)
            switch (decoded, expected) {
            case (.none, .none), (.auto, .auto), (.required, .required):
                break // Match
            default:
                Issue.record("ToolChoice decoding mismatch for \(jsonStr)")
            }
        }

        // Object variant
        let funcJson = """
        {"type": "function", "function": {"name": "my_func"}}
        """
        let data = funcJson.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ToolChoice.self, from: data)
        if case .function(let name) = decoded {
            #expect(name == "my_func")
        } else {
            Issue.record("Expected .function case")
        }
    }

    // MARK: - ToolCall Tests

    @Test("ToolCall encoding and decoding")
    func testToolCallRoundTrip() throws {
        let toolCall = ToolCall(
            id: "call_abc123",
            type: "function",
            function: ToolCallFunction(
                name: "get_weather",
                arguments: "{\"location\":\"New York\"}"
            )
        )

        let data = try JSONEncoder().encode(toolCall)
        let decoded = try JSONDecoder().decode(ToolCall.self, from: data)

        #expect(decoded == toolCall, "ToolCall should round-trip correctly")
        #expect(decoded.id == "call_abc123")
        #expect(decoded.function.name == "get_weather")
        #expect(decoded.function.arguments == "{\"location\":\"New York\"}")
    }

    // MARK: - Message with Tool Call Tests

    @Test("Message with tool_calls encoding")
    func testMessageWithToolCallsEncoding() throws {
        let message = Message(
            role: .assistant,
            content: nil,
            toolCalls: [
                ToolCall(
                    id: "call_123",
                    function: ToolCallFunction(
                        name: "get_weather",
                        arguments: "{\"location\":\"London\"}"
                    )
                )
            ]
        )

        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["role"] as? String == "assistant")
        let toolCalls = json?["tool_calls"] as? [[String: Any]]
        #expect(toolCalls?.count == 1)
        #expect(toolCalls?[0]["id"] as? String == "call_123")
    }

    @Test("Tool result message encoding")
    func testToolResultMessageEncoding() throws {
        let message = Message(
            role: .tool,
            content: .string("{\"temperature\": 72, \"condition\": \"sunny\"}"),
            toolCallId: "call_123"
        )

        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["role"] as? String == "tool")
        #expect(json?["tool_call_id"] as? String == "call_123")
        #expect(json?["content"] as? String == "{\"temperature\": 72, \"condition\": \"sunny\"}")
    }

    // MARK: - ChatResponse with Tool Calls Tests

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

    // MARK: - StreamingDelta with Tool Calls Tests

    @Test("StreamingDelta decoding with tool_calls delta")
    func testStreamingDeltaWithToolCalls() throws {
        let jsonString = """
        {
          "id": "gen-stream",
          "choices": [
            {
              "delta": {
                "role": "assistant",
                "tool_calls": [
                  {
                    "index": 0,
                    "id": "call_stream1",
                    "type": "function",
                    "function": {
                      "name": "get_weather",
                      "arguments": "{\\"loc"
                    }
                  }
                ]
              },
              "index": 0,
              "finish_reason": null
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let delta = try JSONDecoder().decode(StreamingDelta.self, from: data)

        let toolCallDeltas = try #require(delta.choices[0].delta.toolCalls)
        #expect(toolCallDeltas.count == 1)
        let toolCallDelta = try #require(toolCallDeltas.first)
        #expect(toolCallDelta.index == 0)
        #expect(toolCallDelta.id == "call_stream1")
        #expect(toolCallDelta.type == "function")
        #expect(toolCallDelta.function?.name == "get_weather")
        #expect(toolCallDelta.function?.arguments == "{\"loc")
    }

    @Test("StreamingDelta decoding continuation chunk (no id)")
    func testStreamingDeltaContinuationChunk() throws {
        let jsonString = """
        {
          "id": "gen-stream",
          "choices": [
            {
              "delta": {
                "tool_calls": [
                  {
                    "index": 0,
                    "function": {
                      "arguments": "ation\\":\\"NYC\\"}"
                    }
                  }
                ]
              },
              "index": 0,
              "finish_reason": null
            }
          ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let delta = try JSONDecoder().decode(StreamingDelta.self, from: data)

        let continuationDeltas = try #require(delta.choices[0].delta.toolCalls)
        let toolCallDelta = try #require(continuationDeltas.first)
        #expect(toolCallDelta.index == 0)
        #expect(toolCallDelta.id == nil, "Continuation chunk should not have id")
        #expect(toolCallDelta.function?.arguments == "ation\":\"NYC\"}")
    }

    // MARK: - ToolCallAccumulator Tests

    @Test("ToolCallAccumulator assembles a single tool call")
    func testAccumulatorSingleToolCall() {
        var accumulator = ToolCallAccumulator()

        // First delta: id, type, function name, and partial arguments
        accumulator.accumulate(ToolCallDelta(
            index: 0,
            id: "call_abc",
            type: "function",
            function: ToolCallFunctionDelta(name: "get_weather", arguments: "{\"loc")
        ))

        // Continuation: more arguments
        accumulator.accumulate(ToolCallDelta(
            index: 0,
            function: ToolCallFunctionDelta(arguments: "ation\":\"NYC\"}")
        ))

        let calls = accumulator.toolCalls
        #expect(calls.count == 1)
        #expect(calls[0].id == "call_abc")
        #expect(calls[0].type == "function")
        #expect(calls[0].function.name == "get_weather")
        #expect(calls[0].function.arguments == "{\"location\":\"NYC\"}")
    }

    @Test("ToolCallAccumulator assembles multiple interleaved tool calls")
    func testAccumulatorMultipleToolCalls() {
        var accumulator = ToolCallAccumulator()

        // First tool call start
        accumulator.accumulate(ToolCallDelta(
            index: 0,
            id: "call_1",
            type: "function",
            function: ToolCallFunctionDelta(name: "get_weather", arguments: "{\"city\":")
        ))

        // Second tool call start
        accumulator.accumulate(ToolCallDelta(
            index: 1,
            id: "call_2",
            type: "function",
            function: ToolCallFunctionDelta(name: "get_time", arguments: "{\"tz\":")
        ))

        // First tool call continuation
        accumulator.accumulate(ToolCallDelta(
            index: 0,
            function: ToolCallFunctionDelta(arguments: "\"NYC\"}")
        ))

        // Second tool call continuation
        accumulator.accumulate(ToolCallDelta(
            index: 1,
            function: ToolCallFunctionDelta(arguments: "\"EST\"}")
        ))

        let calls = accumulator.toolCalls
        #expect(calls.count == 2)

        #expect(calls[0].id == "call_1")
        #expect(calls[0].function.name == "get_weather")
        #expect(calls[0].function.arguments == "{\"city\":\"NYC\"}")

        #expect(calls[1].id == "call_2")
        #expect(calls[1].function.name == "get_time")
        #expect(calls[1].function.arguments == "{\"tz\":\"EST\"}")
    }

    @Test("ToolCallAccumulator reset clears state")
    func testAccumulatorReset() {
        var accumulator = ToolCallAccumulator()

        accumulator.accumulate(ToolCallDelta(
            index: 0,
            id: "call_1",
            type: "function",
            function: ToolCallFunctionDelta(name: "func1", arguments: "{}")
        ))

        #expect(accumulator.toolCalls.count == 1)

        accumulator.reset()
        #expect(accumulator.toolCalls.isEmpty)
    }

    // MARK: - processLineAsEvents Tests

    @Test("processLineAsEvents extracts text content")
    func testProcessLineAsEventsText() {
        let line = "data: {\"id\":\"gen-1\",\"choices\":[{\"delta\":{\"content\":\"Hello\"},\"index\":0}]}\n"
        let events = URLSessionHTTPClient.processLineAsEvents(line)

        #expect(events.count == 1)
        if case .text(let text) = events[0] {
            #expect(text == "Hello")
        } else {
            Issue.record("Expected .text event")
        }
    }

    @Test("processLineAsEvents extracts tool call deltas")
    func testProcessLineAsEventsToolCall() {
        let line = """
        data: {"id":"gen-1","choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"get_weather","arguments":"{\\"loc"}}]},"index":0}]}
        """
        let events = URLSessionHTTPClient.processLineAsEvents(line)

        #expect(events.count == 1)
        if case .toolCallDelta(let delta) = events[0] {
            #expect(delta.index == 0)
            #expect(delta.id == "call_1")
            #expect(delta.function?.name == "get_weather")
        } else {
            Issue.record("Expected .toolCallDelta event")
        }
    }

    @Test("processLineAsEvents extracts finish reason")
    func testProcessLineAsEventsFinished() {
        let line = """
        data: {"id":"gen-1","choices":[{"delta":{},"index":0,"finish_reason":"tool_calls"}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}
        """
        let events = URLSessionHTTPClient.processLineAsEvents(line)

        #expect(events.count == 1)
        if case .finished(let reason, let usage) = events[0] {
            #expect(reason == "tool_calls")
            #expect(usage?.prompt_tokens == 10)
            #expect(usage?.total_tokens == 15)
        } else {
            Issue.record("Expected .finished event")
        }
    }

    @Test("processLineAsEvents returns empty for non-data lines")
    func testProcessLineAsEventsIgnoresNonData() {
        #expect(URLSessionHTTPClient.processLineAsEvents("").isEmpty)
        #expect(URLSessionHTTPClient.processLineAsEvents(": comment\n").isEmpty)
        #expect(URLSessionHTTPClient.processLineAsEvents("data: [DONE]\n").isEmpty)
    }

    @Test("processLineAsEvents returns multiple events from one line")
    func testProcessLineAsEventsMultipleEvents() {
        // A line with both text content and a finish reason
        let line = """
        data: {"id":"gen-1","choices":[{"delta":{"content":"done"},"index":0,"finish_reason":"stop"}]}
        """
        let events = URLSessionHTTPClient.processLineAsEvents(line)

        #expect(events.count == 2)
        if case .text(let text) = events[0] {
            #expect(text == "done")
        } else {
            Issue.record("Expected .text event first")
        }
        if case .finished(let reason, _) = events[1] {
            #expect(reason == "stop")
        } else {
            Issue.record("Expected .finished event second")
        }
    }

    // MARK: - FunctionDescription with strict parameter Tests

    @Test("FunctionDescription with strict parameter")
    func testFunctionDescriptionStrict() throws {
        let funcDesc = FunctionDescription(
            name: "test_func",
            description: "A test function",
            parameters: .object(["type": .string("object")]),
            strict: true
        )

        let data = try JSONEncoder().encode(funcDesc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["strict"] as? Bool == true)
        #expect(json?["name"] as? String == "test_func")
    }
}

@Suite("Tool Call Integration Tests",
       .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false))
struct ToolCallIntegrationTests {
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

        // Step 1: Send initial request with tool
        let request = ChatRequest(
            messages: [
                Message(role: .user, content: .string("What is the current weather in San Francisco? Use the get_weather tool."))
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
                Message(role: .user, content: .string("What is the current weather in San Francisco? Use the get_weather tool."))
            ]

            // Add the assistant message with tool calls
            conversationMessages.append(Message(
                role: .assistant,
                content: nil,
                toolCalls: toolCalls
            ))

            // Add the tool result
            conversationMessages.append(Message(
                role: .tool,
                content: .string("{\"temperature\": 65, \"condition\": \"foggy\", \"humidity\": 80}"),
                toolCallId: toolCall.id
            ))

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

    #if canImport(Darwin)
    @Test("Streaming tool calls via streamEvents")
    @available(iOS 15.0, macOS 12.0, *)
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
    #endif
}
