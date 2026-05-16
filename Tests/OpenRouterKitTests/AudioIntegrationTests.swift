//
//  AudioIntegrationTests.swift
//  OpenRouterKitTests
//
//  Live integration tests for OpenRouter speech-to-text (gated on OPENROUTER_API_KEY).
//

import Foundation
import OpenRouterKit
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Suite(
    "Audio transcription integration",
    .enabled(if: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false)
)
struct AudioIntegrationTests {
    let client: OpenRouterClient

    init() throws {
        let apiKey = try #require(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"])

        #if canImport(FoundationNetworking)
        let session = URLSession(configuration: .default)
        #else
        let session = URLSession.shared
        #endif

        client = OpenRouterClient(
            apiKey: apiKey,
            siteURL: "https://github.com",
            siteName: "Swift OpenRouterKit Tests",
            session: session
        )
    }

    @Test func transcriptionFromBundledWAVMatchesExpectedWords() async throws {
        let wavURL = try #require(
            Bundle.module.url(forResource: "test", withExtension: "wav"),
            "Missing test.wav in bundle — add Tests/OpenRouterKitTests/Resources/test.wav and Package.swift resources."
        )
        let wavData = try Data(contentsOf: wavURL)
        let base64Audio = wavData.base64EncodedString()

        let request = AudioTranscriptionRequest(
            model: "openai/whisper-large-v3",
            inputAudio: InputAudio(data: base64Audio, format: .wav),
            language: "en",
            temperature: 0
        )

        let response = try await client.audio.createTranscription(request: request)

        let words = normalizedWordSet(from: response.text)
        let required = ["hello", "this", "is", "a", "test"]
        for word in required {
            #expect(
                words.contains(word),
                "Expected transcript to contain word '\(word)'. Transcript: \(response.text)"
            )
        }
    }

    @Test func listTranscriptionModelsReturnsResults() async throws {
        let response = try await client.models.list(
            filters: ModelsListFilters(outputModalities: [.transcription])
        )
        #expect(!response.data.isEmpty, "Expected at least one STT model from models API")
    }
}

private func normalizedWordSet(from text: String) -> Set<String> {
    let lowered = text.lowercased()
    let separators = CharacterSet.alphanumerics.inverted
    return Set(lowered.components(separatedBy: separators).filter { !$0.isEmpty })
}
