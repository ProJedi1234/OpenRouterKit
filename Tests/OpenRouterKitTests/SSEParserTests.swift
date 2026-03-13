//
//  SSEParserTests.swift
//  OpenRouterKit
//
//  Unit tests for SSE (Server-Sent Events) line parsing.
//  These tests run on all platforms with no network dependency.
//

import Testing
import Foundation
@testable import OpenRouterKit

@Suite("SSE Parser")
struct SSEParserTests {

    // MARK: - processLine tests

    @Test func testProcessLineWithValidTextContent() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Hello\"},\"finish_reason\":null}]}\n"
        let result = SSEParser.processLine(line)
        #expect(result == "Hello")
    }

    @Test func testProcessLineWithEmptyLine() {
        let result = SSEParser.processLine("")
        #expect(result == nil)
    }

    @Test func testProcessLineWithWhitespaceOnly() {
        let result = SSEParser.processLine("   \n")
        #expect(result == nil)
    }

    @Test func testProcessLineWithNonDataPrefix() {
        let result = SSEParser.processLine("event: message\n")
        #expect(result == nil)
    }

    @Test func testProcessLineWithDoneMarker() {
        let result = SSEParser.processLine("data: [DONE]\n")
        #expect(result == nil)
    }

    @Test func testProcessLineWithEmptyContent() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"\"},\"finish_reason\":null}]}\n"
        let result = SSEParser.processLine(line)
        #expect(result == nil)
    }

    @Test func testProcessLineWithNilContent() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\"},\"finish_reason\":null}]}\n"
        let result = SSEParser.processLine(line)
        #expect(result == nil)
    }

    @Test func testProcessLineWithInvalidJSON() {
        let result = SSEParser.processLine("data: not valid json\n")
        #expect(result == nil)
    }

    @Test func testProcessLineWithMultiWordContent() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Hello, world!\"},\"finish_reason\":null}]}\n"
        let result = SSEParser.processLine(line)
        #expect(result == "Hello, world!")
    }

    // MARK: - processLineAsEvents tests

    @Test func testProcessLineAsEventsWithTextContent() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Hi\"},\"finish_reason\":null}]}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 1)
        if case .text(let content) = events.first {
            #expect(content == "Hi")
        } else {
            Issue.record("Expected .text event")
        }
    }

    @Test func testProcessLineAsEventsWithFinishReason() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}]}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 1)
        if case .finished(let reason, _) = events.first {
            #expect(reason == "stop")
        } else {
            Issue.record("Expected .finished event")
        }
    }

    @Test func testProcessLineAsEventsWithToolCallDelta() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[{\"index\":0,\"id\":\"call_abc\",\"type\":\"function\",\"function\":{\"name\":\"get_weather\",\"arguments\":\"\"}}]},\"finish_reason\":null}]}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 1)
        if case .toolCallDelta(let delta) = events.first {
            #expect(delta.function?.name == "get_weather")
        } else {
            Issue.record("Expected .toolCallDelta event")
        }
    }

    @Test func testProcessLineAsEventsWithEmptyLine() {
        let events = SSEParser.processLineAsEvents("")
        #expect(events.isEmpty)
    }

    @Test func testProcessLineAsEventsWithDoneMarker() {
        let events = SSEParser.processLineAsEvents("data: [DONE]\n")
        #expect(events.isEmpty)
    }

    @Test func testProcessLineAsEventsWithTextAndFinish() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"done\"},\"finish_reason\":\"stop\"}]}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 2)
        if case .text(let content) = events[0] {
            #expect(content == "done")
        } else {
            Issue.record("Expected .text event first")
        }
        if case .finished(let reason, _) = events[1] {
            #expect(reason == "stop")
        } else {
            Issue.record("Expected .finished event second")
        }
    }

    // MARK: - Usage data tests

    @Test func testProcessLineAsEventsWithUsageOnlyChunk() {
        let line = "data: {\"id\":\"gen-xxx\",\"choices\":[],\"usage\":{\"prompt_tokens\":10,\"completion_tokens\":20,\"total_tokens\":30}}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 1)
        if case .finished(let reason, let usage) = events.first {
            #expect(reason == nil)
            #expect(usage?.prompt_tokens == 10)
            #expect(usage?.completion_tokens == 20)
            #expect(usage?.total_tokens == 30)
        } else {
            Issue.record("Expected .finished event with usage")
        }
    }

    @Test func testProcessLineAsEventsWithFinishReasonAndUsage() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":5,\"completion_tokens\":15,\"total_tokens\":20}}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 1)
        if case .finished(let reason, let usage) = events.first {
            #expect(reason == "stop")
            #expect(usage?.prompt_tokens == 5)
            #expect(usage?.completion_tokens == 15)
            #expect(usage?.total_tokens == 20)
        } else {
            Issue.record("Expected .finished event with reason and usage")
        }
    }

    @Test func testProcessLineAsEventsWithNormalTextChunkNoUsage() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"hello\"},\"finish_reason\":null}]}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 1)
        if case .text(let content) = events.first {
            #expect(content == "hello")
        } else {
            Issue.record("Expected .text event")
        }
    }

    @Test func testProcessLineAsEventsWithToolCallsFinishReason() {
        let line = "data: {\"id\":\"gen-123\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"tool_calls\"}]}\n"
        let events = SSEParser.processLineAsEvents(line)
        #expect(events.count == 1)
        if case .finished(let reason, let usage) = events.first {
            #expect(reason == "tool_calls")
            #expect(usage == nil)
        } else {
            Issue.record("Expected .finished event with tool_calls reason")
        }
    }
}
