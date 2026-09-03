// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EasyRight",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EasyRightCore",
            targets: ["EasyRightCore"]
        )
    ],
    targets: [
        .target(
            name: "EasyRightCore",
            path: "Sources/EasyRight/Core"
        ),
        .testTarget(
            name: "EasyRightTests",
            dependencies: ["EasyRightCore"],
            path: "Tests",
            exclude: [
                "CaskStructureTests.sh",
                "ReleaseWorkflowStructureTests.sh"
            ]
        )
    ]
)
