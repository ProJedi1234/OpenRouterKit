//
//  ModelDecodingTests.swift
//  OpenRouterKit
//
//  Tests for /models decoding against vocabularies the API can extend
//

import Testing
import Foundation
@testable import OpenRouterKit

@Suite("Model Decoding Tests")
struct ModelDecodingTests {

    /// A `/models` entry shaped like the live payload, carrying values this SDK does not know.
    private static let json = """
    {
      "data": [
        {
          "id": "anthropic/claude-fable-5.1",
          "canonical_slug": "anthropic/claude-fable-5.1-20260831",
          "hugging_face_id": null,
          "name": "Anthropic: Claude Fable 5.1",
          "created": 1788285838,
          "description": "A model.",
          "context_length": 1000000,
          "architecture": {
            "modality": "text+image+file->text",
            "input_modalities": ["text", "image", "file", "hologram"],
            "output_modalities": ["text", "hologram"],
            "tokenizer": "SomeFutureTokenizer",
            "instruct_type": "some-future-instruct-type"
          },
          "pricing": {
            "prompt": "0.00001",
            "completion": "0.00005",
            "web_search": "0.01",
            "input_cache_read": "0.00000025",
            "input_cache_write": "0.0000125",
            "input_cache_write_1h": "0.00002"
          },
          "top_provider": {
            "context_length": 1000000,
            "max_completion_tokens": 128000,
            "is_moderated": true
          },
          "per_request_limits": null,
          "supported_parameters": ["max_tokens", "prediction", "some_future_parameter"]
        }
      ]
    }
    """

    @Test("Unknown vocabulary values do not fail the whole payload")
    func decodesDespiteUnknownValues() throws {
        let data = Data(Self.json.utf8)
        let response = try JSONDecoder().decode(ModelsListResponse.self, from: data)

        let model = try #require(response.data.first)
        #expect(model.id == "anthropic/claude-fable-5.1")
        #expect(model.name == "Anthropic: Claude Fable 5.1")

        // Unknown entries are dropped, known ones survive.
        #expect(model.supportedParameters == [.maxTokens, .prediction])
        #expect(model.architecture.inputModalities == [.text, .image, .file])
        #expect(model.architecture.outputModalities == [.text])

        // Unknown scalars decode to nil rather than throwing.
        #expect(model.architecture.tokenizer == nil)
        #expect(model.architecture.instructType == nil)
    }

    @Test("prediction is a recognised supported parameter")
    func decodesPredictionParameter() throws {
        #expect(Parameter(rawValue: "prediction") == .prediction)
    }

    @Test("Known vocabulary values still decode")
    func decodesKnownValues() throws {
        let json = Self.json
            .replacingOccurrences(of: "\"SomeFutureTokenizer\"", with: "\"Claude\"")
            .replacingOccurrences(of: "\"some-future-instruct-type\"", with: "\"chatml\"")
        let response = try JSONDecoder().decode(ModelsListResponse.self, from: Data(json.utf8))

        let model = try #require(response.data.first)
        #expect(model.architecture.tokenizer == .claude)
        #expect(model.architecture.instructType == .chatml)
    }
}
