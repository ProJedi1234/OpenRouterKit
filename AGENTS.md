# AGENTS.md

## Cursor Cloud specific instructions

### Overview

OpenRouterKit is a Swift SDK for the OpenRouter API. It has two library targets:

- **OpenRouterKit** — core library, zero external dependencies (Foundation only)
- **OpenRouterKitNIO** — alternative HTTP transport using SwiftNIO for server-side/Linux streaming

### Build, Test, Lint

Standard commands per `README.md` and CI (`.github/workflows/ci.yml`):

```bash
swift build              # build all targets
swift test --parallel    # run all tests (unit tests run offline; integration tests require OPENROUTER_API_KEY)
swiftlint                # lint (uses static binary at /usr/local/bin/swiftlint)
```

### Key caveats

- **Integration tests are gated**: Tests in `OpenRouterClientTests` and `NIOClientTests` that hit the live OpenRouter API are skipped unless the `OPENROUTER_API_KEY` environment variable is set. Unit tests (SSE parsing, tool calls, reasoning, embeddings) always run offline.
- **SwiftLint static binary**: On Linux, use `swiftlint-static` (installed as `swiftlint`) to avoid needing `libsourcekitdInProc.so`. The dynamic `swiftlint` binary requires `LINUX_SOURCEKIT_LIB_PATH` to point at the Swift toolchain's lib directory.
- **`Package.resolved` is not committed**: Dependencies resolve fresh each build. If a transitive dependency (e.g. `swift-nio`) releases a breaking change, builds may fail until the codebase is updated. Delete `.build/` and `Package.resolved` to force a clean re-resolve.
- **C++ headers required**: Building `OpenRouterKitNIO` (via swift-nio-ssl/BoringSSL) requires C++ standard library headers matching the Swift toolchain's bundled clang version. On Ubuntu 24.04 with Swift 6.2, install `libstdc++-14-dev`.
