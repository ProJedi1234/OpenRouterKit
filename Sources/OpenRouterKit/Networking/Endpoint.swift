//
//  Endpoint.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Represents an API endpoint for the OpenRouter service.
package enum Endpoint {
    case chatCompletions(ChatRequest)
    case listModels(category: String?, supportedParameters: String?, useRSS: String?, useRSSChatLinks: String?)
    case listModelsForUser
    case listKeys(includeDisabled: Bool?, offset: String?)
    case createKey(CreateAPIKeyRequest)
    case getKey(hash: String)
    case updateKey(hash: String, UpdateAPIKeyRequest)
    case deleteKey(hash: String)
    case getCurrentKey

    // Guardrails CRUD
    case listGuardrails(offset: String?, limit: Int?)
    case createGuardrail(CreateGuardrailRequest)
    case getGuardrail(id: String)
    case updateGuardrail(id: String, UpdateGuardrailRequest)
    case deleteGuardrail(id: String)

    // Guardrails Assignments
    case listAllKeyAssignments(offset: String?, limit: Int?)
    case listAllMemberAssignments(offset: String?, limit: Int?)
    case listGuardrailKeyAssignments(guardrailId: String, offset: String?, limit: Int?)
    case assignGuardrailKeys(guardrailId: String, GuardrailAssignKeysRequest)
    case removeGuardrailKeys(guardrailId: String, GuardrailAssignKeysRequest)
    case listGuardrailMemberAssignments(guardrailId: String, offset: String?, limit: Int?)
    case assignGuardrailMembers(guardrailId: String, GuardrailAssignMembersRequest)
    case removeGuardrailMembers(guardrailId: String, GuardrailAssignMembersRequest)

    /// The HTTP method for this endpoint.
    var method: HTTPMethod {
        switch self {
        case .chatCompletions, .createKey, .createGuardrail,
             .assignGuardrailKeys, .removeGuardrailKeys,
             .assignGuardrailMembers, .removeGuardrailMembers:
            return .POST
        case .updateKey, .updateGuardrail:
            return .PATCH
        case .deleteKey, .deleteGuardrail:
            return .DELETE
        case .listModels, .listModelsForUser, .listKeys, .getKey, .getCurrentKey,
             .listGuardrails, .getGuardrail,
             .listAllKeyAssignments, .listAllMemberAssignments,
             .listGuardrailKeyAssignments, .listGuardrailMemberAssignments:
            return .GET
        }
    }

    /// The path for this endpoint.
    var path: String {
        switch self {
        case .chatCompletions:
            return "/chat/completions"
        case .listModels:
            return "/models"
        case .listModelsForUser:
            return "/models/user"
        case .listKeys, .createKey:
            return "/keys"
        case .getKey(let hash), .updateKey(let hash, _), .deleteKey(let hash):
            return "/keys/\(hash)"
        case .getCurrentKey:
            return "/key"
        case .listGuardrails, .createGuardrail:
            return "/guardrails"
        case .getGuardrail(let id), .updateGuardrail(let id, _), .deleteGuardrail(let id):
            return "/guardrails/\(id)"
        case .listAllKeyAssignments:
            return "/guardrails/assignments/keys"
        case .listAllMemberAssignments:
            return "/guardrails/assignments/members"
        case .listGuardrailKeyAssignments(let guardrailId, _, _), .assignGuardrailKeys(let guardrailId, _):
            return "/guardrails/\(guardrailId)/assignments/keys"
        case .removeGuardrailKeys(let guardrailId, _):
            return "/guardrails/\(guardrailId)/assignments/keys/remove"
        case .listGuardrailMemberAssignments(let guardrailId, _, _), .assignGuardrailMembers(let guardrailId, _):
            return "/guardrails/\(guardrailId)/assignments/members"
        case .removeGuardrailMembers(let guardrailId, _):
            return "/guardrails/\(guardrailId)/assignments/members/remove"
        }
    }

    /// Query items for this endpoint (if applicable).
    var queryItems: [URLQueryItem]? {
        switch self {
        case .listModels(let category, let supportedParameters, let useRSS, let useRSSChatLinks):
            var items: [URLQueryItem] = []
            if let category {
                items.append(URLQueryItem(name: "category", value: category))
            }
            if let supportedParameters {
                items.append(URLQueryItem(name: "supported_parameters", value: supportedParameters))
            }
            if let useRSS {
                items.append(URLQueryItem(name: "use_rss", value: useRSS))
            }
            if let useRSSChatLinks {
                items.append(URLQueryItem(name: "use_rss_chat_links", value: useRSSChatLinks))
            }
            return items.isEmpty ? nil : items
        case .listKeys(let includeDisabled, let offset):
            var items: [URLQueryItem] = []
            if let includeDisabled {
                items.append(URLQueryItem(name: "include_disabled", value: String(includeDisabled)))
            }
            if let offset {
                items.append(URLQueryItem(name: "offset", value: offset))
            }
            return items.isEmpty ? nil : items
        case .listGuardrails(let offset, let limit),
             .listAllKeyAssignments(let offset, let limit),
             .listAllMemberAssignments(let offset, let limit),
             .listGuardrailKeyAssignments(_, let offset, let limit),
             .listGuardrailMemberAssignments(_, let offset, let limit):
            var items: [URLQueryItem] = []
            if let offset {
                items.append(URLQueryItem(name: "offset", value: offset))
            }
            if let limit {
                items.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            return items.isEmpty ? nil : items
        default:
            return nil
        }
    }

    /// Request body for this endpoint (if applicable).
    var body: Encodable? {
        switch self {
        case .chatCompletions(let request):
            return request
        case .createKey(let request):
            return request
        case .updateKey(_, let request):
            return request
        case .createGuardrail(let request):
            return request
        case .updateGuardrail(_, let request):
            return request
        case .assignGuardrailKeys(_, let request), .removeGuardrailKeys(_, let request):
            return request
        case .assignGuardrailMembers(_, let request), .removeGuardrailMembers(_, let request):
            return request
        default:
            return nil
        }
    }

    /// Expected HTTP status code for successful responses.
    var expectedStatusCode: Int {
        switch self {
        case .createKey, .createGuardrail:
            return 201
        default:
            return 200
        }
    }
}

/// HTTP method enumeration.
package enum HTTPMethod: String {
    case GET
    case POST
    case PATCH
    case DELETE
}
