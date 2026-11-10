//
//  Annotation.swift
//  OpenRouterKit
//
//  Message annotations, such as the web citations produced by server tools.
//

import Foundation

/// An annotation attached to an assistant message, such as a web search citation.
///
/// Non-streaming responses carry annotations on `ChatResponse.Choice.Message.annotations`.
/// Streams deliver them as ``ChatStreamEvent/annotations(_:)`` events.
public struct Annotation: Codable, Sendable, Equatable {
    /// The annotation type, for example `"url_citation"`.
    public var type: String

    /// The cited web page, present when `type` is `"url_citation"`.
    public var urlCitation: URLCitation?

    enum CodingKeys: String, CodingKey {
        case type
        case urlCitation = "url_citation"
    }

    /// Creates an annotation.
    public init(type: String, urlCitation: URLCitation? = nil) {
        self.type = type
        self.urlCitation = urlCitation
    }
}

/// A web page cited by the model, typically produced by the `openrouter:web_search` server tool.
///
/// Every field is optional so a sparse citation never causes the surrounding chunk to be dropped.
public struct URLCitation: Codable, Sendable, Equatable {
    /// The cited page's URL.
    public var url: String?

    /// The cited page's title.
    public var title: String?

    /// An excerpt of the cited page, when the search engine returns one.
    public var content: String?

    /// Start of the cited span in the message content.
    public var startIndex: Int?

    /// End of the cited span in the message content.
    public var endIndex: Int?

    enum CodingKeys: String, CodingKey {
        case url, title, content
        case startIndex = "start_index"
        case endIndex = "end_index"
    }

    /// Creates a URL citation.
    public init(
        url: String? = nil,
        title: String? = nil,
        content: String? = nil,
        startIndex: Int? = nil,
        endIndex: Int? = nil
    ) {
        self.url = url
        self.title = title
        self.content = content
        self.startIndex = startIndex
        self.endIndex = endIndex
    }
}
