// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NuvioTVKit",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "NuvioDomain", targets: ["NuvioDomain"]),
        .library(name: "NuvioData", targets: ["NuvioData"]),
        .library(name: "NuvioPlayback", targets: ["NuvioPlayback"]),
        .library(name: "NuvioUI", targets: ["NuvioUI"]),
        .library(name: "NuvioFeatures", targets: ["NuvioFeatures"])
    ],
    dependencies: [
        .package(path: "../../Vendor/AetherEngine")
    ],
    targets: [
        .target(name: "NuvioDomain"),
        .target(name: "NuvioData", dependencies: ["NuvioDomain"]),
        .target(
            name: "NuvioPlayback",
            dependencies: [
                "NuvioDomain",
                .product(name: "AetherEngine", package: "AetherEngine")
            ]
        ),
        .target(name: "NuvioUI", dependencies: ["NuvioDomain"]),
        .target(
            name: "NuvioFeatures",
            dependencies: ["NuvioDomain", "NuvioData", "NuvioPlayback", "NuvioUI"]
        )
    ]
)
