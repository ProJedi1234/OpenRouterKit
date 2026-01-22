//
//  RequestBuilder.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Builds URLRequest objects for OpenRouter API endpoints.
struct RequestBuilder {
    let baseURL: String
    let apiKey: String
    let siteURL: String?
    let siteName: String?
    
    /// Builds a URLRequest for the given endpoint.
    ///
    /// - Parameter endpoint: The endpoint to build a request for
    /// - Returns: A configured URLRequest
    /// - Throws: URLError if the URL cannot be constructed
    func build(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(string: "\(baseURL)\(endpoint.path)")
        components?.queryItems = endpoint.queryItems
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Set common headers
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        if let siteURL = siteURL {
            request.addValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }
        
        if let siteName = siteName {
            request.addValue(siteName, forHTTPHeaderField: "X-Title")
        }
        
        // Set body if present
        if let body = endpoint.body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        return request
    }
}
