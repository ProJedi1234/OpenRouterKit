//
//  ToolCallDefinitionTests.swift
//  OpenRouterKit
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Tool Call Unit Tests — definitions")
struct ToolCallDefinitionTests {

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
}
