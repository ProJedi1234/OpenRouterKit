//
//  SSEParser.swift
//  OpenRouterKit
//
//  Shared SSE (Server-Sent Events) parsing logic used by both
//  URLSessionHTTPClient and NIOHTTPClient.
//

import Foundation

/// Parses Server-Sent Events (SSE) lines from the OpenRouter streaming API.
package enum SSEParser {
    /// Extracts text content from a single SSE data line.
    ///
    /// - Parameter line: A raw SSE line (e.g., `data: {"id":...}\n`)
    /// - Returns: The text content from the delta, or nil if the line
    ///   is empty, not a data line, is `[DONE]`, or has no text content.
    package static func processLine(_ line: String) -> String? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty, trimmedLine.hasPrefix("data: ") else { return nil }

        let jsonString = String(trimmedLine.dropFirst(6))
        guard jsonString != "[DONE]",
              let jsonData = jsonString.data(using: .utf8),
              let delta = try? JSONDecoder().decode(StreamingDelta.self, from: jsonData),
              let content = delta.choices.first?.delta.content,
              !content.isEmpty else { return nil }

        return content
    }

    /// Parses a single SSE data line into structured chat stream events.
    ///
    /// A single line may produce multiple events (e.g., text + tool call delta + finish).
    ///
    /// - Parameter line: A raw SSE line
    /// - Returns: An array of ``ChatStreamEvent`` values parsed from the line.
    package static func processLineAsEvents(_ line: String) -> [ChatStreamEvent] {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty, trimmedLine.hasPrefix("data: ") else { return [] }

        let jsonString = String(trimmedLine.dropFirst(6))
        guard jsonString != "[DONE]",
              let jsonData = jsonString.data(using: .utf8),
              let delta = try? JSONDecoder().decode(StreamingDelta.self, from: jsonData),
              let choice = delta.choices.first else { return [] }

        var events: [ChatStreamEvent] = []

        if let content = choice.delta.content, !content.isEmpty {
            events.append(.text(content))
        }

        if let toolCallDeltas = choice.delta.toolCalls {
            for toolCallDelta in toolCallDeltas {
                events.append(.toolCallDelta(toolCallDelta))
            }
        }

        if let finishReason = choice.finish_reason {
            events.append(.finished(finishReason: finishReason, usage: delta.usage))
        }

        return events
    }
}
