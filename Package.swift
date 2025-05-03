// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tuna_v1",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "TunaApp",
            targets: ["TunaApp"]
        ),
        .executable(
            name: "SyncRules",
            targets: ["SyncRules"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.15.1"),
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.9"),
    ],
    targets: [
        .target(
            name: "TunaTypes",
            dependencies: [],
            exclude: ["Legacy"],
        ),
        .target(
            name: "TunaAudio",
            dependencies: [
                "TunaTypes",
            ],
            exclude: ["Legacy"],
        ),
        .target(
            name: "TunaSpeech",
            dependencies: ["TunaTypes"],
            exclude: ["Legacy"],
        ),
        .target(
            name: "TunaCore",
            dependencies: [
                "TunaTypes",
                "TunaAudio",
                "TunaSpeech",
            ],
            exclude: ["Legacy"],
            swiftSettings: [
                .define("TUNACORE_LIBRARY"),
            ]
        ),
        .target(
            name: "TunaUI",
            dependencies: ["TunaTypes"],
            exclude: ["Legacy"],
        ),
        .executableTarget(
            name: "TunaApp",
            dependencies: [
                "TunaTypes",
                "TunaCore",
                "TunaAudio",
                "TunaSpeech",
                "TunaUI",
            ],
            path: "Sources/Tuna",
            exclude: ["../TunaUI/Legacy"],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .define("NEW_SETTINGS_UI"),
            ]
        ),
        .executableTarget(
            name: "SyncRules",
            dependencies: [],
            path: "Scripts/SyncRules"
        ),
        .testTarget(
            name: "TunaTests",
            dependencies: [
                "TunaTypes",
                "TunaCore",
                "TunaAudio",
                "TunaSpeech",
                "TunaUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "ViewInspector", package: "ViewInspector"),
            ],
            path: "Tests/TunaTests",
            resources: [
                .process("__Snapshots__"),
            ]
        ),
    ]
)
