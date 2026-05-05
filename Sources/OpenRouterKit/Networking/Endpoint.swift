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
    case createAudioTranscription(AudioTranscriptionRequest)
    case createEmbedding(EmbeddingRequest)
    case listEmbeddingModels
    case listModels(
        category: String?,
        supportedParameters: String?,
        inputModalities: String?,
        outputModalities: String?,
        useRSS: String?,
        useRSSChatLinks: String?
    )
    case listModelsForUser
    case listKeys(includeDisabled: Bool?, offset: String?)
    case createKey(CreateAPIKeyRequest)
    case getKey(hash: String)
    case updateKey(hash: String, UpdateAPIKeyRequest)
    case deleteKey(hash: String)
    case getCurrentKey
    
    /// The HTTP method for this endpoint.
    var method: HTTPMethod {
        switch self {
        case .chatCompletions, .createAudioTranscription, .createKey, .createEmbedding:
            return .POST
        case .updateKey:
            return .PATCH
        case .deleteKey:
            return .DELETE
        case .listModels, .listModelsForUser, .listEmbeddingModels, .listKeys, .getKey, .getCurrentKey:
            return .GET
        }
    }
    
    /// The path for this endpoint.
    var path: String {
        switch self {
        case .chatCompletions:
            return "/chat/completions"
        case .createAudioTranscription:
            return "/audio/transcriptions"
        case .createEmbedding:
            return "/embeddings"
        case .listEmbeddingModels:
            return "/embeddings/models"
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
        }
    }
    
    /// Query items for this endpoint (if applicable).
    var queryItems: [URLQueryItem]? {
        switch self {
        case .listModels(let category, let supportedParameters, let inputModalities, let outputModalities, let useRSS, let useRSSChatLinks):
            var items: [URLQueryItem] = []
            if let category {
                items.append(URLQueryItem(name: "category", value: category))
            }
            if let supportedParameters {
                items.append(URLQueryItem(name: "supported_parameters", value: supportedParameters))
            }
            if let inputModalities {
                items.append(URLQueryItem(name: "input_modalities", value: inputModalities))
            }
            if let outputModalities {
                items.append(URLQueryItem(name: "output_modalities", value: outputModalities))
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
        default:
            return nil
        }
    }
    
    /// Request body for this endpoint (if applicable).
    var body: Encodable? {
        switch self {
        case .chatCompletions(let request):
            return request
        case .createAudioTranscription(let request):
            return request
        case .createEmbedding(let request):
            return request
        case .createKey(let request):
            return request
        case .updateKey(_, let request):
            return request
        default:
            return nil
        }
    }
    
    /// Expected HTTP status code for successful responses.
    var expectedStatusCode: Int {
        switch self {
        case .createKey:
            return 201
        default:
            return 200
        }
    }
}

/// HTTP method enumeration.
package enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}
