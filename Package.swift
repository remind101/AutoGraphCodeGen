// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AutoGraphCodeGen",
    platforms: [
        // MacOS version could be lower, but swift-parsing requires 10.15. Could open an issue if this becomes a nuisance.
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "libAutoGraphCodeGen", targets: ["libAutoGraphCodeGen"]),
        .executable(name: "AutoGraphCodeGen", targets: ["AutoGraphCodeGen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/remind101/AutoGraph", from: "0.15.1"),
        .package(url: "https://github.com/remind101/AutoGraphParser", from: "0.0.3"),
        .package(url: "https://github.com/apple/swift-syntax", exact: "509.0.0"),
    ],
    targets: [
        .executableTarget(name: "AutoGraphCodeGen", dependencies: ["libAutoGraphCodeGen"]),
        .target(
            name: "libAutoGraphCodeGen",
            dependencies: [
                .product(name: "AutoGraphParser", package: "AutoGraphParser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(
            name: "libAutoGraphCodeGenTests",
            dependencies: [
                "libAutoGraphCodeGen",
                .product(name: "AutoGraphQL", package: "AutoGraph"),
            ]),
    ]
)
