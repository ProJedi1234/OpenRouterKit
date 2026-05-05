//
//  AudioTests.swift
//  OpenRouterKitTests
//
//  Unit tests for audio request encoding, response decoding, and routing.
//

import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Audio API unit tests")
struct AudioTests {

    @Test("Audio transcription request encodes OpenRouter JSON shape")
    func transcriptionRequestEncoding() throws {
        let request = AudioTranscriptionRequest(
            model: "openai/whisper-1",
            inputAudio: InputAudio(data: "UklGRiQA", format: .wav),
            language: "en",
            temperature: 0.2,
            provider: AudioProviderOptions(options: [
                "groq": [
                    "prompt": .string("Expected vocabulary: OpenRouter")
                ]
            ])
        )

        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["model"] as? String == "openai/whisper-1")
        #expect(json["language"] as? String == "en")
        #expect(json["temperature"] as? Double == 0.2)

        let inputAudio = try #require(json["input_audio"] as? [String: Any])
        #expect(inputAudio["data"] as? String == "UklGRiQA")
        #expect(inputAudio["format"] as? String == "wav")

        let provider = try #require(json["provider"] as? [String: Any])
        let options = try #require(provider["options"] as? [String: Any])
        let groq = try #require(options["groq"] as? [String: Any])
        #expect(groq["prompt"] as? String == "Expected vocabulary: OpenRouter")
    }

    @Test("Audio transcription response decodes text and usage")
    func transcriptionResponseDecoding() throws {
        let jsonString = """
        {
          "text": "Hello, this is a test.",
          "usage": {
            "seconds": 9.2,
            "total_tokens": 113,
            "input_tokens": 83,
            "output_tokens": 30,
            "cost": 0.000508
          }
        }
        """

        let data = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(AudioTranscriptionResponse.self, from: data)

        #expect(response.text == "Hello, this is a test.")
        let usage = try #require(response.usage)
        #expect(usage.seconds == 9.2)
        #expect(usage.totalTokens == 113)
        #expect(usage.inputTokens == 83)
        #expect(usage.outputTokens == 30)
        #expect(usage.cost == 0.000508)
    }

    @Test("Chat request encodes audio input and audio output configuration")
    func chatAudioEncoding() throws {
        let request = ChatRequest(
            messages: [
                Message(
                    role: .user,
                    content: .contentParts([
                        .text(TextContent(text: "Transcribe this audio.")),
                        .inputAudio(InputAudioContentPart(inputAudio: InputAudio(data: "UklGRiQA", format: .wav)))
                    ])
                )
            ],
            model: "openai/gpt-audio",
            stream: true,
            modalities: [.text, .audio],
            audio: ChatAudioConfiguration(voice: "alloy", format: .wav)
        )

        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["model"] as? String == "openai/gpt-audio")
        #expect(json["stream"] as? Bool == true)
        #expect(json["modalities"] as? [String] == ["text", "audio"])

        let audio = try #require(json["audio"] as? [String: Any])
        #expect(audio["voice"] as? String == "alloy")
        #expect(audio["format"] as? String == "wav")

        let messages = try #require(json["messages"] as? [[String: Any]])
        let content = try #require(messages[0]["content"] as? [[String: Any]])
        #expect(content[0]["type"] as? String == "text")
        #expect(content[0]["text"] as? String == "Transcribe this audio.")
        #expect(content[1]["type"] as? String == "input_audio")
        let inputAudio = try #require(content[1]["input_audio"] as? [String: Any])
        #expect(inputAudio["data"] as? String == "UklGRiQA")
        #expect(inputAudio["format"] as? String == "wav")
    }

    @Test("Chat response decodes non-streaming audio payload")
    func chatResponseAudioDecoding() throws {
        let jsonString = """
        {
          "id": "gen-123",
          "model": "openai/gpt-audio",
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "Hello there.",
                "audio": {
                  "id": "aud-123",
                  "data": "UklGRiQA",
                  "transcript": "Hello there.",
                  "expires_at": 1760000000
                }
              },
              "finish_reason": "stop"
            }
          ]
        }
        """

        let data = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)

        let audio = try #require(response.choices.first?.message.audio)
        #expect(audio.id == "aud-123")
        #expect(audio.data == "UklGRiQA")
        #expect(audio.transcript == "Hello there.")
        #expect(audio.expiresAt == 1_760_000_000)
    }

    @Test("RequestBuilder paths and methods for audio")
    func requestBuilderAudioEndpoint() throws {
        let builder = RequestBuilder(
            baseURL: "https://openrouter.ai/api/v1",
            apiKey: "test-key",
            siteURL: nil,
            siteName: nil
        )

        let request = try builder.build(
            .createAudioTranscription(
                AudioTranscriptionRequest(
                    model: "openai/whisper-1",
                    inputAudio: InputAudio(data: "UklGRiQA", format: .wav)
                )
            )
        )

        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://openrouter.ai/api/v1/audio/transcriptions")
        #expect(request.httpBody != nil)
    }

    @Test("Model list can filter audio and transcription modalities")
    func requestBuilderModelModalityFilters() throws {
        let builder = RequestBuilder(
            baseURL: "https://openrouter.ai/api/v1",
            apiKey: "test-key",
            siteURL: nil,
            siteName: nil
        )

        let request = try builder.build(
            .listModels(
                category: nil,
                supportedParameters: nil,
                inputModalities: "audio",
                outputModalities: "transcription",
                useRSS: nil,
                useRSSChatLinks: nil
            )
        )

        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://openrouter.ai/api/v1/models?input_modalities=audio&output_modalities=transcription")
    }
}
