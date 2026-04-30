// swift-tools-version: 6.2
// SpeakDash — voice dictation for Mac
// Operated by QuantSummit AI

import PackageDescription

let package = Package(
    name: "SpeakDash",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "SpeakDash",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ]
        ),
    ]
)
