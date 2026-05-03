//
//  EmbeddingsService.swift
//  OpenRouterKit
//
//  Service for embeddings API calls.
//

import Foundation

/// Service for embeddings operations.
final class EmbeddingsService: EmbeddingsServiceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func create(request: EmbeddingRequest) async throws -> EmbeddingResponse {
        try await httpClient.execute(.createEmbedding(request), expectedStatusCode: 200)
    }

    func listModels() async throws -> ModelsListResponse {
        try await httpClient.execute(.listEmbeddingModels, expectedStatusCode: 200)
    }
}
