// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MegrumNative",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MegrumCore", targets: ["MegrumCore"]),
        .library(name: "MegrumDesign", targets: ["MegrumDesign"])
    ],
    targets: [
        .target(name: "MegrumCore"),
        .target(name: "MegrumDesign", dependencies: ["MegrumCore"]),
        .testTarget(name: "MegrumCoreTests", dependencies: ["MegrumCore"])
    ]
)
