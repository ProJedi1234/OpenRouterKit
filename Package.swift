// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenRouterKit",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "OpenRouterKit",
            targets: ["OpenRouterKit"]),
        .library(
            name: "OpenRouterKitNIO",
            targets: ["OpenRouterKitNIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.24.0"),
    ],
    targets: [
        .target(
            name: "OpenRouterKit"),
        .target(
            name: "OpenRouterKitNIO",
            dependencies: [
                "OpenRouterKit",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]),
        .testTarget(
            name: "OpenRouterKitTests",
            dependencies: ["OpenRouterKit"]
        ),
        .testTarget(
            name: "OpenRouterKitNIOTests",
            dependencies: ["OpenRouterKitNIO"]
        ),
    ]
)
