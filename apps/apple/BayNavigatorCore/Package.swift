// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BayNavigatorCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "BayNavigatorCore",
            targets: ["BayNavigatorCore"]
        ),
    ],
    targets: [
        .target(
            name: "BayNavigatorCore",
            dependencies: [],
            path: "Sources/BayNavigatorCore"
        ),
        .testTarget(
            name: "BayNavigatorCoreTests",
            dependencies: ["BayNavigatorCore"],
            path: "Tests/BayNavigatorCoreTests"
        ),
    ]
)
