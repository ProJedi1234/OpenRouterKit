//
//  TestHelpers.swift
//  OpenRouterKit
//
//  Shared test utilities.
//

/// Whether the current platform is Darwin (macOS, iOS, etc.).
/// Used to conditionally skip URLSession streaming tests on non-Darwin platforms.
#if canImport(Darwin)
let isDarwin = true
#else
let isDarwin = false
#endif

/// Model for live integration tests. It needs tool calling and ZDR endpoints with no safety retention.
let integrationTestModel = "z-ai/glm-5.3-flash"
