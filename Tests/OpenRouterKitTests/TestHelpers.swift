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

/// Model for live integration tests. The alias tracks the newest DeepSeek Flash, which has many ZDR
/// endpoints with no safety retention and honors `effort: .none`.
let integrationTestModel = "~deepseek/deepseek-flash-latest"
