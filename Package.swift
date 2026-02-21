// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Chip8Web",
    dependencies: [
        .package(url: "https://github.com/ryanggrey/Chip8EmulatorPackage.git", from: "0.0.14"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.20.0"),
    ],
    targets: [
        .executableTarget(
            name: "Chip8Web",
            dependencies: [
                .product(name: "Chip8Emulator", package: "Chip8EmulatorPackage"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Sources"
        ),
    ]
)
