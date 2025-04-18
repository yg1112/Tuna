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
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.13.0")
    ],
    targets: [
        .executableTarget(
            name: "Tuna",
            dependencies: [],
            path: "Sources/Tuna",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TunaTests",
            dependencies: [
                "Tuna",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        )
    ]
) 