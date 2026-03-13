//
//  GuardrailsService.swift
//  OpenRouterKit
//

import Foundation

/// Service for guardrail management operations.
final class GuardrailsService: GuardrailsServiceProtocol {
    private let httpClient: HTTPClient

    /// Creates a new guardrails service.
    ///
    /// - Parameter httpClient: The HTTP client to use for requests
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: - CRUD

    func list(offset: String?, limit: Int?) async throws -> GuardrailListResponse {
        try await httpClient.execute(.listGuardrails(offset: offset, limit: limit), expectedStatusCode: 200)
    }

    func create(request: CreateGuardrailRequest) async throws -> GuardrailResponse {
        try await httpClient.execute(.createGuardrail(request), expectedStatusCode: 201)
    }

    func get(id: String) async throws -> GuardrailResponse {
        try await httpClient.execute(.getGuardrail(id: id), expectedStatusCode: 200)
    }

    func update(id: String, request: UpdateGuardrailRequest) async throws -> GuardrailResponse {
        try await httpClient.execute(.updateGuardrail(id: id, request), expectedStatusCode: 200)
    }

    func delete(id: String) async throws -> DeleteGuardrailResponse {
        try await httpClient.execute(.deleteGuardrail(id: id), expectedStatusCode: 200)
    }

    // MARK: - Assignments (Keys)

    func listAllKeyAssignments(offset: String?, limit: Int?) async throws -> GuardrailKeyAssignmentListResponse {
        try await httpClient.execute(.listAllKeyAssignments(offset: offset, limit: limit), expectedStatusCode: 200)
    }

    func listKeyAssignments(guardrailId: String, offset: String?, limit: Int?) async throws -> GuardrailKeyAssignmentListResponse {
        try await httpClient.execute(.listGuardrailKeyAssignments(guardrailId: guardrailId, offset: offset, limit: limit), expectedStatusCode: 200)
    }

    func assignKeys(guardrailId: String, request: GuardrailAssignKeysRequest) async throws -> GuardrailAssignKeysResponse {
        try await httpClient.execute(.assignGuardrailKeys(guardrailId: guardrailId, request), expectedStatusCode: 200)
    }

    func removeKeys(guardrailId: String, request: GuardrailAssignKeysRequest) async throws -> GuardrailAssignKeysResponse {
        try await httpClient.execute(.removeGuardrailKeys(guardrailId: guardrailId, request), expectedStatusCode: 200)
    }

    // MARK: - Assignments (Members)

    func listAllMemberAssignments(offset: String?, limit: Int?) async throws -> GuardrailMemberAssignmentListResponse {
        try await httpClient.execute(.listAllMemberAssignments(offset: offset, limit: limit), expectedStatusCode: 200)
    }

    func listMemberAssignments(guardrailId: String, offset: String?, limit: Int?) async throws -> GuardrailMemberAssignmentListResponse {
        try await httpClient.execute(.listGuardrailMemberAssignments(guardrailId: guardrailId, offset: offset, limit: limit), expectedStatusCode: 200)
    }

    func assignMembers(guardrailId: String, request: GuardrailAssignMembersRequest) async throws -> GuardrailAssignMembersResponse {
        try await httpClient.execute(.assignGuardrailMembers(guardrailId: guardrailId, request), expectedStatusCode: 200)
    }

    func removeMembers(guardrailId: String, request: GuardrailAssignMembersRequest) async throws -> GuardrailAssignMembersResponse {
        try await httpClient.execute(.removeGuardrailMembers(guardrailId: guardrailId, request), expectedStatusCode: 200)
    }
}
