//
//  ToolCallStreamingTests.swift
//  OpenRouterKit
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Tool Call Unit Tests — streaming")
struct ToolCallStreamingTests {

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
        let events = SSEParser.processLineAsEvents(line)

        #expect(events.count == 1)
        if case .text(let text) = events[0] {
            #expect(text == "Hello")
        } else {
            Issue.record("Expected .text event")
        }
    }

    @Test("processLineAsEvents extracts tool call deltas")
    func testProcessLineAsEventsToolCall() {
        let line = "data: {\"id\":\"gen-1\",\"choices\":[{\"delta\":{\"tool_calls\":[{\"index\":0,"
            + "\"id\":\"call_1\",\"type\":\"function\",\"function\":{\"name\":\"get_weather\","
            + "\"arguments\":\"{\\\"loc\"}}]},\"index\":0}]}"
        let events = SSEParser.processLineAsEvents(line)

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
        let line = "data: {\"id\":\"gen-1\",\"choices\":[{\"delta\":{},\"index\":0,\"finish_reason\":\"tool_calls\"}],"
            + "\"usage\":{\"prompt_tokens\":10,\"completion_tokens\":5,\"total_tokens\":15}}"
        let events = SSEParser.processLineAsEvents(line)

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
        #expect(SSEParser.processLineAsEvents("").isEmpty)
        #expect(SSEParser.processLineAsEvents(": comment\n").isEmpty)
        #expect(SSEParser.processLineAsEvents("data: [DONE]\n").isEmpty)
    }

    @Test("processLineAsEvents returns multiple events from one line")
    func testProcessLineAsEventsMultipleEvents() {
        // A line with both text content and a finish reason
        let line = """
        data: {"id":"gen-1","choices":[{"delta":{"content":"done"},"index":0,"finish_reason":"stop"}]}
        """
        let events = SSEParser.processLineAsEvents(line)

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
