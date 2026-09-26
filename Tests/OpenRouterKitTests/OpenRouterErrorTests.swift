//
//  OpenRouterErrorTests.swift
//  OpenRouterKit
//
//  Unit tests for OpenRouterError construction and raw response body handling.
//

import Testing
import Foundation
@testable import OpenRouterKit

@Suite("OpenRouterError")
struct OpenRouterErrorTests {

    private func makeErrorResponse(message: String, code: Int = 400) throws -> ErrorResponse {
        let json = """
        {"error":{"code":\(code),"message":"\(message)","metadata":null}}
        """
        return try JSONDecoder().decode(ErrorResponse.self, from: Data(json.utf8))
    }

    @Test func structuredErrorResponseUsesMessageAndOmitsRawBody() throws {
        let errorResponse = try makeErrorResponse(message: "Invalid API key")
        let error = OpenRouterError(
            httpStatusCode: 401,
            errorResponse: errorResponse,
            rawBody: "<html>should be ignored</html>"
        )

        #expect(error.message == "Invalid API key")
        #expect(error.rawResponseBody == nil)
        if case .invalidCredentials = error.type {
        } else {
            Issue.record("Expected .invalidCredentials, got \(error.type)")
        }
    }

    @Test func unstructuredErrorWithShortRawBody() {
        let error = OpenRouterError(
            httpStatusCode: 502,
            errorResponse: nil,
            rawBody: "<html>Bad Gateway</html>"
        )

        #expect(error.message == "Unknown error occurred")
        #expect(error.rawResponseBody == "<html>Bad Gateway</html>")
        if case .modelDown = error.type {
        } else {
            Issue.record("Expected .modelDown, got \(error.type)")
        }
    }

    @Test func unstructuredErrorWithTruncatedRawBody() {
        let longBody = String(repeating: "x", count: 1_500)
        let error = OpenRouterError(
            httpStatusCode: 500,
            errorResponse: nil,
            rawBody: longBody
        )

        #expect(error.message == "Unknown error occurred")
        #expect(error.rawResponseBody?.count == 1_001)
        #expect(error.rawResponseBody?.hasSuffix("\u{2026}") == true)
        #expect(error.rawResponseBody?.dropLast() == longBody.prefix(1_000))
        if case .unknownError(500) = error.type {
        } else {
            Issue.record("Expected .unknownError(500), got \(error.type)")
        }
    }

    @Test func unstructuredErrorWithNilRawBody() {
        let error = OpenRouterError(httpStatusCode: 503, errorResponse: nil, rawBody: nil)

        #expect(error.message == "Unknown error occurred")
        #expect(error.rawResponseBody == nil)
        if case .noAvailableProvider = error.type {
        } else {
            Issue.record("Expected .noAvailableProvider, got \(error.type)")
        }
    }

    @Test func unstructuredErrorWithEmptyRawBody() {
        let error = OpenRouterError(httpStatusCode: 503, errorResponse: nil, rawBody: "")

        #expect(error.message == "Unknown error occurred")
        #expect(error.rawResponseBody == nil)
        if case .noAvailableProvider = error.type {
        } else {
            Issue.record("Expected .noAvailableProvider, got \(error.type)")
        }
    }

    @Test func providerErrorWithObjectRawMetadataDecodes() throws {
        let json = """
        {
          "error": {
            "code": 403,
            "message": "Provider refused the request",
            "metadata": {
              "provider_name": "Anthropic",
              "provider_code": "permission_error",
              "error_type": "refusal",
              "raw": {"type": "error", "error": {"type": "permission_error", "retryable": false}},
              "attempt": 2,
              "cached": null
            }
          }
        }
        """
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: Data(json.utf8))
        let error = OpenRouterError(httpStatusCode: 403, errorResponse: errorResponse, rawBody: json)

        #expect(error.message == "Provider refused the request")
        #expect(error.rawResponseBody == nil)
        #expect(error.metadata?["provider_name"] == "Anthropic")
        #expect(error.metadata?["provider_code"] == "permission_error")
        #expect(error.metadata?["raw"] == #"{"error":{"retryable":false,"type":"permission_error"},"type":"error"}"#)
        #expect(error.metadata?["attempt"] == "2")
        #expect(error.metadata?.keys.contains("cached") == false)
    }

    @Test func moderationErrorWithArrayMetadataDecodes() throws {
        let json = """
        {
          "error": {
            "code": 403,
            "message": "Input was flagged",
            "metadata": {
              "reasons": ["harassment", "violence"],
              "flagged_input": "some text",
              "provider_name": "OpenAI",
              "model_slug": "openai/gpt-4o"
            }
          }
        }
        """
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: Data(json.utf8))
        let error = OpenRouterError(httpStatusCode: 403, errorResponse: errorResponse)

        #expect(error.message == "Input was flagged")
        #expect(error.metadata?["provider_name"] == "OpenAI")
        #expect(error.metadata?["reasons"] == #"["harassment","violence"]"#)
        #expect(error.metadata?["flagged_input"] == "some text")
    }

    @Test func statusCodeMappingRateLimited() throws {
        let errorResponse = try makeErrorResponse(message: "Too many requests", code: 429)
        let error = OpenRouterError(httpStatusCode: 429, errorResponse: errorResponse)

        if case .rateLimited = error.type {
        } else {
            Issue.record("Expected .rateLimited, got \(error.type)")
        }
        #expect(error.message == "Too many requests")
    }
}
