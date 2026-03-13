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

/// Request body for bulk assigning or unassigning keys to/from a guardrail.
public struct GuardrailAssignKeysRequest: Codable, Sendable {
    /// List of API key hashes to assign or unassign.
    public let keyHashes: [String]

    enum CodingKeys: String, CodingKey {
        case keyHashes = "key_hashes"
    }

    public init(keyHashes: [String]) {
        self.keyHashes = keyHashes
    }
}

/// Request body for bulk assigning or unassigning members to/from a guardrail.
public struct GuardrailAssignMembersRequest: Codable, Sendable {
    /// List of member user IDs to assign or unassign.
    public let memberUserIds: [String]

    enum CodingKeys: String, CodingKey {
        case memberUserIds = "member_user_ids"
    }

    public init(memberUserIds: [String]) {
        self.memberUserIds = memberUserIds
    }
}

// MARK: - Assignment Models

/// Represents a key assignment to a guardrail.
public struct GuardrailKeyAssignment: Codable, Sendable {
    /// Unique identifier for the assignment.
    public let id: String

    /// The API key hash.
    public let keyHash: String

    /// The guardrail ID.
    public let guardrailId: String

    /// Name of the assigned key.
    public let keyName: String?

    /// Label of the assigned key.
    public let keyLabel: String?

    /// User ID of who created the assignment.
    public let assignedBy: String?

    /// ISO 8601 timestamp of when the assignment was created.
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case keyHash = "key_hash"
        case guardrailId = "guardrail_id"
        case keyName = "key_name"
        case keyLabel = "key_label"
        case assignedBy = "assigned_by"
        case createdAt = "created_at"
    }
}

/// Represents a member assignment to a guardrail.
public struct GuardrailMemberAssignment: Codable, Sendable {
    /// Unique identifier for the assignment.
    public let id: String

    /// The member user ID.
    public let userId: String

    /// The organization ID.
    public let organizationId: String?

    /// The guardrail ID.
    public let guardrailId: String

    /// User ID of who created the assignment.
    public let assignedBy: String?

    /// ISO 8601 timestamp of when the assignment was created.
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case organizationId = "organization_id"
        case guardrailId = "guardrail_id"
        case assignedBy = "assigned_by"
        case createdAt = "created_at"
    }
}

// MARK: - Response Models

/// Response wrapper for listing guardrails.
public struct GuardrailListResponse: Codable, Sendable {
    /// List of guardrails.
    public let data: [Guardrail]

    /// Total number of guardrails.
    public let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case totalCount = "total_count"
    }
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

    /// Total number of key assignments.
    public let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case totalCount = "total_count"
    }
}

/// Response wrapper for listing member assignments.
public struct GuardrailMemberAssignmentListResponse: Codable, Sendable {
    /// List of member assignments.
    public let data: [GuardrailMemberAssignment]

    /// Total number of member assignments.
    public let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case totalCount = "total_count"
    }
}

/// Response wrapper for bulk key assignment operations.
public struct GuardrailAssignKeysResponse: Codable, Sendable {
    /// Number of keys assigned.
    public let assignedCount: Int?

    /// Number of keys unassigned.
    public let unassignedCount: Int?

    enum CodingKeys: String, CodingKey {
        case assignedCount = "assigned_count"
        case unassignedCount = "unassigned_count"
    }
}

/// Response wrapper for bulk member assignment operations.
public struct GuardrailAssignMembersResponse: Codable, Sendable {
    /// Number of members assigned.
    public let assignedCount: Int?

    /// Number of members unassigned.
    public let unassignedCount: Int?

    enum CodingKeys: String, CodingKey {
        case assignedCount = "assigned_count"
        case unassignedCount = "unassigned_count"
    }
}
