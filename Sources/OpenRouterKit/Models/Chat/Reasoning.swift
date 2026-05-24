//
//  Reasoning.swift
//  OpenRouterKit
//
//  Reasoning configuration types for advanced reasoning capabilities.
//

import Foundation

/// Represents reasoning configuration for advanced reasoning capabilities.
public struct ReasoningConfiguration: Codable, Sendable, Equatable {
    /// The effort level for reasoning.
    public var effort: ReasoningEffort

    /// Creates a new reasoning configuration.
    ///
    /// - Parameter effort: The reasoning effort level
    public init(effort: ReasoningEffort) {
        self.effort = effort
    }
}

/// Represents the effort level for reasoning.
///
/// Supported by OpenAI reasoning models (o1, o3, GPT-5 series) and Grok models.
/// OpenRouter maps effort to a portion of `max_tokens` for reasoning (e.g. ~95% for `xhigh`, ~10% for `minimal`).
public enum ReasoningEffort: String, Codable, Sendable, Equatable {
    /// Largest reasoning budget (~95% of max_tokens).
    case xhigh
    /// Large reasoning budget (~80% of max_tokens).
    case high
    /// Moderate reasoning budget (~50% of max_tokens).
    case medium
    /// Smaller reasoning budget (~20% of max_tokens).
    case low
    /// Minimal reasoning budget (~10% of max_tokens).
    case minimal
    /// Disables reasoning entirely.
    case none
}
