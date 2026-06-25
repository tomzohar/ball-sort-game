// swift-tools-version: 6.0
import PackageDescription

// Pure game logic for Ball Sort Game — model, classic move rules, solver, generator.
// No UIKit/SwiftUI: builds and tests from the command line (`swift test`) with no Xcode,
// and is consumed by the iOS app target as a local package once Xcode is installed.
let package = Package(
    name: "BallSortCore",
    platforms: [.macOS(.v13), .iOS(.v17)], // iOS 17 floor per ADR-0001 (@Observable). macOS 13 only so the core tests run from the CLI.
    products: [
        .library(name: "BallSortCore", targets: ["BallSortCore"]),
    ],
    targets: [
        .target(name: "BallSortCore"),
        .testTarget(name: "BallSortCoreTests", dependencies: ["BallSortCore"]),
    ]
)
