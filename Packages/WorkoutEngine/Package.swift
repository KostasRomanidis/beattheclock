// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WorkoutEngine",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "WorkoutEngine", targets: ["WorkoutEngine"]),
    ],
    targets: [
        .target(name: "WorkoutEngine"),
        .testTarget(name: "WorkoutEngineTests", dependencies: ["WorkoutEngine"]),
    ]
)
