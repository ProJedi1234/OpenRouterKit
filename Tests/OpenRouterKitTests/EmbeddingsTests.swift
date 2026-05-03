//
//  EmbeddingsTests.swift
//  OpenRouterKitTests
//
//  Unit tests for embeddings request encoding, response decoding, and routing.
//

import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import OpenRouterKit

@Suite("Embeddings API unit tests")
struct EmbeddingsTests {

    @Test("EmbeddingRequest encodes single string input")
    func singleStringInputEncoding() throws {
        let request = EmbeddingRequest(
            model: "openai/text-embedding-3-small",
            input: .string("The quick brown fox")
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["model"] as? String == "openai/text-embedding-3-small")
        #expect(json["input"] as? String == "The quick brown fox")
    }

    @Test("EmbeddingRequest encodes batch string input")
    func batchStringInputEncoding() throws {
        let strings = [
            "Machine learning is a subset of artificial intelligence",
            "Natural language processing enables computers to understand text"
        ]
        let request = EmbeddingRequest(
            model: "openai/text-embedding-3-small",
            input: .strings(strings)
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let input = try #require(json["input"] as? [String])
        #expect(input == strings)
    }

    @Test("EmbeddingRequest encodes multimodal content blocks")
    func multimodalInputEncoding() throws {
        let block = EmbeddingMultimodalBlock(content: [
            .text(TextContent(text: "A scenic boardwalk")),
            .image(ImageContentPart(imageURL: ImageUrl(url: "https://example.com/image.jpg", detail: nil)))
        ])
        let request = EmbeddingRequest(
            model: "openai/text-embedding-3-small",
            input: .multimodalBlocks([block]),
            encodingFormat: .float
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["encoding_format"] as? String == "float")
        let input = try #require(json["input"] as? [[String: Any]])
        #expect(input.count == 1)
        let content = try #require(input[0]["content"] as? [[String: Any]])
        #expect(content.count == 2)
        #expect(content[0]["type"] as? String == "text")
        #expect(content[0]["text"] as? String == "A scenic boardwalk")
        #expect(content[1]["type"] as? String == "image_url")
        let imageURL = try #require(content[1]["image_url"] as? [String: Any])
        #expect(imageURL["url"] as? String == "https://example.com/image.jpg")
    }

    @Test("ProviderPreferences encodes allow_fallbacks and data_collection")
    func providerPreferencesEncoding() throws {
        let prefs = ProviderPreferences(
            order: ["openai", "azure"],
            allowFallbacks: true,
            dataCollection: .deny
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(prefs)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect((json["order"] as? [String]) == ["openai", "azure"])
        #expect(json["allow_fallbacks"] as? Bool == true)
        #expect(json["data_collection"] as? String == "deny")
    }

    @Test("EmbeddingRequest encodes provider on request")
    func embeddingRequestProviderEncoding() throws {
        let request = EmbeddingRequest(
            model: "m",
            input: .string("x"),
            provider: ProviderPreferences(order: ["a"], allowFallbacks: false, dataCollection: .allow)
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let provider = try #require(json["provider"] as? [String: Any])
        #expect((provider["order"] as? [String]) == ["a"])
        #expect(provider["allow_fallbacks"] as? Bool == false)
        #expect(provider["data_collection"] as? String == "allow")
    }

    @Test("EmbeddingResponse decodes float vectors and usage")
    func floatResponseDecoding() throws {
        let jsonString = """
        {
          "object": "list",
          "model": "openai/text-embedding-3-small",
          "data": [
            {
              "object": "embedding",
              "index": 0,
              "embedding": [0.1, 0.2, 0.3]
            }
          ],
          "id": "emb-123",
          "usage": {
            "prompt_tokens": 10,
            "total_tokens": 10,
            "cost": 0.00001
          }
        }
        """
        let data = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        #expect(response.model == "openai/text-embedding-3-small")
        #expect(response.object == "list")
        #expect(response.id == "emb-123")
        #expect(response.data.count == 1)
        #expect(response.data[0].index == 0)
        #expect(response.data[0].object == "embedding")
        if case .floats(let vec) = response.data[0].embedding {
            #expect(vec == [0.1, 0.2, 0.3])
        } else {
            Issue.record("Expected float embedding")
        }
        let usage = try #require(response.usage)
        #expect(usage.promptTokens == 10)
        #expect(usage.totalTokens == 10)
        #expect(usage.cost == 0.00001)
    }

    @Test("EmbeddingResponse decodes base64 embedding string")
    func base64ResponseDecoding() throws {
        let jsonString = #"""
        {
          "object": "list",
          "model": "m",
          "data": [
            {
              "object": "embedding",
              "embedding": "YWFh"
            }
          ]
        }
        """#
        let data = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        if case .base64(let base64) = response.data[0].embedding {
            #expect(base64 == "YWFh")
        } else {
            Issue.record("Expected base64 embedding")
        }
    }

    @Test("RequestBuilder paths and methods for embeddings")
    func requestBuilderEmbeddingsEndpoints() throws {
        let builder = RequestBuilder(
            baseURL: "https://openrouter.ai/api/v1",
            apiKey: "test-key",
            siteURL: nil,
            siteName: nil
        )
        let createReq = try builder.build(.createEmbedding(EmbeddingRequest(model: "m", input: .string("hi"))))
        #expect(createReq.httpMethod == "POST")
        #expect(createReq.url?.absoluteString == "https://openrouter.ai/api/v1/embeddings")
        #expect(createReq.httpBody != nil)

        let listReq = try builder.build(.listEmbeddingModels)
        #expect(listReq.httpMethod == "GET")
        #expect(listReq.url?.absoluteString == "https://openrouter.ai/api/v1/embeddings/models")
        #expect(listReq.httpBody == nil)
    }

    @Test("EmbeddingInput round-trip: strings and multimodal")
    func embeddingInputRoundTrip() throws {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase

        let strings = EmbeddingInput.strings(["a", "b"])
        let stringsData = try enc.encode(strings)
        let stringsDecoded = try dec.decode(EmbeddingInput.self, from: stringsData)
        if case .strings(let arr) = stringsDecoded {
            #expect(arr == ["a", "b"])
        } else {
            Issue.record("Expected strings case")
        }

        let mm = EmbeddingInput.multimodalBlocks([
            EmbeddingMultimodalBlock(content: [.text(TextContent(text: "t"))])
        ])
        let mmData = try enc.encode(mm)
        let mmDecoded = try dec.decode(EmbeddingInput.self, from: mmData)
        if case .multimodalBlocks(let blocks) = mmDecoded {
            #expect(blocks.count == 1)
            if case .text(let textContent) = blocks[0].content[0] {
                #expect(textContent.text == "t")
            } else {
                Issue.record("Expected text part")
            }
        } else {
            Issue.record("Expected multimodalBlocks case")
        }
    }
}
