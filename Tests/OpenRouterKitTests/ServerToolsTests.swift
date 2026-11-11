//
//  ServerToolsTests.swift
//  OpenRouterKit
//
//  Tests for OpenRouter server tools (openrouter:web_search and friends).
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Server Tools - Request Encoding")
struct ServerToolsRequestTests {
    private func encodeJSON<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("Web search with no parameters encodes only its type")
    func webSearchWithoutParameters() throws {
        let json = try encodeJSON(Tool.webSearch())

        #expect(json["type"] as? String == "openrouter:web_search")
        #expect(json["parameters"] == nil)
        #expect(json["function"] == nil)
    }

    @Test("Web search parameters encode with snake_case keys")
    func webSearchParameters() throws {
        let tool = Tool.webSearch(WebSearchParameters(
            engine: .exa,
            mode: "fast",
            maxResults: 3,
            maxUses: 2,
            maxTotalResults: 6,
            searchContextSize: .high,
            maxCharacters: 2000,
            userLocation: WebSearchUserLocation(city: "Seattle", country: "US", timezone: "America/Los_Angeles"),
            allowedDomains: ["swift.org"],
            excludedDomains: ["example.com"]
        ))
        let json = try encodeJSON(tool)
        let parameters = try #require(json["parameters"] as? [String: Any])

        #expect(json["function"] == nil)
        #expect(parameters["engine"] as? String == "exa")
        #expect(parameters["mode"] as? String == "fast")
        #expect(parameters["max_results"] as? Int == 3)
        #expect(parameters["max_uses"] as? Int == 2)
        #expect(parameters["max_total_results"] as? Int == 6)
        #expect(parameters["search_context_size"] as? String == "high")
        #expect(parameters["max_characters"] as? Int == 2000)
        #expect(parameters["allowed_domains"] as? [String] == ["swift.org"])
        #expect(parameters["excluded_domains"] as? [String] == ["example.com"])

        let location = try #require(parameters["user_location"] as? [String: Any])
        #expect(location["type"] as? String == "approximate")
        #expect(location["city"] as? String == "Seattle")
        #expect(location["country"] as? String == "US")
        #expect(location["timezone"] as? String == "America/Los_Angeles")
        #expect(location["region"] == nil)
    }

    @Test("Raw server tool passes its type and parameters through")
    func rawServerTool() throws {
        let tool = Tool.serverTool(
            type: "openrouter:datetime",
            parameters: .object(["timezone": .string("America/New_York")])
        )
        let json = try encodeJSON(tool)

        #expect(json["type"] as? String == "openrouter:datetime")
        #expect(json["function"] == nil)
        let parameters = try #require(json["parameters"] as? [String: Any])
        #expect(parameters["timezone"] as? String == "America/New_York")
    }

    @Test("Function tools still encode a function and no parameters key")
    func functionToolUnchanged() throws {
        let tool = Tool(function: FunctionDescription(
            name: "get_weather",
            parameters: .object(["type": .string("object")])
        ))
        let json = try encodeJSON(tool)

        #expect(json["type"] as? String == "function")
        #expect(json["parameters"] == nil)
        let function = try #require(json["function"] as? [String: Any])
        #expect(function["name"] as? String == "get_weather")
    }

    @Test("Server and function tools share one request")
    func mixedToolsRequest() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("hi"))],
            model: "test-model",
            tools: [
                .webSearch(WebSearchParameters(engine: .exa)),
                Tool(function: FunctionDescription(name: "get_weather", parameters: .object([:])))
            ]
        )
        let json = try encodeJSON(request)
        let tools = try #require(json["tools"] as? [[String: Any]])

        #expect(tools.count == 2)
        #expect(tools[0]["type"] as? String == "openrouter:web_search")
        #expect(tools[1]["type"] as? String == "function")
        #expect(tools[1]["function"] != nil)
    }
}

@Suite("Server Tools - Response Decoding")
struct ServerToolsResponseTests {
    // Chunks below are trimmed copies of a live openai/gpt-5-mini stream using openrouter:web_search.
    private static let annotationChunk = """
    data: {"id":"gen-1","object":"chat.completion.chunk","created":1794341399,"model":"openai/gpt-5-mini",\
    "provider":"OpenAI","choices":[{"index":0,"delta":{"content":"","role":"assistant","annotations":[{"type":"url_citation",\
    "url_citation":{"url":"https://forums.swift.org/t/announcing-swift-6-4-2/90337",\
    "title":"Announcing Swift 6.4.2 - Announcements - Swift Forums","start_index":86,"end_index":163}}]},\
    "finish_reason":null,"native_finish_reason":null}]}
    """

    private static let usageChunk = """
    data: {"id":"gen-1","object":"chat.completion.chunk","created":1794341399,"model":"openai/gpt-5-mini",\
    "provider":"OpenAI","choices":[{"index":0,"delta":{"content":"","role":"assistant"},"finish_reason":"stop",\
    "native_finish_reason":"completed"}],"usage":{"prompt_tokens":11522,"completion_tokens":815,"total_tokens":12337,\
    "cost":0.0237041,"server_tool_use_details":{"web_search_requests":2}}}
    """

    @Test("Streamed annotations become an annotations event")
    func streamedAnnotations() throws {
        let events = SSEParser.processLineAsEvents(Self.annotationChunk)

        #expect(events.count == 1)
        guard case .annotations(let annotations) = events.first else {
            Issue.record("Expected an annotations event, got \(events)")
            return
        }
        let citation = try #require(annotations.first?.urlCitation)
        #expect(annotations.first?.type == "url_citation")
        #expect(citation.url == "https://forums.swift.org/t/announcing-swift-6-4-2/90337")
        #expect(citation.title == "Announcing Swift 6.4.2 - Announcements - Swift Forums")
        #expect(citation.startIndex == 86)
        #expect(citation.endIndex == 163)
    }

    @Test("Streamed usage carries server tool use details")
    func streamedServerToolUsage() throws {
        let events = SSEParser.processLineAsEvents(Self.usageChunk)

        guard case .finished(let reason, let usage) = events.last else {
            Issue.record("Expected a finished event, got \(events)")
            return
        }
        #expect(reason == "stop")
        #expect(usage?.server_tool_use_details?.web_search_requests == 2)
        #expect(usage?.server_tool_use_details?.tool_calls_executed == nil)
    }

    @Test("Non-streaming message decodes annotations and server tool usage")
    func nonStreamingResponse() throws {
        let json = """
        {
          "id": "gen-2",
          "model": "openai/gpt-5-mini",
          "provider": "OpenAI",
          "choices": [{
            "finish_reason": "stop",
            "message": {
              "role": "assistant",
              "content": "Swift 6.4.2 is the latest release.",
              "annotations": [{
                "type": "url_citation",
                "url_citation": {"url": "https://swift.org", "title": "Swift.org", "content": "Swift 6.4.2 [...]"}
              }]
            }
          }],
          "usage": {
            "prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15,
            "server_tool_use_details": {"tool_calls_requested": 1, "tool_calls_executed": 1}
          }
        }
        """
        let response = try JSONDecoder().decode(ChatResponse.self, from: Data(json.utf8))
        let message = try #require(response.choices.first?.message)

        #expect(message.annotations?.first?.urlCitation?.url == "https://swift.org")
        #expect(message.annotations?.first?.urlCitation?.content == "Swift 6.4.2 [...]")
        #expect(message.toolCalls == nil)
        #expect(response.usage?.server_tool_use_details?.tool_calls_requested == 1)
        #expect(response.usage?.server_tool_use_details?.tool_calls_executed == 1)
    }

    @Test("Unknown annotation types decode without a citation")
    func unknownAnnotationType() throws {
        let line = """
        data: {"id":"gen-3","choices":[{"index":0,"delta":{"content":"hi","annotations":[{"type":"file_citation"}]}}]}
        """
        let events = SSEParser.processLineAsEvents(line)

        #expect(events.count == 2)
        guard case .annotations(let annotations) = events.last else {
            Issue.record("Expected an annotations event, got \(events)")
            return
        }
        #expect(annotations.first?.type == "file_citation")
        #expect(annotations.first?.urlCitation == nil)
    }

    @Test("Function calls after a server tool call start at index 1 and still accumulate")
    func functionCallAfterServerTool() throws {
        // A live mixed request (web search, then get_weather) streamed the function call at
        // index 1; the server tool call held index 0 but never appeared in the stream.
        let lines = [
            #"data: {"id":"g","choices":[{"index":0,"delta":{"tool_calls":[{"index":1,"id":"call_MG91","type":"function","#
                + #""function":{"name":"get_weather","arguments":""}}]}}]}"#,
            #"data: {"id":"g","choices":[{"index":0,"delta":{"tool_calls":[{"index":1,"function":{"arguments":"{\"location\":\"Paris\"}"}}]}}]}"#,
            #"data: {"id":"g","choices":[{"index":0,"delta":{"content":""},"finish_reason":"tool_calls"}]}"#
        ]
        var accumulator = ToolCallAccumulator()
        var finishReason: String?
        for event in lines.flatMap(SSEParser.processLineAsEvents) {
            switch event {
            case .toolCallDelta(let delta):
                accumulator.accumulate(delta)
            case .finished(let reason, _):
                finishReason = reason
            case .text, .audio, .annotations:
                break
            }
        }

        #expect(finishReason == "tool_calls")
        #expect(accumulator.toolCalls == [
            ToolCall(id: "call_MG91", function: ToolCallFunction(name: "get_weather", arguments: #"{"location":"Paris"}"#))
        ])
    }
}

@Suite("Server Tools - Integration",
       .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false))
struct ServerToolsIntegrationTests {
    let client: OpenRouterClient

    init() throws {
        let apiKey = try #require(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"])
        client = OpenRouterClient(
            apiKey: apiKey,
            siteURL: "https://github.com",
            siteName: "Swift OpenRouterKit Server Tools Tests"
        )
    }

    @Test("Web search returns citations and server tool usage")
    func webSearch() async throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string(
                "Search the web for the city that hosted the 2024 Summer Olympics. Answer in one sentence."
            ))],
            model: integrationTestModel,
            tools: [.webSearch(WebSearchParameters(engine: .exa, maxResults: 1))]
        )
        let response = try await client.chat.send(request: request)
        let message = try #require(response.choices.first?.message)

        #expect(message.toolCalls == nil, "Server tool calls should not surface as tool_calls")
        #expect(message.annotations?.contains { $0.urlCitation?.url?.isEmpty == false } == true)
        #expect((response.usage?.server_tool_use_details?.web_search_requests ?? 0) >= 1)
    }
}
