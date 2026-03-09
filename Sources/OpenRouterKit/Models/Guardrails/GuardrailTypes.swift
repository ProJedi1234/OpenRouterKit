//
//  GuardrailTypes.swift
//  OpenRouterKit
//

import Foundation

// MARK: - Enums

/// Reset interval for a guardrail spending limit.
public enum GuardrailResetInterval: String, Codable, Sendable {
    case daily
    case weekly
    case monthly
}

// MARK: - Core Models

/// Represents a guardrail with all its properties.
public struct Guardrail: Codable, Sendable {
    /// Unique identifier for the guardrail.
    public let id: String

    /// Name of the guardrail.
    public let name: String

    /// Description of the guardrail.
    public let description: String?

    /// Spending limit in USD.
    public let limitUsd: Double?

    /// How often the spending limit resets.
    public let resetInterval: GuardrailResetInterval?

    /// List of allowed provider identifiers.
    public let allowedProviders: [String]?

    /// List of ignored provider identifiers.
    public let ignoredProviders: [String]?

    /// List of allowed model identifiers.
    public let allowedModels: [String]?

    /// Whether to enforce zero data retention.
    public let enforceZdr: Bool?

    /// ISO 8601 timestamp of when the guardrail was created.
    public let createdAt: String?

    /// ISO 8601 timestamp of when the guardrail was last updated.
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case limitUsd = "limit_usd"
        case resetInterval = "reset_interval"
        case allowedProviders = "allowed_providers"
        case ignoredProviders = "ignored_providers"
        case allowedModels = "allowed_models"
        case enforceZdr = "enforce_zdr"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Request Models

/// Request body for creating a guardrail.
public struct CreateGuardrailRequest: Codable, Sendable {
    /// Name for the guardrail (required).
    public let name: String

    /// Description of the guardrail.
    public let description: String?

    /// Spending limit in USD.
    public let limitUsd: Double?

    /// How often the spending limit resets.
    public let resetInterval: GuardrailResetInterval?

    /// List of allowed provider identifiers.
    public let allowedProviders: [String]?

    /// List of ignored provider identifiers.
    public let ignoredProviders: [String]?

    /// List of allowed model identifiers.
    public let allowedModels: [String]?

    /// Whether to enforce zero data retention.
    public let enforceZdr: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case limitUsd = "limit_usd"
        case resetInterval = "reset_interval"
        case allowedProviders = "allowed_providers"
        case ignoredProviders = "ignored_providers"
        case allowedModels = "allowed_models"
        case enforceZdr = "enforce_zdr"
    }

    public init(
        name: String,
        description: String? = nil,
        limitUsd: Double? = nil,
        resetInterval: GuardrailResetInterval? = nil,
        allowedProviders: [String]? = nil,
        ignoredProviders: [String]? = nil,
        allowedModels: [String]? = nil,
        enforceZdr: Bool? = nil
    ) {
        self.name = name
        self.description = description
        self.limitUsd = limitUsd
        self.resetInterval = resetInterval
        self.allowedProviders = allowedProviders
        self.ignoredProviders = ignoredProviders
        self.allowedModels = allowedModels
        self.enforceZdr = enforceZdr
    }
}

/// Request body for updating a guardrail.
public struct UpdateGuardrailRequest: Codable, Sendable {
    /// New name for the guardrail.
    public let name: String?

    /// New description.
    public let description: String?

    /// New spending limit in USD.
    public let limitUsd: Double?

    /// New reset interval.
    public let resetInterval: GuardrailResetInterval?

    /// New list of allowed provider identifiers.
    public let allowedProviders: [String]?

    /// New list of ignored provider identifiers.
    public let ignoredProviders: [String]?

    /// New list of allowed model identifiers.
    public let allowedModels: [String]?

    /// Whether to enforce zero data retention.
    public let enforceZdr: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case limitUsd = "limit_usd"
        case resetInterval = "reset_interval"
        case allowedProviders = "allowed_providers"
        case ignoredProviders = "ignored_providers"
        case allowedModels = "allowed_models"
        case enforceZdr = "enforce_zdr"
    }

    public init(
        name: String? = nil,
        description: String? = nil,
        limitUsd: Double? = nil,
        resetInterval: GuardrailResetInterval? = nil,
        allowedProviders: [String]? = nil,
        ignoredProviders: [String]? = nil,
        allowedModels: [String]? = nil,
        enforceZdr: Bool? = nil
    ) {
        self.name = name
        self.description = description
        self.limitUsd = limitUsd
        self.resetInterval = resetInterval
        self.allowedProviders = allowedProviders
        self.ignoredProviders = ignoredProviders
        self.allowedModels = allowedModels
        self.enforceZdr = enforceZdr
    }
}

/// Request body for bulk assigning keys to a guardrail.
public struct GuardrailAssignKeysRequest: Codable, Sendable {
    /// List of API key hashes to assign.
    public let keyHashes: [String]

    enum CodingKeys: String, CodingKey {
        case keyHashes = "key_hashes"
    }

    public init(keyHashes: [String]) {
        self.keyHashes = keyHashes
    }
}

/// Request body for bulk assigning members to a guardrail.
public struct GuardrailAssignMembersRequest: Codable, Sendable {
    /// List of member user IDs to assign.
    public let userIds: [String]

    enum CodingKeys: String, CodingKey {
        case userIds = "user_ids"
    }

    public init(userIds: [String]) {
        self.userIds = userIds
    }
}

// MARK: - Assignment Models

/// Represents a key assignment to a guardrail.
public struct GuardrailKeyAssignment: Codable, Sendable {
    /// The guardrail ID.
    public let guardrailId: String

    /// The API key hash.
    public let keyHash: String

    enum CodingKeys: String, CodingKey {
        case guardrailId = "guardrail_id"
        case keyHash = "key_hash"
    }
}

/// Represents a member assignment to a guardrail.
public struct GuardrailMemberAssignment: Codable, Sendable {
    /// The guardrail ID.
    public let guardrailId: String

    /// The member user ID.
    public let userId: String

    enum CodingKeys: String, CodingKey {
        case guardrailId = "guardrail_id"
        case userId = "user_id"
    }
}

// MARK: - Response Models

/// Response wrapper for listing guardrails.
public struct GuardrailListResponse: Codable, Sendable {
    /// List of guardrails.
    public let data: [Guardrail]
}

/// Response wrapper for a single guardrail.
public struct GuardrailResponse: Codable, Sendable {
    /// The guardrail.
    public let data: Guardrail
}

/// Response wrapper for deleting a guardrail.
public struct DeleteGuardrailResponse: Codable, Sendable {
    /// Whether the guardrail was deleted.
    public let deleted: Bool
}

/// Response wrapper for listing key assignments.
public struct GuardrailKeyAssignmentListResponse: Codable, Sendable {
    /// List of key assignments.
    public let data: [GuardrailKeyAssignment]
}

/// Response wrapper for listing member assignments.
public struct GuardrailMemberAssignmentListResponse: Codable, Sendable {
    /// List of member assignments.
    public let data: [GuardrailMemberAssignment]
}

/// Response wrapper for bulk key assignment operations.
public struct GuardrailAssignKeysResponse: Codable, Sendable {
    /// List of key assignments after the operation.
    public let data: [GuardrailKeyAssignment]
}

/// Response wrapper for bulk member assignment operations.
public struct GuardrailAssignMembersResponse: Codable, Sendable {
    /// List of member assignments after the operation.
    public let data: [GuardrailMemberAssignment]
}
