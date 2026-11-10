//
//  Tool.swift
//  OpenRouterKit
//
//  Request-side tool definitions for the OpenRouter chat API.
//

import Foundation

/// Represents a tool available for use in a chat request.
///
/// Example:
/// ```swift
/// let tool = Tool(function: FunctionDescription(
///     name: "get_weather",
///     description: "Get the current weather for a location",
///     parameters: .object([
///         "type": .string("object"),
///         "properties": .object([
///             "location": .object([
///                 "type": .string("string"),
///                 "description": .string("The city and state")
///             ])
///         ]),
///         "required": .array([.string("location")])
///     ])
/// ))
/// ```
///
/// Server tools run on OpenRouter's side and can share a request with function tools:
/// ```swift
/// let tools: [Tool] = [
///     .webSearch(WebSearchParameters(engine: .exa, maxResults: 3)),
///     .serverTool(type: "openrouter:datetime"),
///     weatherTool
/// ]
/// ```
public struct Tool: Codable, Sendable {
    /// The type of the tool: `"function"` for a function tool, or an
    /// `openrouter:`-prefixed name such as `"openrouter:web_search"` for a server tool.
    public let type: String

    /// The function associated with the tool. `nil` for server tools.
    public let function: FunctionDescription?

    /// Configuration for a server tool. `nil` for function tools, and optional for server tools.
    public let parameters: JSONValue?

    /// Creates a new function tool.
    ///
    /// - Parameters:
    ///   - type: The type of tool (default: "function")
    ///   - function: The function description
    public init(type: String = "function", function: FunctionDescription) {
        self.type = type
        self.function = function
        self.parameters = nil
    }

    private init(serverType: String, parameters: JSONValue?) {
        self.type = serverType
        self.function = nil
        self.parameters = parameters
    }

    /// Creates a server tool from its type name and raw parameters.
    ///
    /// Use this for server tools that have no typed helper, such as
    /// `"openrouter:web_fetch"` or `"openrouter:image_generation"`.
    ///
    /// - Parameters:
    ///   - type: The full server tool type, including the `openrouter:` prefix
    ///   - parameters: The tool's parameters object, or `nil` to use its defaults
    /// - Returns: A server tool entry for `ChatRequest.tools`.
    public static func serverTool(type: String, parameters: JSONValue? = nil) -> Tool {
        Tool(serverType: type, parameters: parameters)
    }

    /// Creates the `openrouter:web_search` server tool.
    ///
    /// - Parameter parameters: Search configuration. The default sends no parameters.
    /// - Returns: A server tool entry for `ChatRequest.tools`.
    public static func webSearch(_ parameters: WebSearchParameters = WebSearchParameters()) -> Tool {
        Tool(serverType: "openrouter:web_search", parameters: parameters.jsonValue)
    }

    enum CodingKeys: String, CodingKey {
        case type, function, parameters
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(function, forKey: .function)
        try container.encodeIfPresent(parameters, forKey: .parameters)
    }
}

/// Search engine used by the `openrouter:web_search` server tool.
public enum WebSearchEngine: String, Sendable {
    /// The provider's native search when available, otherwise Exa (the default).
    case auto
    /// The model provider's built-in search.
    case native
    case exa
    case firecrawl
    case parallel
    case perplexity
}

/// How much page content the search engine returns per result.
public enum WebSearchContextSize: String, Sendable {
    case low
    case medium
    case high
}

/// Approximate user location, used by native provider search.
public struct WebSearchUserLocation: Sendable, Equatable {
    /// Location type. OpenRouter documents only `"approximate"`.
    public var type: String
    public var city: String?
    public var region: String?
    public var country: String?
    /// IANA time zone, for example `"America/Los_Angeles"`.
    public var timezone: String?

    /// Creates an approximate user location.
    public init(
        type: String = "approximate",
        city: String? = nil,
        region: String? = nil,
        country: String? = nil,
        timezone: String? = nil
    ) {
        self.type = type
        self.city = city
        self.region = region
        self.country = country
        self.timezone = timezone
    }

    var jsonValue: JSONValue {
        var object: [String: JSONValue] = ["type": .string(type)]
        object["city"] = city.map { .string($0) }
        object["region"] = region.map { .string($0) }
        object["country"] = country.map { .string($0) }
        object["timezone"] = timezone.map { .string($0) }
        return .object(object)
    }
}

/// Parameters for the `openrouter:web_search` server tool.
///
/// Every field is optional and omitted from the request when `nil`, so OpenRouter applies its defaults.
public struct WebSearchParameters: Sendable, Equatable {
    /// Search engine. OpenRouter defaults to `.auto`.
    public var engine: WebSearchEngine?

    /// Engine-specific search mode, such as `"fast"` or `"deep"` for Exa. Other engines ignore it.
    public var mode: String?

    /// Results per search, 1-25 (1-20 for Perplexity). OpenRouter defaults to 5.
    public var maxResults: Int?

    /// Maximum number of searches the model may run in this request.
    public var maxUses: Int?

    /// Maximum number of results across all searches in this request.
    public var maxTotalResults: Int?

    /// How much content each result carries. Overridden by `maxCharacters`.
    public var searchContextSize: WebSearchContextSize?

    /// Maximum characters of content per result, 1-100,000.
    public var maxCharacters: Int?

    /// Approximate user location for native provider search.
    public var userLocation: WebSearchUserLocation?

    /// Only return results from these domains.
    public var allowedDomains: [String]?

    /// Never return results from these domains.
    public var excludedDomains: [String]?

    /// Creates web search parameters.
    public init(
        engine: WebSearchEngine? = nil,
        mode: String? = nil,
        maxResults: Int? = nil,
        maxUses: Int? = nil,
        maxTotalResults: Int? = nil,
        searchContextSize: WebSearchContextSize? = nil,
        maxCharacters: Int? = nil,
        userLocation: WebSearchUserLocation? = nil,
        allowedDomains: [String]? = nil,
        excludedDomains: [String]? = nil
    ) {
        self.engine = engine
        self.mode = mode
        self.maxResults = maxResults
        self.maxUses = maxUses
        self.maxTotalResults = maxTotalResults
        self.searchContextSize = searchContextSize
        self.maxCharacters = maxCharacters
        self.userLocation = userLocation
        self.allowedDomains = allowedDomains
        self.excludedDomains = excludedDomains
    }

    /// The wire form of these parameters, or `nil` when every field is unset.
    var jsonValue: JSONValue? {
        var object: [String: JSONValue] = [:]
        object["engine"] = engine.map { .string($0.rawValue) }
        object["mode"] = mode.map { .string($0) }
        object["max_results"] = maxResults.map { .int($0) }
        object["max_uses"] = maxUses.map { .int($0) }
        object["max_total_results"] = maxTotalResults.map { .int($0) }
        object["search_context_size"] = searchContextSize.map { .string($0.rawValue) }
        object["max_characters"] = maxCharacters.map { .int($0) }
        object["user_location"] = userLocation.map(\.jsonValue)
        object["allowed_domains"] = allowedDomains.map { .array($0.map(JSONValue.string)) }
        object["excluded_domains"] = excludedDomains.map { .array($0.map(JSONValue.string)) }
        return object.isEmpty ? nil : .object(object)
    }
}

/// Represents the function description of a tool.
///
/// The `parameters` field should be a JSON Schema object describing the function's parameters.
public struct FunctionDescription: Codable, Sendable {
    /// The name of the function.
    public let name: String

    /// Optional description of what the function does.
    public let description: String?

    /// JSON Schema describing the function's parameters.
    public let parameters: JSONValue

    /// Whether to enable strict schema adherence (optional).
    public let strict: Bool?

    /// Creates a new function description.
    ///
    /// - Parameters:
    ///   - name: The function name
    ///   - description: Optional description of the function
    ///   - parameters: JSON Schema for the function parameters
    ///   - strict: Whether to enable strict schema adherence
    public init(name: String, description: String? = nil, parameters: JSONValue, strict: Bool? = nil) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.strict = strict
    }
}

/// Represents the choice of tools in a chat request.
///
/// Controls how the model selects tools:
/// - `.none`: The model will not call any tools
/// - `.auto`: The model decides whether to call tools (default behavior)
/// - `.required`: The model must call at least one tool
/// - `.function(name:)`: The model must call the specified function
public enum ToolChoice: Codable, Sendable {
    /// No tools should be used.
    case none
    /// Automatically choose tools (default).
    case auto
    /// The model must call at least one tool.
    case required
    /// Use a specific function by name.
    case function(name: String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as a string first ("none", "auto", "required")
        if let stringValue = try? container.decode(String.self) {
            switch stringValue {
            case "none":
                self = .none
            case "auto":
                self = .auto
            case "required":
                self = .required
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid tool choice string: \(stringValue)"
                )
            }
            return
        }

        // Try decoding as an object {"type": "function", "function": {"name": "..."}}
        let objectContainer = try decoder.container(keyedBy: ToolChoiceCodingKeys.self)
        let type = try objectContainer.decode(String.self, forKey: .type)
        if type == "function" {
            let functionObj = try objectContainer.decode(ToolChoiceFunction.self, forKey: .function)
            self = .function(name: functionObj.name)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: objectContainer,
                debugDescription: "Invalid tool choice type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .none:
            var container = encoder.singleValueContainer()
            try container.encode("none")
        case .auto:
            var container = encoder.singleValueContainer()
            try container.encode("auto")
        case .required:
            var container = encoder.singleValueContainer()
            try container.encode("required")
        case .function(let name):
            var container = encoder.container(keyedBy: ToolChoiceCodingKeys.self)
            try container.encode("function", forKey: .type)
            try container.encode(ToolChoiceFunction(name: name), forKey: .function)
        }
    }

    private enum ToolChoiceCodingKeys: String, CodingKey {
        case type
        case function
    }

    private struct ToolChoiceFunction: Codable, Sendable {
        let name: String
    }
}
