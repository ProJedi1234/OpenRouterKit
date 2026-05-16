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

    func list(filters: ModelsListFilters) async throws -> ModelsListResponse {
        try await httpClient.execute(
            .listModels(
                category: filters.category,
                supportedParameters: filters.supportedParameters,
                inputModalities: filters.inputModalities.flatMap(Self.joinRawValues),
                outputModalities: filters.outputModalities.flatMap(Self.joinRawValues),
                useRSS: filters.useRSS,
                useRSSChatLinks: filters.useRSSChatLinks
            ),
            expectedStatusCode: 200
        )
    }

    private static func joinRawValues<T: RawRepresentable>(_ values: [T]) -> String? where T.RawValue == String {
        values.isEmpty ? nil : values.map(\.rawValue).joined(separator: ",")
    }

    func listForUser() async throws -> ModelsListResponse {
        try await httpClient.execute(.listModelsForUser, expectedStatusCode: 200)
    }
}
