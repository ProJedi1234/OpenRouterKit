//
//  ToolCallAccumulator.swift
//  OpenRouterKit
//
//  Reassembles streaming tool call deltas into complete ToolCall objects.
//

import Foundation

/// Reassembles fragmented ``ToolCallDelta`` values into complete ``ToolCall`` objects.
///
/// During streaming, tool calls arrive incrementally across multiple SSE chunks.
/// Feed each delta into ``accumulate(_:)`` and read the assembled results from ``toolCalls``.
///
/// ```swift
/// var accumulator = ToolCallAccumulator()
/// for await event in stream {
///     if case .toolCallDelta(let delta) = event {
///         accumulator.accumulate(delta)
///     }
/// }
/// let completedCalls = accumulator.toolCalls
/// ```
public struct ToolCallAccumulator: Sendable {
    private struct InProgressToolCall: Sendable {
        var id: String
        var type: String
        var functionName: String
        var arguments: String
    }

    private var inProgress: [Int: InProgressToolCall] = [:]

    /// Creates a new, empty accumulator.
    public init() {}

    /// Incorporates a tool call delta into the accumulator.
    ///
    /// - Parameter delta: The incremental tool call data from a streaming chunk.
    public mutating func accumulate(_ delta: ToolCallDelta) {
        if var existing = inProgress[delta.index] {
            if let id = delta.id {
                existing.id = id
            }
            if let type = delta.type {
                existing.type = type
            }
            if let name = delta.function?.name {
                existing.functionName = name
            }
            if let args = delta.function?.arguments {
                existing.arguments += args
            }
            inProgress[delta.index] = existing
        } else {
            inProgress[delta.index] = InProgressToolCall(
                id: delta.id ?? "",
                type: delta.type ?? "function",
                functionName: delta.function?.name ?? "",
                arguments: delta.function?.arguments ?? ""
            )
        }
    }

    /// The assembled tool calls, sorted by their streaming index.
    ///
    /// Returns all tool calls accumulated so far, even if the stream has not finished.
    public var toolCalls: [ToolCall] {
        inProgress.keys.sorted().compactMap { index in
            guard let entry = inProgress[index], !entry.id.isEmpty else { return nil }
            return ToolCall(
                id: entry.id,
                type: entry.type,
                function: ToolCallFunction(
                    name: entry.functionName,
                    arguments: entry.arguments
                )
            )
        }
    }

    /// Resets the accumulator, discarding all in-progress tool calls.
    public mutating func reset() {
        inProgress.removeAll()
    }
}
