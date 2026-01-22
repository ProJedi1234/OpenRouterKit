//
//  APIKeyTypes.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 12/19/24.
//

import Foundation

// MARK: - Enums

/// Type of limit reset for an API key
public enum APIKeyLimitReset: String, Codable, Sendable {
    case daily
    case weekly
    case monthly
}

// MARK: - Core Models

/// Represents an API key with all its properties
public struct APIKey: Codable, Sendable {
    /// Unique hash identifier for the API key
    public let hash: String
    
    /// Name of the API key
    public let name: String
    
    /// Human-readable label for the API key
    public let label: String
    
    /// Whether the API key is disabled
    public let disabled: Bool
    
    /// Spending limit for the API key in USD
    public let limit: Double?
    
    /// Remaining spending limit in USD
    public let limitRemaining: Double?
    
    /// Type of limit reset for the API key
    public let limitReset: APIKeyLimitReset?
    
    /// Whether to include external BYOK usage in the credit limit
    public let includeByokInLimit: Bool
    
    /// Total OpenRouter credit usage (in USD) for the API key
    public let usage: Double
    
    /// OpenRouter credit usage (in USD) for the current UTC day
    public let usageDaily: Double
    
    /// OpenRouter credit usage (in USD) for the current UTC week (Monday-Sunday)
    public let usageWeekly: Double
    
    /// OpenRouter credit usage (in USD) for the current UTC month
    public let usageMonthly: Double
    
    /// Total external BYOK usage (in USD) for the API key
    public let byokUsage: Double
    
    /// External BYOK usage (in USD) for the current UTC day
    public let byokUsageDaily: Double
    
    /// External BYOK usage (in USD) for the current UTC week (Monday-Sunday)
    public let byokUsageWeekly: Double
    
    /// External BYOK usage (in USD) for current UTC month
    public let byokUsageMonthly: Double
    
    /// ISO 8601 timestamp of when the API key was created
    public let createdAt: Date
    
    /// ISO 8601 timestamp of when the API key was last updated
    public let updatedAt: Date?
    
    /// ISO 8601 UTC timestamp when the API key expires, or null if no expiration
    public let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case hash
        case name
        case label
        case disabled
        case limit
        case limitRemaining = "limit_remaining"
        case limitReset = "limit_reset"
        case includeByokInLimit = "include_byok_in_limit"
        case usage
        case usageDaily = "usage_daily"
        case usageWeekly = "usage_weekly"
        case usageMonthly = "usage_monthly"
        case byokUsage = "byok_usage"
        case byokUsageDaily = "byok_usage_daily"
        case byokUsageWeekly = "byok_usage_weekly"
        case byokUsageMonthly = "byok_usage_monthly"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        hash = try container.decode(String.self, forKey: .hash)
        name = try container.decode(String.self, forKey: .name)
        label = try container.decode(String.self, forKey: .label)
        disabled = try container.decode(Bool.self, forKey: .disabled)
        limit = try container.decodeIfPresent(Double.self, forKey: .limit)
        limitRemaining = try container.decodeIfPresent(Double.self, forKey: .limitRemaining)
        
        // Handle limit_reset as optional string that can be decoded to enum or nil
        if let limitResetString = try container.decodeIfPresent(String.self, forKey: .limitReset) {
            limitReset = APIKeyLimitReset(rawValue: limitResetString)
        } else {
            limitReset = nil
        }
        
        includeByokInLimit = try container.decode(Bool.self, forKey: .includeByokInLimit)
        usage = try container.decode(Double.self, forKey: .usage)
        usageDaily = try container.decode(Double.self, forKey: .usageDaily)
        usageWeekly = try container.decode(Double.self, forKey: .usageWeekly)
        usageMonthly = try container.decode(Double.self, forKey: .usageMonthly)
        byokUsage = try container.decode(Double.self, forKey: .byokUsage)
        byokUsageDaily = try container.decode(Double.self, forKey: .byokUsageDaily)
        byokUsageWeekly = try container.decode(Double.self, forKey: .byokUsageWeekly)
        byokUsageMonthly = try container.decode(Double.self, forKey: .byokUsageMonthly)
        
        // Decode dates from ISO8601 strings (supporting both with and without fractional seconds)
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = Self.parseISO8601Date(createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format for created_at")
        }
        createdAt = createdAtDate
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = Self.parseISO8601Date(updatedAtString)
        } else {
            updatedAt = nil
        }
        
        if let expiresAtString = try container.decodeIfPresent(String.self, forKey: .expiresAt) {
            expiresAt = Self.parseISO8601Date(expiresAtString)
        } else {
            expiresAt = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hash, forKey: .hash)
        try container.encode(name, forKey: .name)
        try container.encode(label, forKey: .label)
        try container.encode(disabled, forKey: .disabled)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(limitRemaining, forKey: .limitRemaining)
        try container.encodeIfPresent(limitReset?.rawValue, forKey: .limitReset)
        try container.encode(includeByokInLimit, forKey: .includeByokInLimit)
        try container.encode(usage, forKey: .usage)
        try container.encode(usageDaily, forKey: .usageDaily)
        try container.encode(usageWeekly, forKey: .usageWeekly)
        try container.encode(usageMonthly, forKey: .usageMonthly)
        try container.encode(byokUsage, forKey: .byokUsage)
        try container.encode(byokUsageDaily, forKey: .byokUsageDaily)
        try container.encode(byokUsageWeekly, forKey: .byokUsageWeekly)
        try container.encode(byokUsageMonthly, forKey: .byokUsageMonthly)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        if let updatedAt = updatedAt {
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        } else {
            try container.encodeNil(forKey: .updatedAt)
        }
        if let expiresAt = expiresAt {
            try container.encode(dateFormatter.string(from: expiresAt), forKey: .expiresAt)
        } else {
            try container.encodeNil(forKey: .expiresAt)
        }
    }
    
    /// Helper method to parse ISO8601 dates supporting both formats (with and without fractional seconds)
    private static func parseISO8601Date(_ dateString: String) -> Date? {
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatterWithFractional.date(from: dateString) {
            return date
        }
        
        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]
        
        return formatterWithoutFractional.date(from: dateString)
    }
}

/// Represents rate limit information for an API key
public struct RateLimit: Codable, Sendable {
    /// Number of requests allowed per interval
    public let requests: Double
    
    /// Rate limit interval
    public let interval: String
    
    /// Note about the rate limit
    public let note: String
}

/// Represents the current API key information (different structure than regular APIKey)
public struct CurrentAPIKey: Codable, Sendable {
    /// Human-readable label for the API key
    public let label: String
    
    /// Spending limit for the API key in USD
    public let limit: Double?
    
    /// Total OpenRouter credit usage (in USD) for the API key
    public let usage: Double
    
    /// OpenRouter credit usage (in USD) for the current UTC day
    public let usageDaily: Double
    
    /// OpenRouter credit usage (in USD) for the current UTC week (Monday-Sunday)
    public let usageWeekly: Double
    
    /// OpenRouter credit usage (in USD) for the current UTC month
    public let usageMonthly: Double
    
    /// Total external BYOK usage (in USD) for the API key
    public let byokUsage: Double
    
    /// External BYOK usage (in USD) for the current UTC day
    public let byokUsageDaily: Double
    
    /// External BYOK usage (in USD) for the current UTC week (Monday-Sunday)
    public let byokUsageWeekly: Double
    
    /// External BYOK usage (in USD) for current UTC month
    public let byokUsageMonthly: Double
    
    /// Whether this is a free tier API key
    public let isFreeTier: Bool
    
    /// Whether this is a provisioning key
    public let isProvisioningKey: Bool
    
    /// Remaining spending limit in USD
    public let limitRemaining: Double?
    
    /// Type of limit reset for the API key
    public let limitReset: APIKeyLimitReset?
    
    /// Whether to include external BYOK usage in the credit limit
    public let includeByokInLimit: Bool
    
    /// ISO 8601 UTC timestamp when the API key expires, or null if no expiration
    public let expiresAt: Date?
    
    /// Legacy rate limit information about a key. Will always return -1.
    public let rateLimit: RateLimit
    
    enum CodingKeys: String, CodingKey {
        case label
        case limit
        case usage
        case usageDaily = "usage_daily"
        case usageWeekly = "usage_weekly"
        case usageMonthly = "usage_monthly"
        case byokUsage = "byok_usage"
        case byokUsageDaily = "byok_usage_daily"
        case byokUsageWeekly = "byok_usage_weekly"
        case byokUsageMonthly = "byok_usage_monthly"
        case isFreeTier = "is_free_tier"
        case isProvisioningKey = "is_provisioning_key"
        case limitRemaining = "limit_remaining"
        case limitReset = "limit_reset"
        case includeByokInLimit = "include_byok_in_limit"
        case expiresAt = "expires_at"
        case rateLimit = "rate_limit"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        label = try container.decode(String.self, forKey: .label)
        limit = try container.decodeIfPresent(Double.self, forKey: .limit)
        usage = try container.decode(Double.self, forKey: .usage)
        usageDaily = try container.decode(Double.self, forKey: .usageDaily)
        usageWeekly = try container.decode(Double.self, forKey: .usageWeekly)
        usageMonthly = try container.decode(Double.self, forKey: .usageMonthly)
        byokUsage = try container.decode(Double.self, forKey: .byokUsage)
        byokUsageDaily = try container.decode(Double.self, forKey: .byokUsageDaily)
        byokUsageWeekly = try container.decode(Double.self, forKey: .byokUsageWeekly)
        byokUsageMonthly = try container.decode(Double.self, forKey: .byokUsageMonthly)
        isFreeTier = try container.decode(Bool.self, forKey: .isFreeTier)
        isProvisioningKey = try container.decode(Bool.self, forKey: .isProvisioningKey)
        limitRemaining = try container.decodeIfPresent(Double.self, forKey: .limitRemaining)
        
        if let limitResetString = try container.decodeIfPresent(String.self, forKey: .limitReset) {
            limitReset = APIKeyLimitReset(rawValue: limitResetString)
        } else {
            limitReset = nil
        }
        
        includeByokInLimit = try container.decode(Bool.self, forKey: .includeByokInLimit)
        
        if let expiresAtString = try container.decodeIfPresent(String.self, forKey: .expiresAt) {
            expiresAt = Self.parseISO8601Date(expiresAtString)
        } else {
            expiresAt = nil
        }
        
        rateLimit = try container.decode(RateLimit.self, forKey: .rateLimit)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encode(usage, forKey: .usage)
        try container.encode(usageDaily, forKey: .usageDaily)
        try container.encode(usageWeekly, forKey: .usageWeekly)
        try container.encode(usageMonthly, forKey: .usageMonthly)
        try container.encode(byokUsage, forKey: .byokUsage)
        try container.encode(byokUsageDaily, forKey: .byokUsageDaily)
        try container.encode(byokUsageWeekly, forKey: .byokUsageWeekly)
        try container.encode(byokUsageMonthly, forKey: .byokUsageMonthly)
        try container.encode(isFreeTier, forKey: .isFreeTier)
        try container.encode(isProvisioningKey, forKey: .isProvisioningKey)
        try container.encodeIfPresent(limitRemaining, forKey: .limitRemaining)
        try container.encodeIfPresent(limitReset?.rawValue, forKey: .limitReset)
        try container.encode(includeByokInLimit, forKey: .includeByokInLimit)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let expiresAt = expiresAt {
            try container.encode(dateFormatter.string(from: expiresAt), forKey: .expiresAt)
        } else {
            try container.encodeNil(forKey: .expiresAt)
        }
        
        try container.encode(rateLimit, forKey: .rateLimit)
    }
    
    /// Helper method to parse ISO8601 dates supporting both formats (with and without fractional seconds)
    private static func parseISO8601Date(_ dateString: String) -> Date? {
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatterWithFractional.date(from: dateString) {
            return date
        }
        
        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]
        
        return formatterWithoutFractional.date(from: dateString)
    }
}

// MARK: - Request Models

/// Request body for creating a new API key
public struct CreateAPIKeyRequest: Codable, Sendable {
    /// Name for the new API key (required)
    public let name: String
    
    /// Optional spending limit for the API key in USD
    public let limit: Double?
    
    /// Type of limit reset for the API key (daily, weekly, monthly, or null for no reset)
    public let limitReset: APIKeyLimitReset?
    
    /// Whether to include BYOK usage in the limit
    public let includeByokInLimit: Bool?
    
    /// Optional ISO 8601 UTC timestamp when the API key should expire
    public let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case name
        case limit
        case limitReset = "limit_reset"
        case includeByokInLimit = "include_byok_in_limit"
        case expiresAt = "expires_at"
    }
    
    public init(
        name: String,
        limit: Double? = nil,
        limitReset: APIKeyLimitReset? = nil,
        includeByokInLimit: Bool? = nil,
        expiresAt: Date? = nil
    ) {
        self.name = name
        self.limit = limit
        self.limitReset = limitReset
        self.includeByokInLimit = includeByokInLimit
        self.expiresAt = expiresAt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(limitReset?.rawValue, forKey: .limitReset)
        try container.encodeIfPresent(includeByokInLimit, forKey: .includeByokInLimit)
        
        if let expiresAt = expiresAt {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(dateFormatter.string(from: expiresAt), forKey: .expiresAt)
        } else {
            try container.encodeNil(forKey: .expiresAt)
        }
    }
}

/// Request body for updating an API key
public struct UpdateAPIKeyRequest: Codable, Sendable {
    /// New name for the API key
    public let name: String?
    
    /// Whether to disable the API key
    public let disabled: Bool?
    
    /// New spending limit for the API key in USD
    public let limit: Double?
    
    /// New limit reset type for the API key (daily, weekly, monthly, or null for no reset)
    public let limitReset: APIKeyLimitReset?
    
    /// Whether to include BYOK usage in the limit
    public let includeByokInLimit: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case disabled
        case limit
        case limitReset = "limit_reset"
        case includeByokInLimit = "include_byok_in_limit"
    }
    
    public init(
        name: String? = nil,
        disabled: Bool? = nil,
        limit: Double? = nil,
        limitReset: APIKeyLimitReset? = nil,
        includeByokInLimit: Bool? = nil
    ) {
        self.name = name
        self.disabled = disabled
        self.limit = limit
        self.limitReset = limitReset
        self.includeByokInLimit = includeByokInLimit
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(disabled, forKey: .disabled)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(limitReset?.rawValue, forKey: .limitReset)
        try container.encodeIfPresent(includeByokInLimit, forKey: .includeByokInLimit)
    }
}

// MARK: - Response Models

/// Response wrapper for listing API keys
public struct APIKeyListResponse: Codable, Sendable {
    /// List of API keys
    public let data: [APIKey]
}

/// Response wrapper for a single API key
public struct APIKeyResponse: Codable, Sendable {
    /// The API key information
    public let data: APIKey
}

/// Response wrapper for creating an API key
public struct CreateAPIKeyResponse: Codable, Sendable {
    /// The created API key information
    public let data: APIKey
    
    /// The actual API key string (only shown once)
    public let key: String
}

/// Response wrapper for the current API key
public struct CurrentAPIKeyResponse: Codable, Sendable {
    /// Current API key information
    public let data: CurrentAPIKey
}

/// Response wrapper for deleting an API key
public struct DeleteAPIKeyResponse: Codable, Sendable {
    /// Confirmation that the API key was deleted
    public let deleted: Bool
}
