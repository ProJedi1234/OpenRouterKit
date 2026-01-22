# OpenRouterKit

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

[OpenRouter](https://openrouter.ai/docs/quickstart) lets you talk to 200+ language models through one API. This is an unofficial Swift SDK that makes working with it easy! Chat completions, real-time streaming, model browsing, the works. No dependencies to manage, just async/await the way you'd expect.

## Install

Drop it into your project with Swift Package Manager. No other dependencies to worry about!

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ProJedi1234/OpenRouterKit", from: "0.1.0")
]
```

Requires Swift 6.0+, iOS 15+, macOS 12+, tvOS 13+, watchOS 6+.

## Getting Started

Here's the fun part! Create a client, throw a message at a model, and get a response back. The whole thing is async/await so it fits right into your existing Swift code. You can also stream responses if you want that nice typewriter effect in your UI.

```swift
import OpenRouterKit

// Create a client with your API key
// siteURL and siteName are optional but show up in your OpenRouter dashboard
let client = OpenRouterClient(
    apiKey: "sk-or-...",
    siteURL: "https://myapp.com",
    siteName: "My App"
)

// Send a chat completion with provider preferences
let request = ChatRequest(
    messages: [Message(role: .user, content: .string("Tell me a joke"))],
    model: "openai/gpt-oss-120b",
    provider: ProviderPreferences(order: [
        "cerebras",
        "groq",
        "google-vertex",
        "amazon-bedrock"
    ])
)
let response = try await client.chat.send(request: request)
print(response.choices[0].message.content)

// Or stream the response token by token (Apple platforms only)
let stream = client.chat.stream(request: request)
for await text in stream {
    print(text, terminator: "")
}
```

## What's Included

You're not just getting chat completions here! The SDK covers pretty much everything the OpenRouter API offers. Here's what you can do:

**Chat** (`client.chat`) - Send chat completions and stream responses. Supports all the usual parameters like temperature, max tokens, and tool calling.

**Models** (`client.models`) - Browse available models, check pricing, see what parameters each model supports. Great for building model pickers or checking capabilities at runtime.

**Keys** (`client.keys`) - Full CRUD for API keys if you're building something that manages multiple keys. Create, list, update, delete, check usage.

## Error Handling

Every API error maps to a specific Swift type. Rate limited? That's `.rateLimited`. Auth failed? `.invalidCredentials`. Model's having a bad day? `.modelDown`. You get the idea. No digging through generic error messages to figure out what went wrong!

```swift
do {
    let response = try await client.chat.send(request: request)
} catch let error as OpenRouterError {
    switch error.type {
    case .invalidCredentials:
        // check your API key
    case .insufficientCredits:
        // add credits at openrouter.ai
    case .rateLimited:
        // back off and retry
    case .modelDown:
        // try a different model
    case .noAvailableProvider:
        // model might be overloaded
    default:
        print(error.message)
    }
}
```

## A Note on Linux

Streaming uses `URLSession.bytes()` which isn't available on Linux. If you call `stream()` there, it'll crash with a helpful error message pointing you to `send()` instead. Regular request/response works fine everywhere!

## Links

- [OpenRouter API Docs](https://openrouter.ai/docs/quickstart)
- [Model List](https://openrouter.ai/models)

## License

MIT - do whatever you want with it, just keep the copyright notice. See [LICENSE](LICENSE) for the full text.
