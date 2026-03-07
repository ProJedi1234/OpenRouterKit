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
