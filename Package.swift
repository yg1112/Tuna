// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Tuna",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Tuna", targets: ["Tuna"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.13.0"),
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.8"),
    ],
    targets: [
        .executableTarget(
            name: "Tuna",
            dependencies: [],
            path: "Sources/Tuna",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .define("NEW_SETTINGS_UI"),
            ]
        ),
        .testTarget(
            name: "TunaTests",
            dependencies: [
                "Tuna",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "ViewInspector", package: "ViewInspector"),
            ],
            path: "Tests/TunaTests",
            resources: [
                .process("__Snapshots__"),
            ]
        ),
        .testTarget(
            name: "MenuBarPopoverTests",
            dependencies: [
                "Tuna",
            ],
            path: "Tests/MenuBarPopoverTests"
        ),
    ]
)
