//
//  Reasoning.swift
//  OpenRouterKit
//
//  Reasoning configuration types for advanced reasoning capabilities.
//

import Foundation

/// Represents reasoning configuration for advanced reasoning capabilities.
public struct ReasoningConfiguration: Codable, Sendable {
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
public enum ReasoningEffort: String, Codable, Sendable {
    /// Basic reasoning with minimal computational effort.
    case minimal
    /// Light reasoning for simple problems.
    case low
    /// Balanced reasoning for moderate complexity.
    case medium
    /// Deep reasoning for complex problems.
    case high
}
