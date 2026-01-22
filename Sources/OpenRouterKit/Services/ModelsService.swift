//
//  ModelsService.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Service for model listing operations.
final class ModelsService: ModelsServiceProtocol {
    private let httpClient: HTTPClient
    
    /// Creates a new models service.
    ///
    /// - Parameter httpClient: The HTTP client to use for requests
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func list(
        category: String?,
        supportedParameters: String?,
        useRSS: String?,
        useRSSChatLinks: String?
    ) async throws -> ModelsListResponse {
        try await httpClient.execute(
            .listModels(category: category, supportedParameters: supportedParameters, useRSS: useRSS, useRSSChatLinks: useRSSChatLinks),
            expectedStatusCode: 200
        )
    }
    
    func listForUser() async throws -> ModelsListResponse {
        try await httpClient.execute(.listModelsForUser, expectedStatusCode: 200)
    }
}
