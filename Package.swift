// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HyperWhisper",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "HyperWhisper", targets: ["HyperWhisper"])
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "HyperWhisper",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio")
            ],
            path: "Sources/HyperWhisper", // Explicit path to ensure correct structure
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/HyperWhisper/Info.plist"
                ])
            ]
        )
    ]
)
