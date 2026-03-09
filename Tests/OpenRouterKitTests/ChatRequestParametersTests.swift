//
//  ChatRequestParametersTests.swift
//  OpenRouterKit
//
//  Tests for new ChatRequest parameters (issue #16)
//

import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("ChatRequest New Parameters - Unit Tests")
struct ChatRequestParametersUnitTests {

    // MARK: - Nil Omission (Backward Compatibility)

    @Test("New parameters are omitted from JSON when nil")
    func testNilParametersOmitted() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("Hello"))],
            model: "test-model"
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // None of the new parameters should appear
        #expect(json?["max_completion_tokens"] == nil)
        #expect(json?["stream_options"] == nil)
        #expect(json?["logprobs"] == nil)
        #expect(json?["top_logprobs"] == nil)
        #expect(json?["parallel_tool_calls"] == nil)
        #expect(json?["modalities"] == nil)
        #expect(json?["user"] == nil)
        #expect(json?["metadata"] == nil)
        #expect(json?["session_id"] == nil)
        #expect(json?["trace"] == nil)
        #expect(json?["cache_control"] == nil)
        #expect(json?["debug"] == nil)
        #expect(json?["image_config"] == nil)
    }

    // MARK: - Scalar Parameter Encoding

    @Test("maxCompletionTokens encodes as max_completion_tokens")
    func testMaxCompletionTokensEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            maxCompletionTokens: 500
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["max_completion_tokens"] as? Int == 500)
    }

    @Test("logprobs and topLogprobs encoding")
    func testLogprobsEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            logprobs: true,
            topLogprobs: 5
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["logprobs"] as? Bool == true)
        #expect(json?["top_logprobs"] as? Int == 5)
    }

    @Test("parallelToolCalls encodes as parallel_tool_calls")
    func testParallelToolCallsEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            parallelToolCalls: true
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["parallel_tool_calls"] as? Bool == true)
    }

    @Test("modalities encoding")
    func testModalitiesEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            modalities: ["text", "image"]
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["modalities"] as? [String] == ["text", "image"])
    }

    @Test("user encoding")
    func testUserEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            user: "user-12345"
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["user"] as? String == "user-12345")
    }

    @Test("metadata encoding")
    func testMetadataEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            metadata: ["env": "test", "version": "1.0"]
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let metadata = json?["metadata"] as? [String: String]
        #expect(metadata?["env"] == "test")
        #expect(metadata?["version"] == "1.0")
    }

    @Test("sessionId encodes as session_id")
    func testSessionIdEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            sessionId: "sess-abc123"
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["session_id"] as? String == "sess-abc123")
    }

    // MARK: - StreamOptions Encoding

    @Test("StreamOptions encoding")
    func testStreamOptionsEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            streamOptions: StreamOptions(includeUsage: true)
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let streamOptions = json?["stream_options"] as? [String: Any]
        #expect(streamOptions?["include_usage"] as? Bool == true)
    }

    // MARK: - Trace Encoding

    @Test("Trace encoding with all fields")
    func testTraceEncodingAllFields() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            trace: Trace(
                traceId: "trace-001",
                traceName: "my-trace",
                spanName: "chat-span",
                generationName: "gen-1",
                parentSpanId: "parent-001"
            )
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let trace = json?["trace"] as? [String: Any]
        #expect(trace?["trace_id"] as? String == "trace-001")
        #expect(trace?["trace_name"] as? String == "my-trace")
        #expect(trace?["span_name"] as? String == "chat-span")
        #expect(trace?["generation_name"] as? String == "gen-1")
        #expect(trace?["parent_span_id"] as? String == "parent-001")
    }

    @Test("Trace encoding with partial fields")
    func testTraceEncodingPartialFields() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            trace: Trace(traceId: "trace-001")
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let trace = json?["trace"] as? [String: Any]
        #expect(trace?["trace_id"] as? String == "trace-001")
    }

    // MARK: - CacheControl Encoding

    @Test("CacheControl encoding")
    func testCacheControlEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            cacheControl: CacheControl(type: "ephemeral")
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let cacheControl = json?["cache_control"] as? [String: Any]
        #expect(cacheControl?["type"] as? String == "ephemeral")
    }

    // MARK: - DebugOptions Encoding

    @Test("DebugOptions encoding")
    func testDebugOptionsEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            debug: DebugOptions(echoUpstreamBody: true)
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let debug = json?["debug"] as? [String: Any]
        #expect(debug?["echo_upstream_body"] as? Bool == true)
    }

    // MARK: - ImageConfig Encoding

    @Test("ImageConfig encoding with all fields")
    func testImageConfigEncodingAllFields() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            imageConfig: ImageConfig(
                width: 1024,
                height: 768,
                steps: 30,
                guidanceScale: 7.5,
                seed: 42
            )
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let imageConfig = json?["image_config"] as? [String: Any]
        #expect(imageConfig?["width"] as? Int == 1024)
        #expect(imageConfig?["height"] as? Int == 768)
        #expect(imageConfig?["steps"] as? Int == 30)
        #expect(imageConfig?["guidance_scale"] as? Double == 7.5)
        #expect(imageConfig?["seed"] as? Int == 42)
    }

    // MARK: - Supporting Type Round-Trip Decoding

    @Test("StreamOptions round-trip")
    func testStreamOptionsRoundTrip() throws {
        let original = StreamOptions(includeUsage: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StreamOptions.self, from: data)
        #expect(decoded.includeUsage == true)
    }

    @Test("Trace round-trip")
    func testTraceRoundTrip() throws {
        let original = Trace(
            traceId: "t-1",
            traceName: "name",
            spanName: "span",
            generationName: "gen",
            parentSpanId: "parent"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Trace.self, from: data)
        #expect(decoded.traceId == "t-1")
        #expect(decoded.traceName == "name")
        #expect(decoded.spanName == "span")
        #expect(decoded.generationName == "gen")
        #expect(decoded.parentSpanId == "parent")
    }

    @Test("CacheControl round-trip")
    func testCacheControlRoundTrip() throws {
        let original = CacheControl(type: "ephemeral")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CacheControl.self, from: data)
        #expect(decoded.type == "ephemeral")
    }

    @Test("DebugOptions round-trip")
    func testDebugOptionsRoundTrip() throws {
        let original = DebugOptions(echoUpstreamBody: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DebugOptions.self, from: data)
        #expect(decoded.echoUpstreamBody == true)
    }

    @Test("ImageConfig round-trip")
    func testImageConfigRoundTrip() throws {
        let original = ImageConfig(width: 512, height: 512, steps: 20, guidanceScale: 7.0, seed: 99)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ImageConfig.self, from: data)
        #expect(decoded.width == 512)
        #expect(decoded.height == 512)
        #expect(decoded.steps == 20)
        #expect(decoded.seed == 99)
    }

    // MARK: - Full Request with All New Parameters

    @Test("Full request with all new parameters encodes correctly")
    func testFullRequestAllNewParams() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            maxCompletionTokens: 100,
            streamOptions: StreamOptions(includeUsage: true),
            logprobs: true,
            topLogprobs: 3,
            parallelToolCalls: false,
            modalities: ["text"],
            user: "user-xyz",
            metadata: ["key": "value"],
            sessionId: "sess-1",
            trace: Trace(traceId: "t-1"),
            cacheControl: CacheControl(type: "ephemeral"),
            debug: DebugOptions(echoUpstreamBody: true),
            imageConfig: ImageConfig(width: 1024, height: 1024)
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["max_completion_tokens"] as? Int == 100)
        #expect((json?["stream_options"] as? [String: Any])?["include_usage"] as? Bool == true)
        #expect(json?["logprobs"] as? Bool == true)
        #expect(json?["top_logprobs"] as? Int == 3)
        #expect(json?["parallel_tool_calls"] as? Bool == false)
        #expect(json?["modalities"] as? [String] == ["text"])
        #expect(json?["user"] as? String == "user-xyz")
        #expect((json?["metadata"] as? [String: String])?["key"] == "value")
        #expect(json?["session_id"] as? String == "sess-1")
        #expect((json?["trace"] as? [String: Any])?["trace_id"] as? String == "t-1")
        #expect((json?["cache_control"] as? [String: Any])?["type"] as? String == "ephemeral")
        #expect((json?["debug"] as? [String: Any])?["echo_upstream_body"] as? Bool == true)
        #expect((json?["image_config"] as? [String: Any])?["width"] as? Int == 1024)
    }

    // MARK: - Decoding from JSON (simulating API response parsing)

    @Test("ChatRequest decodes new parameters from JSON")
    func testChatRequestDecodingNewParams() throws {
        let jsonString = """
        {
            "model": "test-model",
            "messages": [{"role": "user", "content": "test"}],
            "max_completion_tokens": 200,
            "logprobs": true,
            "top_logprobs": 5,
            "parallel_tool_calls": true,
            "modalities": ["text", "audio"],
            "user": "u-1",
            "metadata": {"source": "test"},
            "session_id": "sess-abc",
            "stream_options": {"include_usage": true},
            "trace": {"trace_id": "t-99", "span_name": "my-span"},
            "cache_control": {"type": "ephemeral"},
            "debug": {"echo_upstream_body": false},
            "image_config": {"width": 256, "height": 256, "steps": 10, "guidance_scale": 5.0}
        }
        """

        let data = jsonString.data(using: .utf8)!
        let request = try JSONDecoder().decode(ChatRequest.self, from: data)

        #expect(request.maxCompletionTokens == 200)
        #expect(request.logprobs == true)
        #expect(request.topLogprobs == 5)
        #expect(request.parallelToolCalls == true)
        #expect(request.modalities == ["text", "audio"])
        #expect(request.user == "u-1")
        #expect(request.metadata?["source"] == "test")
        #expect(request.sessionId == "sess-abc")
        #expect(request.streamOptions?.includeUsage == true)
        #expect(request.trace?.traceId == "t-99")
        #expect(request.trace?.spanName == "my-span")
        #expect(request.cacheControl?.type == "ephemeral")
        #expect(request.debug?.echoUpstreamBody == false)
        #expect(request.imageConfig?.width == 256)
        #expect(request.imageConfig?.height == 256)
        #expect(request.imageConfig?.steps == 10)
    }

    // MARK: - maxTokens and maxCompletionTokens coexistence

    @Test("maxTokens and maxCompletionTokens can coexist")
    func testMaxTokensAndMaxCompletionTokensCoexist() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("test"))],
            model: "test-model",
            maxTokens: 100,
            maxCompletionTokens: 200
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["max_tokens"] as? Int == 100)
        #expect(json?["max_completion_tokens"] as? Int == 200)
    }
}

// MARK: - Integration Tests

@Suite("ChatRequest New Parameters - Integration Tests",
       .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false))
struct ChatRequestParametersIntegrationTests {
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
            siteName: "Swift OpenRouterKit Parameters Tests",
            session: session
        )
    }

    @Test("Request with maxCompletionTokens")
    func testMaxCompletionTokens() async throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("Say hello."))],
            model: "google/gemini-3-flash-preview",
            maxCompletionTokens: 50
        )

        let response = try await client.chat.send(request: request)

        let choice = try #require(response.choices.first)
        #expect(choice.message.content?.isEmpty == false)
        // Verify token usage is within our limit
        if let usage = response.usage {
            #expect(usage.completion_tokens <= 50,
                   "Completion tokens (\(usage.completion_tokens)) should respect maxCompletionTokens limit")
        }
    }

    @Test("Request with user identifier")
    func testUserIdentifier() async throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("Say hi."))],
            model: "google/gemini-3-flash-preview",
            maxCompletionTokens: 20,
            user: "test-user-123"
        )

        let response = try await client.chat.send(request: request)
        let choice = try #require(response.choices.first)
        #expect(choice.message.content?.isEmpty == false)
    }

    @Test("Request with metadata and sessionId")
    func testMetadataAndSessionId() async throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("Say ok."))],
            model: "google/gemini-3-flash-preview",
            maxCompletionTokens: 10,
            metadata: ["env": "test"],
            sessionId: "test-session-001"
        )

        let response = try await client.chat.send(request: request)
        let choice = try #require(response.choices.first)
        #expect(choice.message.content?.isEmpty == false)
    }

    @Test("Streaming with streamOptions includeUsage", .enabled(if: isDarwin))
    func testStreamingWithUsage() async throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("Count to 3."))],
            model: "google/gemini-3-flash-preview",
            stream: true,
            maxCompletionTokens: 50,
            streamOptions: StreamOptions(includeUsage: true)
        )

        var streamedText = ""
        var chunkCount = 0

        let stream = try await client.chat.stream(request: request)
        for try await text in stream {
            streamedText += text
            chunkCount += 1
        }

        #expect(!streamedText.isEmpty, "Should receive streamed text")
        #expect(chunkCount >= 1, "Should receive at least one chunk")
    }

    @Test("Request with parallel_tool_calls")
    func testParallelToolCalls() async throws {
        let weatherTool = Tool(function: FunctionDescription(
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
                Message(role: .user, content: .string("What's the weather in NYC and London? Use the tool for each."))
            ],
            model: "google/gemini-3-flash-preview",
            maxCompletionTokens: 200,
            tools: [weatherTool],
            toolChoice: .required,
            parallelToolCalls: true
        )

        let response = try await client.chat.send(request: request)
        let choice = try #require(response.choices.first)

        // With parallel tool calls and required, we expect tool calls
        if choice.finish_reason == "tool_calls" {
            let toolCalls = try #require(choice.message.toolCalls)
            #expect(toolCalls.count >= 1, "Should have at least one tool call")
            print("Parallel tool calls returned \(toolCalls.count) call(s)")
        }
    }
}
