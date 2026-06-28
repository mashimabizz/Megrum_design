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
        .library(name: "MegrumData", targets: ["MegrumData"]),
        .library(name: "MegrumDesign", targets: ["MegrumDesign"]),
        .library(name: "MegrumApp", targets: ["MegrumApp"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "13.6.0"
        )
    ],
    targets: [
        .target(name: "MegrumCore"),
        .target(name: "MegrumData", dependencies: ["MegrumCore"]),
        .target(name: "MegrumDesign", dependencies: ["MegrumCore"]),
        .target(
            name: "MegrumApp",
            dependencies: [
                "MegrumCore",
                "MegrumData",
                "MegrumDesign",
                .product(
                    name: "GoogleMobileAds",
                    package: "swift-package-manager-google-mobile-ads",
                    condition: .when(platforms: [.iOS])
                )
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(name: "MegrumCoreTests", dependencies: ["MegrumCore"]),
        .testTarget(name: "MegrumDataTests", dependencies: ["MegrumData"]),
        .testTarget(name: "MegrumAppTests", dependencies: ["MegrumApp"])
    ]
)
