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
/// text chunks, tool call deltas, and finish signals from a single stream.
///
/// Example:
/// ```swift
/// var accumulator = ToolCallAccumulator()
/// for await event in client.chat.streamEvents(request: request) {
///     switch event {
///     case .text(let text):
///         print(text, terminator: "")
///     case .toolCallDelta(let delta):
///         accumulator.accumulate(delta)
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

    /// An incremental tool call delta. Accumulate these with ``ToolCallAccumulator``
    /// to reassemble complete ``ToolCall`` objects.
    case toolCallDelta(ToolCallDelta)

    /// The stream has finished. Includes the finish reason and optional token usage.
    case finished(finishReason: String?, usage: StreamingDelta.Usage?)
}
