// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Chip8Web",
    dependencies: [
        .package(path: "../Chip8EmulatorPackage"),
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
