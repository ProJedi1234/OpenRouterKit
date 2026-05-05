//
//  AudioService.swift
//  OpenRouterKit
//
//  Service for audio API calls.
//

import Foundation

/// Service for audio operations.
final class AudioService: AudioServiceProtocol {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func createTranscription(request: AudioTranscriptionRequest) async throws -> AudioTranscriptionResponse {
        try await httpClient.execute(.createAudioTranscription(request), expectedStatusCode: 200)
    }
}
