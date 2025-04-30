// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Tuna",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Tuna", targets: ["TunaApp"]),
        .executable(name: "SyncRules", targets: ["SyncRules"]),
        .library(name: "TunaCore", targets: ["TunaCore"]),
        .library(name: "TunaUI", targets: ["TunaUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.13.0"),
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.8"),
    ],
    targets: [
        .executableTarget(
            name: "SyncRules",
            dependencies: [],
            path: "Scripts/SyncRules"
        ),
        .target(
            name: "TunaCore",
            dependencies: [],
            path: "Sources/TunaCore"
        ),
        .target(
            name: "TunaUI",
            dependencies: ["TunaCore"],
            path: "Sources/TunaUI"
        ),
        .executableTarget(
            name: "TunaApp",
            dependencies: ["TunaCore", "TunaUI"],
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
                "TunaApp",
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
                "TunaApp",
            ],
            path: "Tests/MenuBarPopoverTests"
        ),
    ]
)
