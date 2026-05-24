# OpenRouterKit

Swift 6.0+
Platforms
License

A Swift SDK for the [OpenRouter](https://openrouter.ai/docs/quickstart) API. Chat completions, audio transcription, embeddings, streaming, tool calling, image and audio inputs, reasoning, model browsing, API key management — all with zero dependencies and native async/await.

## Features

- **Chat Completions** — send messages and get responses, with full parameter control
- **Audio** — transcribe base64 audio and use chat models with audio input/output
- **Embeddings** — generate vectors from text (or multimodal input) and list embedding-capable models
- **Streaming** — real-time token-by-token text streaming and structured event streaming (Apple platforms)
- **Tool Calling** — define tools, handle model-initiated function calls, and send results back
- **Streaming Tool Calls** — reassemble incremental tool call deltas with `ToolCallAccumulator`
- **Image Inputs** — send images via URL or base64 alongside text in multi-part messages
- **Audio Inputs and Outputs** — send `input_audio` content and stream audio deltas
- **Structured Outputs** — request JSON-formatted responses from models
- **Reasoning** — configure reasoning effort levels and track reasoning token usage
- **Model Browsing** — list models, filter by category or capability, check pricing
- **API Key Management** — create, list, update, delete, and inspect API keys
- **Provider Preferences** — route requests to preferred providers
- **Multi-Model Routing** — specify fallback models for automatic failover
- **Error Handling** — every API error maps to a typed Swift error
- **Cross-Platform** — works on iOS, macOS, tvOS, watchOS, and Linux (non-streaming)
- **Zero Dependencies** — pure Swift, nothing else to install

## Install

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ProJedi1234/OpenRouterKit", from: "0.1.0")
]
```

Requires Swift 6.0+, iOS 15+, macOS 12+, tvOS 13+, watchOS 6+.

## Getting Started

Create a client and send a chat completion:

```swift
import OpenRouterKit

let client = OpenRouterClient(
    apiKey: "sk-or-..."
)

let request = ChatRequest(
    messages: [Message(role: .user, content: .string("Tell me a joke"))],
    model: "openai/gpt-4o"
)
let response = try await client.chat.send(request: request)
print(response.choices[0].message.content ?? "")
```

## Audio

Transcribe audio with the dedicated speech-to-text endpoint:

```swift
let audio = InputAudio(data: base64Audio, format: .wav)
let transcript = try await client.audio.createTranscription(
    request: AudioTranscriptionRequest(
        model: "openai/whisper-1",
        inputAudio: audio,
        language: "en"
    )
)
print(transcript.text)
```

Send audio to chat models with `input_audio` content parts:

```swift
let message = Message(
    role: .user,
    content: .contentParts([
        .text(TextContent(text: "Please transcribe this audio.")),
        .inputAudio(InputAudioContentPart(inputAudio: audio))
    ])
)

let response = try await client.chat.send(request: ChatRequest(
    messages: [message],
    model: "openai/gpt-audio"
))
```

Request streamed audio output from capable chat models:

```swift
let request = ChatRequest(
    messages: [Message(role: .user, content: .string("Say hello."))],
    model: "openai/gpt-audio",
    modalities: [.text, .audio],
    audio: ChatAudioConfiguration(voice: "alloy", format: .wav)
)

let events = try await client.chat.streamEvents(request: request)
for try await event in events {
    switch event {
    case .audio(let delta):
        if let data = delta.data {
            print("Audio base64 chunk: \(data)")
        }
        if let transcript = delta.transcript {
            print(transcript, terminator: "")
        }
    default:
        break
    }
}
```

Audio payloads must be base64-encoded raw bytes, not data URIs. Common formats include `.wav`, `.mp3`, `.flac`, `.m4a`, `.ogg`, `.webm`, and `.aac`.

Discover audio-capable models with modality filters:

```swift
let audioInputModels = try await client.models.list(
    filters: ModelsListFilters(inputModalities: [.audio])
)

let transcriptionModels = try await client.models.list(
    filters: ModelsListFilters(outputModalities: [.transcription])
)
```

## Embeddings

Create embeddings and list models that support them ([API reference](https://openrouter.ai/docs/api/reference/embeddings)):

```swift
let response = try await client.embeddings.create(
    request: EmbeddingRequest(
        model: "openai/text-embedding-3-small",
        input: .string("The quick brown fox jumps over the lazy dog")
    )
)

if case .floats(let vector)? = response.data.first?.embedding {
    print("Dimensions: \(vector.count)")
}

// Batch strings in one request
let batch = try await client.embeddings.create(
    request: EmbeddingRequest(
        model: "openai/text-embedding-3-small",
        input: .strings([
            "Machine learning is a subset of artificial intelligence",
            "Natural language processing enables computers to understand text"
        ])
    )
)

// List embedding models
let embeddingModels = try await client.embeddings.listModels()
for model in embeddingModels.data {
    print(model.id)
}
```

Optional fields include `encodingFormat` (`.float` or `.base64`), `dimensions`, `inputType`, `user`, and `provider` routing via `ProviderPreferences` (e.g. `order`, `only`, `sort`, `allowFallbacks`, `dataCollection`). Multimodal input uses the same `ContentPart` text / `image_url` shape as chat messages, wrapped in `EmbeddingMultimodalBlock` and `EmbeddingInput.multimodalBlocks(...)`.

The client also accepts optional `siteURL` and `siteName` parameters that show up in your OpenRouter dashboard, a custom `baseURL` if you need one, and a custom `URLSession` for full control over networking.

## Streaming

Stream responses token-by-token for a typewriter effect in your UI:

```swift
let stream = try await client.chat.stream(request: request)
for try await text in stream {
    print(text, terminator: "")
}
```

For more control, use `streamEvents` to receive structured events including text chunks, tool call deltas, and finish signals:

```swift
let events = try await client.chat.streamEvents(request: request)
for try await event in events {
    switch event {
    case .text(let text):
        print(text, terminator: "")
    case .audio(let audio):
        print(audio.transcript ?? "")
    case .toolCallDelta(let delta):
        // handle incremental tool call data
        break
    case .finished(let reason, let usage):
        print("\nDone: \(reason ?? "unknown")")
    }
}
```

> Streaming uses `URLSession.bytes` and is available on Apple platforms only (iOS 15+, macOS 12+). On Linux, use `send()` for standard request/response.

## Tool Calling

Define tools, let the model call them, and send results back:

```swift
let tool = Tool(function: FunctionDescription(
    name: "get_weather",
    description: "Get the current weather for a location",
    parameters: .object([
        "type": .string("object"),
        "properties": .object([
            "location": .object([
                "type": .string("string"),
                "description": .string("City and state, e.g. San Francisco, CA")
            ])
        ]),
        "required": .array([.string("location")])
    ])
))

let request = ChatRequest(
    messages: [Message(role: .user, content: .string("What's the weather in Portland?"))],
    model: "openai/gpt-4o",
    tools: [tool],
    toolChoice: .auto
)

let response = try await client.chat.send(request: request)

if response.choices[0].finish_reason == "tool_calls",
   let toolCall = response.choices[0].message.toolCalls?.first {
    // Parse toolCall.function.arguments (JSON string), call your function,
    // then send the result back:
    let messages: [Message] = [
        Message(role: .user, content: .string("What's the weather in Portland?")),
        Message(role: .assistant, toolCalls: [toolCall]),
        Message(role: .tool, content: .string("{\"temperature\": 55}"), toolCallId: toolCall.id)
    ]
    let followUp = ChatRequest(messages: messages, model: "openai/gpt-4o")
    let result = try await client.chat.send(request: followUp)
    print(result.choices[0].message.content ?? "")
}
```

Control tool selection with `ToolChoice`:

- `.auto` — model decides whether to call tools (default)
- `.none` — model will not call any tools
- `.required` — model must call at least one tool
- `.function(name: "get_weather")` — model must call a specific function

### Streaming Tool Calls

When streaming, tool calls arrive incrementally across multiple chunks. Use `ToolCallAccumulator` to reassemble them:

```swift
var accumulator = ToolCallAccumulator()

let events = try await client.chat.streamEvents(request: request)
for try await event in events {
    switch event {
    case .text(let text):
        print(text, terminator: "")
    case .toolCallDelta(let delta):
        accumulator.accumulate(delta)
    case .audio:
        break
    case .finished(let reason, _):
        if reason == "tool_calls" {
            let toolCalls = accumulator.toolCalls
            // Process completed tool calls
        }
    }
}
```

## Image Inputs

Send images alongside text using multi-part content:

```swift
let message = Message(
    role: .user,
    content: .contentParts([
        .text(TextContent(text: "What's in this image?")),
        .image(ImageContentPart(imageURL: ImageUrl(
            url: "https://example.com/photo.jpg",
            detail: "auto"
        )))
    ])
)
```

Images can be URLs or base64-encoded data URIs.

## Structured Outputs

Request JSON-formatted responses:

```swift
let request = ChatRequest(
    messages: [Message(role: .user, content: .string("List 3 colors as JSON"))],
    model: "openai/gpt-4o",
    responseFormat: ResponseFormat(type: "json_object")
)
```

## Reasoning

Configure reasoning effort for models that support it, and track reasoning token usage:

```swift
let request = ChatRequest(
    messages: [Message(role: .user, content: .string("Solve this step by step..."))],
    model: "openai/o1",
    reasoning: ReasoningConfiguration(effort: .high)
)

let response = try await client.chat.send(request: request)
if let reasoningTokens = response.usage?.completion_tokens_details?.reasoning_tokens {
    print("Reasoning tokens used: \(reasoningTokens)")
}
```

Effort levels: `.minimal`, `.low`, `.medium`, `.high`.

## Provider Preferences

Control how OpenRouter selects a provider endpoint for your model:

| Field | Use when |
| --- | --- |
| `order` | You want providers tried in a **fixed priority sequence** (first choice, then fallbacks). |
| `only` | You want an **allowlist** of provider slugs (unordered); OpenRouter picks among them. |
| `sort` | You want providers ranked by `price`, `throughput`, or `latency` (disables default load balancing). |
| `allowFallbacks` | Set to `false` to restrict routing to your `order` / `only` list only. |

**Priority order** (try Azure, then OpenAI, with fallbacks):

```swift
let request = ChatRequest(
    messages: [Message(role: .user, content: .string("Hello"))],
    model: "openai/gpt-4o",
    provider: ProviderPreferences(order: ["azure", "openai"])
)
```

**Allowlist + sort by throughput** (only DeepInfra or Together, prefer highest throughput):

```swift
let request = ChatRequest(
    messages: [Message(role: .user, content: .string("Hello"))],
    model: "meta-llama/llama-3.3-70b-instruct",
    provider: ProviderPreferences(
        only: ["deepinfra", "together"],
        sort: .throughput,
        allowFallbacks: false
    )
)
```

**Strict allowlist** (Azure only, no other providers):

```swift
provider: ProviderPreferences(only: ["azure"], allowFallbacks: false)
```

Advanced `sort` with `partition: .none` sorts endpoints globally across model fallbacks (see [OpenRouter provider routing](https://openrouter.ai/docs/guides/routing/provider-selection)). Model slug shortcuts `:nitro` (throughput) and `:floor` (price) are equivalent to setting `sort` without using `ProviderPreferences`.

## Multi-Model Routing

Specify fallback models so the request automatically tries alternatives:

```swift
let request = ChatRequest(
    messages: [Message(role: .user, content: .string("Hello"))],
    models: ["openai/gpt-4o", "anthropic/claude-sonnet-4", "google/gemini-2.0-flash"],
    route: "fallback"
)
```

## Models

Browse available models, check pricing, and filter by capabilities:

```swift
// List all models
let allModels = try await client.models.list(filters: ModelsListFilters())

for model in allModels.data {
    print("\(model.name) — \(model.pricing.prompt) per token")
}

// List STT models
let sttModels = try await client.models.list(
    filters: ModelsListFilters(outputModalities: [.transcription])
)

// List models available to the current user
let myModels = try await client.models.listForUser()
```

Embedding-specific discovery uses `client.embeddings.listModels()` (see [Embeddings](#embeddings)).

## API Key Management

Full CRUD for API keys — useful if you're building something that manages multiple keys:

```swift
// List keys
let keys = try await client.keys.list(includeDisabled: false, offset: nil)

// Create a key with a spending limit
let newKey = try await client.keys.create(request: CreateAPIKeyRequest(
    name: "Production Key",
    limit: 100.0,
    limitReset: .monthly
))
print(newKey.key) // Only shown once!

// Check current key info
let current = try await client.keys.getCurrent()

// Update a key
_ = try await client.keys.update(hash: "key-hash", request: UpdateAPIKeyRequest(
    name: "Renamed Key",
    disabled: false
))

// Delete a key
_ = try await client.keys.delete(hash: "key-hash")
```

## Error Handling

Every API error maps to a specific Swift type:

```swift
do {
    let response = try await client.chat.send(request: request)
} catch let error as OpenRouterError {
    switch error.type {
    case .badRequest:
        // malformed request (400)
    case .invalidCredentials:
        // check your API key (401)
    case .insufficientCredits:
        // add credits at openrouter.ai (402)
    case .moderationError:
        // content flagged (403)
    case .requestTimeout:
        // request timed out (408)
    case .rateLimited:
        // back off and retry (429)
    case .modelDown:
        // try a different model (502)
    case .noAvailableProvider:
        // model might be overloaded (503)
    case .streamingUnavailable:
        // streaming not supported on this platform; use OpenRouterKitNIO
    case .unknownError(let code):
        print("Unexpected error (\(code)): \(error.message)")
    }
}
```

## Migration Notes

### Custom Protocol Conformers

If you conform to client protocols yourself (tests, mocks, or alternate implementations), update stubs for these requirements:

- **`OpenRouterClientProtocol`** now requires `var audio: AudioServiceProtocol { get }`.
- **`ModelsServiceProtocol`** now requires `func list(filters: ModelsListFilters) async throws -> ModelsListResponse`.

The older parameter-based `list(category:supportedParameters:inputModalities:outputModalities:useRSS:useRSSChatLinks:)` overload is deprecated. Prefer `ModelsListFilters` and the single `list(filters:)` entry point—for example, filtering by input modality:

```swift
let response = try await client.models.list(
    filters: ModelsListFilters(inputModalities: [.audio])
)
```

Apps using the built-in `OpenRouterClient` do not need a migration; only custom protocol conformers must add or forward the new members.

## Links

- [OpenRouter API Docs](https://openrouter.ai/docs/quickstart)
- [Model List](https://openrouter.ai/models)

## License

MIT — see [LICENSE](LICENSE) for the full text.