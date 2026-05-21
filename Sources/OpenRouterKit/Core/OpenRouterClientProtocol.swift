//
//  OpenRouterClientProtocol.swift
//  OpenRouterKit
//
//  Created by Aditya Dhar on 10/11/24.
//

import Foundation

/// Main protocol for the OpenRouter client.
///
/// Provides access to chat completions, embeddings, model information, and API key management
/// through dedicated service objects.
public protocol OpenRouterClientProtocol: Sendable {
    /// Service for chat completions.
    var chat: ChatServiceProtocol { get }

    /// Service for audio transcription operations.
    var audio: AudioServiceProtocol { get }

    /// Service for embeddings.
    var embeddings: EmbeddingsServiceProtocol { get }

    /// Service for model information.
    var models: ModelsServiceProtocol { get }

    /// Service for API key management.
    var keys: KeysServiceProtocol { get }

    /// Service for guardrail management.
    var guardrails: GuardrailsServiceProtocol { get }
}

/// Protocol for chat completion operations.
public protocol ChatServiceProtocol: Sendable {
    /// Sends a chat completion request.
    ///
    /// - Parameter request: The chat request to send
    /// - Returns: The chat response
    /// - Throws: OpenRouterError if the request fails
    func send(request: ChatRequest) async throws -> ChatResponse

    /// Streams a chat completion response.
    ///
    /// - Parameter request: The chat request to stream
    /// - Returns: An AsyncThrowingStream of String chunks
    /// - Throws: OpenRouterError if the request fails
    /// - Note: On non-Darwin platforms, throws ``OpenRouterError/streamingUnavailable``.
    ///   Use `OpenRouterKitNIO` for cross-platform streaming support.
    func stream(request: ChatRequest) async throws -> AsyncThrowingStream<String, Error>

    /// Streams a chat completion response as structured events.
    ///
    /// Unlike ``stream(request:)`` which only returns text content, this method
    /// surfaces text chunks, tool call deltas, and finish reasons as
    /// ``ChatStreamEvent`` values. Errors during streaming are propagated
    /// through the throwing stream rather than silently finishing.
    ///
    /// - Parameter request: The chat request to stream
    /// - Returns: An AsyncThrowingStream of ChatStreamEvent values
    /// - Throws: OpenRouterError if the initial request fails
    /// - Note: On non-Darwin platforms, throws ``OpenRouterError/streamingUnavailable``.
    ///   Use `OpenRouterKitNIO` for cross-platform streaming support.
    func streamEvents(request: ChatRequest) async throws -> AsyncThrowingStream<ChatStreamEvent, Error>
}

/// Protocol for audio operations.
public protocol AudioServiceProtocol: Sendable {
    /// Creates a speech-to-text transcription.
    ///
    /// - Parameter request: Audio transcription request with model and base64 input audio
    /// - Returns: Decoded transcription response
    /// - Throws: ``OpenRouterError`` if the request fails
    func createTranscription(request: AudioTranscriptionRequest) async throws -> AudioTranscriptionResponse
}

/// Protocol for model listing operations.
public protocol ModelsServiceProtocol: Sendable {
    /// Lists available models with optional filters.
    ///
    /// - Parameter filters: Optional query filters for the models endpoint
    /// - Returns: List of available models
    /// - Throws: OpenRouterError if the request fails
    func list(filters: ModelsListFilters) async throws -> ModelsListResponse

    /// Lists models available to the current user.
    ///
    /// - Returns: List of models available to the user
    /// - Throws: OpenRouterError if the request fails
    func listForUser() async throws -> ModelsListResponse
}

/// Protocol for API key management operations.
public protocol KeysServiceProtocol: Sendable {
    /// Lists API keys.
    ///
    /// - Parameters:
    ///   - includeDisabled: Whether to include disabled keys
    ///   - offset: Pagination offset
    /// - Returns: List of API keys
    /// - Throws: OpenRouterError if the request fails
    func list(includeDisabled: Bool?, offset: String?) async throws -> APIKeyListResponse

    /// Creates a new API key.
    ///
    /// - Parameter request: The API key creation request
    /// - Returns: The created API key (including the key string)
    /// - Throws: OpenRouterError if the request fails
    func create(request: CreateAPIKeyRequest) async throws -> CreateAPIKeyResponse

    /// Gets a single API key by hash.
    ///
    /// - Parameter hash: The hash identifier of the API key
    /// - Returns: The API key information
    /// - Throws: OpenRouterError if the request fails
    func get(hash: String) async throws -> APIKeyResponse

    /// Updates an API key.
    ///
    /// - Parameters:
    ///   - hash: The hash identifier of the API key
    ///   - request: The update request
    /// - Returns: The updated API key information
    /// - Throws: OpenRouterError if the request fails
    func update(hash: String, request: UpdateAPIKeyRequest) async throws -> APIKeyResponse

    /// Deletes an API key.
    ///
    /// - Parameter hash: The hash identifier of the API key
    /// - Returns: Confirmation of deletion
    /// - Throws: OpenRouterError if the request fails
    func delete(hash: String) async throws -> DeleteAPIKeyResponse

    /// Gets information about the current API key.
    ///
    /// - Returns: Current API key information
    /// - Throws: OpenRouterError if the request fails
    func getCurrent() async throws -> CurrentAPIKeyResponse
}

/// Protocol for embeddings operations.
public protocol EmbeddingsServiceProtocol: Sendable {
    /// Creates embeddings for the given request.
    ///
    /// - Parameter request: Embeddings request (model, input, optional routing and format)
    /// - Returns: Decoded embeddings response
    /// - Throws: ``OpenRouterError`` if the request fails
    func create(request: EmbeddingRequest) async throws -> EmbeddingResponse

    /// Lists models available for embeddings.
    ///
    /// - Returns: Same shape as general model listing (`data` array of ``Model``)
    /// - Throws: ``OpenRouterError`` if the request fails
    func listModels() async throws -> ModelsListResponse
}

/// Protocol for guardrail management operations.
public protocol GuardrailsServiceProtocol: Sendable {
    /// Lists guardrails with optional pagination and workspace filters.
    func list(filters: GuardrailListFilters) async throws -> GuardrailListResponse

    /// Creates a new guardrail.
    func create(request: CreateGuardrailRequest) async throws -> GuardrailResponse

    /// Gets a single guardrail by ID.
    func get(id: String) async throws -> GuardrailResponse

    /// Updates a guardrail.
    func update(id: String, request: UpdateGuardrailRequest) async throws -> GuardrailResponse

    /// Deletes a guardrail.
    func delete(id: String) async throws -> DeleteGuardrailResponse

    /// Lists all key assignments across all guardrails.
    func listAllKeyAssignments(offset: String?, limit: Int?) async throws -> GuardrailKeyAssignmentListResponse

    /// Lists key assignments for a specific guardrail.
    func listKeyAssignments(
        guardrailId: String,
        offset: String?,
        limit: Int?
    ) async throws -> GuardrailKeyAssignmentListResponse

    /// Bulk assigns keys to a guardrail.
    func assignKeys(
        guardrailId: String,
        request: GuardrailAssignKeysRequest
    ) async throws -> GuardrailAssignKeysResponse

    /// Bulk removes key assignments from a guardrail.
    func removeKeys(
        guardrailId: String,
        request: GuardrailAssignKeysRequest
    ) async throws -> GuardrailAssignKeysResponse

    /// Lists all member assignments across all guardrails.
    func listAllMemberAssignments(offset: String?, limit: Int?) async throws -> GuardrailMemberAssignmentListResponse

    /// Lists member assignments for a specific guardrail.
    func listMemberAssignments(
        guardrailId: String,
        offset: String?,
        limit: Int?
    ) async throws -> GuardrailMemberAssignmentListResponse

    /// Bulk assigns members to a guardrail.
    func assignMembers(
        guardrailId: String,
        request: GuardrailAssignMembersRequest
    ) async throws -> GuardrailAssignMembersResponse

    /// Bulk removes member assignments from a guardrail.
    func removeMembers(
        guardrailId: String,
        request: GuardrailAssignMembersRequest
    ) async throws -> GuardrailAssignMembersResponse
}
