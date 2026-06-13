//
//  UsageCostTests.swift
//  OpenRouterKit
//
//  Tests for usage cost field decoding
//

import Testing
import Foundation
@testable import OpenRouterKit

@Suite("Usage Cost Field Decoding Tests")
struct UsageCostTests {

    @Test("Decodes cost, cost_details, and prompt_tokens_details")
    func decodesCostFields() throws {
        let jsonString = """
        {
          "id": "gen-test123",
          "model": "openai/gpt-4o",
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "Hello!"
              },
              "finish_reason": "stop"
            }
          ],
          "usage": {
            "prompt_tokens": 194,
            "completion_tokens": 2,
            "total_tokens": 196,
            "cost": 0.95,
            "cost_details": {
              "upstream_inference_cost": 19,
              "upstream_inference_prompt_cost": 0.000001614,
              "upstream_inference_completions_cost": 0.0000584
            },
            "prompt_tokens_details": {
              "cached_tokens": 0,
              "cache_write_tokens": 100,
              "audio_tokens": 0,
              "video_tokens": 0
            },
            "completion_tokens_details": {
              "reasoning_tokens": 0,
              "audio_tokens": 12,
              "image_tokens": 34
            }
          }
        }
        """

        let jsonData = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponse.self, from: jsonData)
        let usage = try #require(response.usage)

        #expect(usage.cost == 0.95)
        #expect(usage.cost_details?.upstream_inference_cost == 19)
        #expect(usage.cost_details?.upstream_inference_prompt_cost == 0.000001614)
        #expect(usage.cost_details?.upstream_inference_completions_cost == 0.0000584)
        #expect(usage.prompt_tokens_details?.cached_tokens == 0)
        #expect(usage.prompt_tokens_details?.cache_write_tokens == 100)
        #expect(usage.prompt_tokens_details?.audio_tokens == 0)
        #expect(usage.prompt_tokens_details?.video_tokens == 0)
        #expect(usage.completion_tokens_details?.reasoning_tokens == 0)
        #expect(usage.completion_tokens_details?.audio_tokens == 12)
        #expect(usage.completion_tokens_details?.image_tokens == 34)
    }

    @Test("Decodes usage without cost fields")
    func decodesWithoutCostFields() throws {
        let jsonString = """
        {
          "id": "gen-test456",
          "model": "test-model",
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "Response without cost fields."
              },
              "finish_reason": "stop"
            }
          ],
          "usage": {
            "prompt_tokens": 10,
            "completion_tokens": 5,
            "total_tokens": 15
          }
        }
        """

        let jsonData = try #require(jsonString.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponse.self, from: jsonData)
        let usage = try #require(response.usage)

        #expect(usage.prompt_tokens == 10)
        #expect(usage.completion_tokens == 5)
        #expect(usage.total_tokens == 15)
        #expect(usage.cost == nil)
        #expect(usage.cost_details == nil)
        #expect(usage.prompt_tokens_details == nil)
    }
}
