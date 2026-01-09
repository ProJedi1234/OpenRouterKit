//
//  KeysService.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Service for API key management operations.
final class KeysService: KeysServiceProtocol {
    private let httpClient: HTTPClient
    
    /// Creates a new keys service.
    ///
    /// - Parameter httpClient: The HTTP client to use for requests
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func list(includeDisabled: Bool?, offset: String?) async throws -> APIKeyListResponse {
        try await httpClient.execute(.listKeys(includeDisabled: includeDisabled, offset: offset), expectedStatusCode: 200)
    }
    
    func create(request: CreateAPIKeyRequest) async throws -> CreateAPIKeyResponse {
        try await httpClient.execute(.createKey(request), expectedStatusCode: 201)
    }
    
    func get(hash: String) async throws -> APIKeyResponse {
        try await httpClient.execute(.getKey(hash: hash), expectedStatusCode: 200)
    }
    
    func update(hash: String, request: UpdateAPIKeyRequest) async throws -> APIKeyResponse {
        try await httpClient.execute(.updateKey(hash: hash, request), expectedStatusCode: 200)
    }
    
    func delete(hash: String) async throws -> DeleteAPIKeyResponse {
        try await httpClient.execute(.deleteKey(hash: hash), expectedStatusCode: 200)
    }
    
    func getCurrent() async throws -> CurrentAPIKeyResponse {
        try await httpClient.execute(.getCurrentKey, expectedStatusCode: 200)
    }
}
