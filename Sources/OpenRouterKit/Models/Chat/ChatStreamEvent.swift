//
//  ChatStreamEvent.swift
//  OpenRouterKit
//
//  Events emitted during streaming chat completions.
//

import Foundation

/// An event emitted during a streaming chat completion.
///
/// Use with `ChatServiceProtocol.streamEvents(request:)` to receive
/// text chunks, audio deltas, tool call deltas, and finish signals from a single stream.
///
/// Example:
/// ```swift
/// var accumulator = ToolCallAccumulator()
/// var citations: [Annotation] = []
/// for try await event in try await client.chat.streamEvents(request: request) {
///     switch event {
///     case .text(let text):
///         print(text, terminator: "")
///     case .audio(let audio):
///         print(audio.transcript ?? "", terminator: "")
///     case .toolCallDelta(let delta):
///         accumulator.accumulate(delta)
///     case .annotations(let annotations):
///         citations.append(contentsOf: annotations)
///     case .finished(let reason, let usage):
///         if reason == "tool_calls" {
///             let toolCalls = accumulator.toolCalls
///         }
///     }
/// }
/// ```
public enum ChatStreamEvent: Sendable {
    /// A chunk of text content from the model.
    case text(String)

    /// A chunk of generated audio and/or transcript text from the model.
    case audio(AudioDelta)

    /// An incremental tool call delta. Accumulate these with ``ToolCallAccumulator``
    /// to reassemble complete ``ToolCall`` objects.
    case toolCallDelta(ToolCallDelta)

    /// Annotations on the assistant message, such as web search citations from server tools.
    /// A stream may emit several of these; each carries only the annotations in its chunk.
    case annotations([Annotation])

    /// The stream has finished. Includes the finish reason and optional token usage.
    case finished(finishReason: String?, usage: StreamingDelta.Usage?)
}
