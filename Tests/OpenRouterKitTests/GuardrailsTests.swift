//
//  GuardrailsTests.swift
//  OpenRouterKit
//

import Testing
import Foundation
@testable import OpenRouterKit

@Suite("Guardrails Types")
struct GuardrailsTypesTests {

    // MARK: - Guardrail Decoding

    @Test func testDecodeGuardrail() throws {
        let json = Data("""
        {
            "id": "gr_123",
            "name": "Production Guardrail",
            "description": "Limits for production keys",
            "limit_usd": 100.0,
            "reset_interval": "monthly",
            "allowed_providers": ["openai", "anthropic"],
            "ignored_providers": ["google"],
            "allowed_models": ["openai/gpt-4o"],
            "enforce_zdr": true,
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-06-01T00:00:00Z"
        }
        """.utf8)

        let guardrail = try JSONDecoder().decode(Guardrail.self, from: json)

        #expect(guardrail.id == "gr_123")
        #expect(guardrail.name == "Production Guardrail")
        #expect(guardrail.description == "Limits for production keys")
        #expect(guardrail.limitUsd == 100.0)
        #expect(guardrail.resetInterval == .monthly)
        #expect(guardrail.allowedProviders == ["openai", "anthropic"])
        #expect(guardrail.ignoredProviders == ["google"])
        #expect(guardrail.allowedModels == ["openai/gpt-4o"])
        #expect(guardrail.enforceZdr == true)
        #expect(guardrail.createdAt == "2025-01-01T00:00:00Z")
        #expect(guardrail.updatedAt == "2025-06-01T00:00:00Z")
    }

    @Test func testDecodeGuardrailMinimalFields() throws {
        let json = Data("""
        {
            "id": "gr_456",
            "name": "Basic Guardrail"
        }
        """.utf8)

        let guardrail = try JSONDecoder().decode(Guardrail.self, from: json)

        #expect(guardrail.id == "gr_456")
        #expect(guardrail.name == "Basic Guardrail")
        #expect(guardrail.description == nil)
        #expect(guardrail.limitUsd == nil)
        #expect(guardrail.resetInterval == nil)
        #expect(guardrail.allowedProviders == nil)
        #expect(guardrail.ignoredProviders == nil)
        #expect(guardrail.allowedModels == nil)
        #expect(guardrail.enforceZdr == nil)
    }

    @Test func testDecodeGuardrailListResponse() throws {
        let json = Data("""
        {
            "data": [
                {"id": "gr_1", "name": "First"},
                {"id": "gr_2", "name": "Second"}
            ],
            "total_count": 42
        }
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailListResponse.self, from: json)
        #expect(response.data.count == 2)
        #expect(response.data[0].id == "gr_1")
        #expect(response.data[1].name == "Second")
        #expect(response.totalCount == 42)
    }

    @Test func testDecodeGuardrailListResponseWithoutTotalCount() throws {
        let json = Data("""
        {
            "data": [{"id": "gr_1", "name": "First"}]
        }
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailListResponse.self, from: json)
        #expect(response.data.count == 1)
        #expect(response.totalCount == nil)
    }

    @Test func testDecodeGuardrailResponse() throws {
        let json = Data("""
        {
            "data": {
                "id": "gr_1",
                "name": "Test"
            }
        }
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailResponse.self, from: json)
        #expect(response.data.id == "gr_1")
    }

    @Test func testDecodeDeleteGuardrailResponse() throws {
        let json = Data("""
        {"deleted": true}
        """.utf8)

        let response = try JSONDecoder().decode(DeleteGuardrailResponse.self, from: json)
        #expect(response.deleted == true)
    }

    // MARK: - Request Encoding

    @Test func testEncodeCreateGuardrailRequest() throws {
        let request = CreateGuardrailRequest(
            name: "New Guardrail",
            description: "A test guardrail",
            limitUsd: 50.0,
            resetInterval: .weekly,
            allowedProviders: ["openai"],
            ignoredProviders: nil,
            allowedModels: ["openai/gpt-4o"],
            enforceZdr: false
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(dict?["name"] as? String == "New Guardrail")
        #expect(dict?["description"] as? String == "A test guardrail")
        #expect(dict?["limit_usd"] as? Double == 50.0)
        #expect(dict?["reset_interval"] as? String == "weekly")
        #expect(dict?["allowed_providers"] as? [String] == ["openai"])
        #expect(dict?["allowed_models"] as? [String] == ["openai/gpt-4o"])
        #expect(dict?["enforce_zdr"] as? Bool == false)
    }

    @Test func testEncodeCreateGuardrailRequestMinimal() throws {
        let request = CreateGuardrailRequest(name: "Minimal")

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(dict?["name"] as? String == "Minimal")
        #expect(dict?.keys.count == 1)
    }

    @Test func testEncodeUpdateGuardrailRequest() throws {
        let request = UpdateGuardrailRequest(
            name: "Updated Name",
            limitUsd: 200.0,
            resetInterval: .daily
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(dict?["name"] as? String == "Updated Name")
        #expect(dict?["limit_usd"] as? Double == 200.0)
        #expect(dict?["reset_interval"] as? String == "daily")
    }

    @Test func testEncodeAssignKeysRequest() throws {
        let request = GuardrailAssignKeysRequest(keyHashes: ["hash_1", "hash_2"])

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(dict?["key_hashes"] as? [String] == ["hash_1", "hash_2"])
    }

    @Test func testEncodeAssignMembersRequest() throws {
        let request = GuardrailAssignMembersRequest(memberUserIds: ["user_1", "user_2"])

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(dict?["member_user_ids"] as? [String] == ["user_1", "user_2"])
    }

    // MARK: - Assignment Decoding

    @Test func testDecodeKeyAssignment() throws {
        let json = Data("""
        {
            "id": "ka_1",
            "key_hash": "abc123",
            "guardrail_id": "gr_1",
            "key_name": "Production Key",
            "key_label": "prod-key",
            "assigned_by": "user_42",
            "created_at": "2025-01-01T00:00:00Z"
        }
        """.utf8)

        let assignment = try JSONDecoder().decode(GuardrailKeyAssignment.self, from: json)
        #expect(assignment.id == "ka_1")
        #expect(assignment.keyHash == "abc123")
        #expect(assignment.guardrailId == "gr_1")
        #expect(assignment.keyName == "Production Key")
        #expect(assignment.keyLabel == "prod-key")
        #expect(assignment.assignedBy == "user_42")
        #expect(assignment.createdAt == "2025-01-01T00:00:00Z")
    }

    @Test func testDecodeMemberAssignment() throws {
        let json = Data("""
        {
            "id": "ma_1",
            "user_id": "user_42",
            "organization_id": "org_1",
            "guardrail_id": "gr_1",
            "assigned_by": "admin_1",
            "created_at": "2025-01-01T00:00:00Z"
        }
        """.utf8)

        let assignment = try JSONDecoder().decode(GuardrailMemberAssignment.self, from: json)
        #expect(assignment.id == "ma_1")
        #expect(assignment.userId == "user_42")
        #expect(assignment.organizationId == "org_1")
        #expect(assignment.guardrailId == "gr_1")
        #expect(assignment.assignedBy == "admin_1")
        #expect(assignment.createdAt == "2025-01-01T00:00:00Z")
    }

    @Test func testDecodeKeyAssignmentListResponse() throws {
        let json = Data("""
        {
            "data": [
                {"id": "ka_1", "key_hash": "h1", "guardrail_id": "gr_1"},
                {"id": "ka_2", "key_hash": "h2", "guardrail_id": "gr_1"}
            ],
            "total_count": 2
        }
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailKeyAssignmentListResponse.self, from: json)
        #expect(response.data.count == 2)
        #expect(response.totalCount == 2)
    }

    @Test func testDecodeMemberAssignmentListResponse() throws {
        let json = Data("""
        {
            "data": [
                {"id": "ma_1", "user_id": "u1", "guardrail_id": "gr_1"}
            ],
            "total_count": 1
        }
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailMemberAssignmentListResponse.self, from: json)
        #expect(response.data.count == 1)
        #expect(response.data[0].userId == "u1")
        #expect(response.totalCount == 1)
    }

    @Test func testDecodeBulkAssignKeysResponse() throws {
        let json = Data("""
        {"assigned_count": 3}
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailAssignKeysResponse.self, from: json)
        #expect(response.assignedCount == 3)
        #expect(response.unassignedCount == nil)
    }

    @Test func testDecodeBulkUnassignKeysResponse() throws {
        let json = Data("""
        {"unassigned_count": 2}
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailAssignKeysResponse.self, from: json)
        #expect(response.unassignedCount == 2)
        #expect(response.assignedCount == nil)
    }

    @Test func testDecodeBulkAssignMembersResponse() throws {
        let json = Data("""
        {"assigned_count": 5}
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailAssignMembersResponse.self, from: json)
        #expect(response.assignedCount == 5)
    }

    @Test func testDecodeBulkUnassignMembersResponse() throws {
        let json = Data("""
        {"unassigned_count": 1}
        """.utf8)

        let response = try JSONDecoder().decode(GuardrailAssignMembersResponse.self, from: json)
        #expect(response.unassignedCount == 1)
    }

    // MARK: - Reset Interval

    @Test func testGuardrailResetIntervalValues() {
        #expect(GuardrailResetInterval.daily.rawValue == "daily")
        #expect(GuardrailResetInterval.weekly.rawValue == "weekly")
        #expect(GuardrailResetInterval.monthly.rawValue == "monthly")
    }
}

@Suite("Guardrails Endpoints")
struct GuardrailsEndpointTests {

    @Test func testListGuardrailsEndpoint() {
        let endpoint = Endpoint.listGuardrails(offset: nil, limit: nil)
        #expect(endpoint.method == .GET)
        #expect(endpoint.path == "/guardrails")
        #expect(endpoint.queryItems == nil)
        #expect(endpoint.body == nil)
    }

    @Test func testListGuardrailsWithPagination() {
        let endpoint = Endpoint.listGuardrails(offset: "abc123", limit: 50)
        #expect(endpoint.queryItems?.count == 2)
        #expect(endpoint.queryItems?[0].name == "offset")
        #expect(endpoint.queryItems?[0].value == "abc123")
        #expect(endpoint.queryItems?[1].name == "limit")
        #expect(endpoint.queryItems?[1].value == "50")
    }

    @Test func testCreateGuardrailEndpoint() {
        let request = CreateGuardrailRequest(name: "Test")
        let endpoint = Endpoint.createGuardrail(request)
        #expect(endpoint.method == .POST)
        #expect(endpoint.path == "/guardrails")
        #expect(endpoint.expectedStatusCode == 201)
        #expect(endpoint.body != nil)
    }

    @Test func testGetGuardrailEndpoint() {
        let endpoint = Endpoint.getGuardrail(id: "gr_123")
        #expect(endpoint.method == .GET)
        #expect(endpoint.path == "/guardrails/gr_123")
        #expect(endpoint.body == nil)
    }

    @Test func testUpdateGuardrailEndpoint() {
        let request = UpdateGuardrailRequest(name: "Updated")
        let endpoint = Endpoint.updateGuardrail(id: "gr_123", request)
        #expect(endpoint.method == .PATCH)
        #expect(endpoint.path == "/guardrails/gr_123")
        #expect(endpoint.body != nil)
    }

    @Test func testDeleteGuardrailEndpoint() {
        let endpoint = Endpoint.deleteGuardrail(id: "gr_123")
        #expect(endpoint.method == .DELETE)
        #expect(endpoint.path == "/guardrails/gr_123")
    }

    @Test func testListAllKeyAssignmentsEndpoint() {
        let endpoint = Endpoint.listAllKeyAssignments(offset: nil, limit: nil)
        #expect(endpoint.method == .GET)
        #expect(endpoint.path == "/guardrails/assignments/keys")
    }

    @Test func testListAllKeyAssignmentsWithPagination() {
        let endpoint = Endpoint.listAllKeyAssignments(offset: "off1", limit: 25)
        #expect(endpoint.queryItems?.count == 2)
    }

    @Test func testListAllMemberAssignmentsEndpoint() {
        let endpoint = Endpoint.listAllMemberAssignments(offset: nil, limit: nil)
        #expect(endpoint.method == .GET)
        #expect(endpoint.path == "/guardrails/assignments/members")
    }

    @Test func testListGuardrailKeyAssignmentsEndpoint() {
        let endpoint = Endpoint.listGuardrailKeyAssignments(guardrailId: "gr_1", offset: nil, limit: nil)
        #expect(endpoint.method == .GET)
        #expect(endpoint.path == "/guardrails/gr_1/assignments/keys")
    }

    @Test func testAssignGuardrailKeysEndpoint() {
        let request = GuardrailAssignKeysRequest(keyHashes: ["h1"])
        let endpoint = Endpoint.assignGuardrailKeys(guardrailId: "gr_1", request)
        #expect(endpoint.method == .POST)
        #expect(endpoint.path == "/guardrails/gr_1/assignments/keys")
        #expect(endpoint.body != nil)
    }

    @Test func testRemoveGuardrailKeysEndpoint() {
        let request = GuardrailAssignKeysRequest(keyHashes: ["h1"])
        let endpoint = Endpoint.removeGuardrailKeys(guardrailId: "gr_1", request)
        #expect(endpoint.method == .POST)
        #expect(endpoint.path == "/guardrails/gr_1/assignments/keys/remove")
    }

    @Test func testListGuardrailMemberAssignmentsEndpoint() {
        let endpoint = Endpoint.listGuardrailMemberAssignments(guardrailId: "gr_1", offset: nil, limit: nil)
        #expect(endpoint.method == .GET)
        #expect(endpoint.path == "/guardrails/gr_1/assignments/members")
    }

    @Test func testAssignGuardrailMembersEndpoint() {
        let request = GuardrailAssignMembersRequest(memberUserIds: ["u1"])
        let endpoint = Endpoint.assignGuardrailMembers(guardrailId: "gr_1", request)
        #expect(endpoint.method == .POST)
        #expect(endpoint.path == "/guardrails/gr_1/assignments/members")
    }

    @Test func testRemoveGuardrailMembersEndpoint() {
        let request = GuardrailAssignMembersRequest(memberUserIds: ["u1"])
        let endpoint = Endpoint.removeGuardrailMembers(guardrailId: "gr_1", request)
        #expect(endpoint.method == .POST)
        #expect(endpoint.path == "/guardrails/gr_1/assignments/members/remove")
    }
}
