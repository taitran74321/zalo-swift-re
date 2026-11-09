// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Olaz",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Olaz",
            path: "Sources/Olaz",
            resources: [.copy("JSModules"), .copy("Resources"), .copy("HostScripts")]
        ),
        .testTarget(
            name: "OlazTests",
            dependencies: ["Olaz"],
            path: "Tests/OlazTests"
        )
    ]
)
