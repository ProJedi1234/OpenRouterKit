//
//  ProviderPreferencesTests.swift
//  OpenRouterKitTests
//
//  Unit tests for provider routing preferences (only, sort, order).
//

import Foundation
import Testing
@testable import OpenRouterKit

@Suite("ProviderPreferences unit tests")
struct ProviderPreferencesTests {

    private func encodeJSON(_ prefs: ProviderPreferences) throws -> [String: Any] {
        let data = try JSONEncoder().encode(prefs)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("only encodes without order key")
    func onlyEncoding() throws {
        let json = try encodeJSON(ProviderPreferences(only: ["azure"]))
        #expect((json["only"] as? [String]) == ["azure"])
        #expect(json["order"] == nil)
    }

    @Test("sort encodes as string")
    func sortStringEncoding() throws {
        let json = try encodeJSON(ProviderPreferences(sort: .throughput))
        #expect(json["sort"] as? String == "throughput")
    }

    @Test("sort encodes as object with partition")
    func sortObjectEncoding() throws {
        let json = try encodeJSON(
            ProviderPreferences(sort: .options(by: .price, partition: .none))
        )
        let sort = try #require(json["sort"] as? [String: Any])
        #expect(sort["by"] as? String == "price")
        #expect(sort["partition"] as? String == "none")
    }

    @Test("sort object omits default model partition")
    func sortObjectOmitsDefaultPartition() throws {
        let json = try encodeJSON(
            ProviderPreferences(sort: .options(by: .latency, partition: .model))
        )
        let sort = try #require(json["sort"] as? [String: Any])
        #expect(sort["by"] as? String == "latency")
        #expect(sort["partition"] == nil)
    }

    @Test("only sort and allow_fallbacks combine")
    func combinedEncoding() throws {
        let json = try encodeJSON(
            ProviderPreferences(
                only: ["azure", "openai"],
                sort: .throughput,
                allowFallbacks: false
            )
        )
        #expect((json["only"] as? [String]) == ["azure", "openai"])
        #expect(json["sort"] as? String == "throughput")
        #expect(json["allow_fallbacks"] as? Bool == false)
        #expect(json["order"] == nil)
    }

    @Test("round-trip decode preserves only and sort")
    func roundTripDecode() throws {
        let json = """
        {
          "only": ["deepinfra", "together"],
          "sort": "latency",
          "allow_fallbacks": true
        }
        """.data(using: .utf8)!
        let prefs = try JSONDecoder().decode(ProviderPreferences.self, from: json)
        #expect(prefs.only == ["deepinfra", "together"])
        #expect(prefs.sort == .latency)
        #expect(prefs.allowFallbacks == true)
        #expect(prefs.order.isEmpty)

        let encoded = try encodeJSON(prefs)
        #expect((encoded["only"] as? [String]) == ["deepinfra", "together"])
        #expect(encoded["sort"] as? String == "latency")
        #expect(encoded["allow_fallbacks"] as? Bool == true)
    }

    @Test("round-trip decode preserves sort object")
    func roundTripSortObject() throws {
        let json = """
        {
          "sort": { "by": "throughput", "partition": "none" }
        }
        """.data(using: .utf8)!
        let prefs = try JSONDecoder().decode(ProviderPreferences.self, from: json)
        #expect(prefs.sort == .options(by: .throughput, partition: .none))

        let encoded = try encodeJSON(prefs)
        let sort = try #require(encoded["sort"] as? [String: Any])
        #expect(sort["by"] as? String == "throughput")
        #expect(sort["partition"] as? String == "none")
    }

    @Test("order allow_fallbacks and data_collection still encode")
    func orderRegressionEncoding() throws {
        let json = try encodeJSON(
            ProviderPreferences(
                order: ["openai", "azure"],
                allowFallbacks: true,
                dataCollection: .deny
            )
        )
        #expect((json["order"] as? [String]) == ["openai", "azure"])
        #expect(json["allow_fallbacks"] as? Bool == true)
        #expect(json["data_collection"] as? String == "deny")
    }

    @Test("ChatRequest encodes nested provider preferences")
    func chatRequestProviderEncoding() throws {
        let request = ChatRequest(
            messages: [Message(role: .user, content: .string("Hello"))],
            model: "meta-llama/llama-3.3-70b-instruct",
            provider: ProviderPreferences(
                only: ["deepinfra"],
                sort: .throughput,
                allowFallbacks: false
            )
        )
        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let provider = try #require(json["provider"] as? [String: Any])
        #expect((provider["only"] as? [String]) == ["deepinfra"])
        #expect(provider["sort"] as? String == "throughput")
        #expect(provider["allow_fallbacks"] as? Bool == false)
    }
}
