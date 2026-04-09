// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WalkieTalkieServer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WalkieTalkieServer", targets: ["WalkieTalkieServer"]),
    ],
    targets: [
        .executableTarget(
            name: "WalkieTalkieServer",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
    ]
)
