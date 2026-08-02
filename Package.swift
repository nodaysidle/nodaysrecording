// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "NoDaysRecord",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "NoDaysRecord", targets: ["NoDaysRecord"])
    ],
    targets: [
        .executableTarget(
            name: "NoDaysRecord",
            path: "Sources/NoDaysRecord"
        )
    ]
)
