// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Tuna",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Tuna", targets: ["Tuna"]),
        .library(name: "Views", targets: ["Views"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Tuna",
            dependencies: ["Views"],
            path: "Sources/Tuna"
        ),
        .target(
            name: "Views",
            dependencies: [],
            path: "Sources/Views"
        )
    ]
) 