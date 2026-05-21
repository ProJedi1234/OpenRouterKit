//
//  GuardrailTypes.swift
//  OpenRouterKit
//
//  Request and response types for the OpenRouter guardrails API.
//

import Foundation

// MARK: - Enums

/// Reset interval for a guardrail spending limit.
public enum GuardrailInterval: String, Codable, Sendable {
    case daily
    case weekly
    case monthly
}

/// Action taken when a builtin content filter triggers.
public enum ContentFilterBuiltinAction: String, Codable, Sendable {
    case redact
    case block
    case flag
}

/// Builtin content filter identifier.
public enum ContentFilterBuiltinSlug: String, Codable, Sendable {
    case email
    case phone
    case ssn
    case creditCard = "credit-card"
    case ipAddress = "ip-address"
    case personName = "person-name"
    case address
    case regexPromptInjection = "regex-prompt-injection"
}

/// Action taken when a custom content filter pattern matches.
public enum ContentFilterAction: String, Codable, Sendable {
    case redact
    case block
}

// MARK: - Filters

/// Query filters for listing guardrails.
public struct GuardrailListFilters: Sendable {
    /// Pagination offset.
    public var offset: String?

    /// Maximum number of records to return (max 100).
    public var limit: Int?

    /// Workspace ID to filter by.
    public var workspaceId: String?

    public init(offset: String? = nil, limit: Int? = nil, workspaceId: String? = nil) {
        self.offset = offset
        self.limit = limit
        self.workspaceId = workspaceId
    }
}

// MARK: - Content Filters

/// A builtin content filter entry.
public struct ContentFilterBuiltinEntry: Codable, Sendable, Equatable {
    public var action: ContentFilterBuiltinAction
    public var slug: ContentFilterBuiltinSlug
    public var label: String?

    enum CodingKeys: String, CodingKey {
        case action
        case slug
        case label
    }

    public init(
        action: ContentFilterBuiltinAction,
        slug: ContentFilterBuiltinSlug,
        label: String? = nil
    ) {
        self.action = action
        self.slug = slug
        self.label = label
    }
}

/// A custom regex content filter entry.
public struct ContentFilterEntry: Codable, Sendable, Equatable {
    public var action: ContentFilterAction
    public var pattern: String
    public var label: String?

    public init(action: ContentFilterAction, pattern: String, label: String? = nil) {
        self.action = action
        self.pattern = pattern
        self.label = label
    }
}

// MARK: - Core Models

/// Represents a guardrail with all its properties.
public struct Guardrail: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let limitUsd: Double?
    public let resetInterval: GuardrailInterval?
    public let allowedProviders: [String]?
    public let ignoredProviders: [String]?
    public let allowedModels: [String]?
    public let ignoredModels: [String]?
    public let contentFilterBuiltins: [ContentFilterBuiltinEntry]?
    public let contentFilters: [ContentFilterEntry]?
    public let enforceZdr: Bool?
    public let enforceZdrAnthropic: Bool?
    public let enforceZdrOpenai: Bool?
    public let enforceZdrGoogle: Bool?
    public let enforceZdrOther: Bool?
    public let workspaceId: String?
    public let createdAt: String?
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
        case ignoredModels = "ignored_models"
        case contentFilterBuiltins = "content_filter_builtins"
        case contentFilters = "content_filters"
        case enforceZdr = "enforce_zdr"
        case enforceZdrAnthropic = "enforce_zdr_anthropic"
        case enforceZdrOpenai = "enforce_zdr_openai"
        case enforceZdrGoogle = "enforce_zdr_google"
        case enforceZdrOther = "enforce_zdr_other"
        case workspaceId = "workspace_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Request Models

/// Request body for creating a guardrail.
public struct CreateGuardrailRequest: Codable, Sendable {
    public let name: String
    public let description: String?
    public let limitUsd: Double?
    public let resetInterval: GuardrailInterval?
    public let allowedProviders: [String]?
    public let ignoredProviders: [String]?
    public let allowedModels: [String]?
    public let ignoredModels: [String]?
    public let contentFilterBuiltins: [ContentFilterBuiltinEntry]?
    public let contentFilters: [ContentFilterEntry]?
    public let enforceZdr: Bool?
    public let enforceZdrAnthropic: Bool?
    public let enforceZdrOpenai: Bool?
    public let enforceZdrGoogle: Bool?
    public let enforceZdrOther: Bool?
    public let workspaceId: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case limitUsd = "limit_usd"
        case resetInterval = "reset_interval"
        case allowedProviders = "allowed_providers"
        case ignoredProviders = "ignored_providers"
        case allowedModels = "allowed_models"
        case ignoredModels = "ignored_models"
        case contentFilterBuiltins = "content_filter_builtins"
        case contentFilters = "content_filters"
        case enforceZdr = "enforce_zdr"
        case enforceZdrAnthropic = "enforce_zdr_anthropic"
        case enforceZdrOpenai = "enforce_zdr_openai"
        case enforceZdrGoogle = "enforce_zdr_google"
        case enforceZdrOther = "enforce_zdr_other"
        case workspaceId = "workspace_id"
    }

    public init(
        name: String,
        description: String? = nil,
        limitUsd: Double? = nil,
        resetInterval: GuardrailInterval? = nil,
        allowedProviders: [String]? = nil,
        ignoredProviders: [String]? = nil,
        allowedModels: [String]? = nil,
        ignoredModels: [String]? = nil,
        contentFilterBuiltins: [ContentFilterBuiltinEntry]? = nil,
        contentFilters: [ContentFilterEntry]? = nil,
        enforceZdr: Bool? = nil,
        enforceZdrAnthropic: Bool? = nil,
        enforceZdrOpenai: Bool? = nil,
        enforceZdrGoogle: Bool? = nil,
        enforceZdrOther: Bool? = nil,
        workspaceId: String? = nil
    ) {
        self.name = name
        self.description = description
        self.limitUsd = limitUsd
        self.resetInterval = resetInterval
        self.allowedProviders = allowedProviders
        self.ignoredProviders = ignoredProviders
        self.allowedModels = allowedModels
        self.ignoredModels = ignoredModels
        self.contentFilterBuiltins = contentFilterBuiltins
        self.contentFilters = contentFilters
        self.enforceZdr = enforceZdr
        self.enforceZdrAnthropic = enforceZdrAnthropic
        self.enforceZdrOpenai = enforceZdrOpenai
        self.enforceZdrGoogle = enforceZdrGoogle
        self.enforceZdrOther = enforceZdrOther
        self.workspaceId = workspaceId
    }
}

/// Request body for updating a guardrail.
public struct UpdateGuardrailRequest: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let limitUsd: Double?
    public let resetInterval: GuardrailInterval?
    public let allowedProviders: [String]?
    public let ignoredProviders: [String]?
    public let allowedModels: [String]?
    public let ignoredModels: [String]?
    public let contentFilterBuiltins: [ContentFilterBuiltinEntry]?
    public let contentFilters: [ContentFilterEntry]?
    public let enforceZdr: Bool?
    public let enforceZdrAnthropic: Bool?
    public let enforceZdrOpenai: Bool?
    public let enforceZdrGoogle: Bool?
    public let enforceZdrOther: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case limitUsd = "limit_usd"
        case resetInterval = "reset_interval"
        case allowedProviders = "allowed_providers"
        case ignoredProviders = "ignored_providers"
        case allowedModels = "allowed_models"
        case ignoredModels = "ignored_models"
        case contentFilterBuiltins = "content_filter_builtins"
        case contentFilters = "content_filters"
        case enforceZdr = "enforce_zdr"
        case enforceZdrAnthropic = "enforce_zdr_anthropic"
        case enforceZdrOpenai = "enforce_zdr_openai"
        case enforceZdrGoogle = "enforce_zdr_google"
        case enforceZdrOther = "enforce_zdr_other"
    }

    public init(
        name: String? = nil,
        description: String? = nil,
        limitUsd: Double? = nil,
        resetInterval: GuardrailInterval? = nil,
        allowedProviders: [String]? = nil,
        ignoredProviders: [String]? = nil,
        allowedModels: [String]? = nil,
        ignoredModels: [String]? = nil,
        contentFilterBuiltins: [ContentFilterBuiltinEntry]? = nil,
        contentFilters: [ContentFilterEntry]? = nil,
        enforceZdr: Bool? = nil,
        enforceZdrAnthropic: Bool? = nil,
        enforceZdrOpenai: Bool? = nil,
        enforceZdrGoogle: Bool? = nil,
        enforceZdrOther: Bool? = nil
    ) {
        self.name = name
        self.description = description
        self.limitUsd = limitUsd
        self.resetInterval = resetInterval
        self.allowedProviders = allowedProviders
        self.ignoredProviders = ignoredProviders
        self.allowedModels = allowedModels
        self.ignoredModels = ignoredModels
        self.contentFilterBuiltins = contentFilterBuiltins
        self.contentFilters = contentFilters
        self.enforceZdr = enforceZdr
        self.enforceZdrAnthropic = enforceZdrAnthropic
        self.enforceZdrOpenai = enforceZdrOpenai
        self.enforceZdrGoogle = enforceZdrGoogle
        self.enforceZdrOther = enforceZdrOther
    }
}

/// Request body for bulk assigning or unassigning keys to/from a guardrail.
public struct GuardrailAssignKeysRequest: Codable, Sendable {
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
    public let id: String
    public let keyHash: String
    public let guardrailId: String
    public let keyName: String?
    public let keyLabel: String?
    public let assignedBy: String?
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
    public let id: String
    public let userId: String
    public let organizationId: String?
    public let guardrailId: String
    public let assignedBy: String?
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
    public let data: [Guardrail]
    public let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case totalCount = "total_count"
    }
}

/// Response wrapper for a single guardrail.
public struct GuardrailResponse: Codable, Sendable {
    public let data: Guardrail
}

/// Response wrapper for deleting a guardrail.
public struct DeleteGuardrailResponse: Codable, Sendable {
    public let deleted: Bool
}

/// Response wrapper for listing key assignments.
public struct GuardrailKeyAssignmentListResponse: Codable, Sendable {
    public let data: [GuardrailKeyAssignment]
    public let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case totalCount = "total_count"
    }
}

/// Response wrapper for listing member assignments.
public struct GuardrailMemberAssignmentListResponse: Codable, Sendable {
    public let data: [GuardrailMemberAssignment]
    public let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case totalCount = "total_count"
    }
}

/// Response wrapper for bulk key assignment operations.
public struct GuardrailAssignKeysResponse: Codable, Sendable {
    public let assignedCount: Int?
    public let unassignedCount: Int?

    enum CodingKeys: String, CodingKey {
        case assignedCount = "assigned_count"
        case unassignedCount = "unassigned_count"
    }
}

/// Response wrapper for bulk member assignment operations.
public struct GuardrailAssignMembersResponse: Codable, Sendable {
    public let assignedCount: Int?
    public let unassignedCount: Int?

    enum CodingKeys: String, CodingKey {
        case assignedCount = "assigned_count"
        case unassignedCount = "unassigned_count"
    }
}
