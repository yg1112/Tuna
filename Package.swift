// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Tuna",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Tuna", targets: ["Tuna"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Tuna",
            dependencies: [],
            path: "Sources/Tuna",
            resources: [
                .process("Resources")
            ]
        )
    ]
) 