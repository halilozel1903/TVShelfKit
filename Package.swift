// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TVShelfKit",
    platforms: [
        .tvOS(.v18),
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "TVShelfKit", targets: ["TVShelfKit"]),
    ],
    targets: [
        .target(name: "TVShelfKit"),
        .testTarget(name: "TVShelfKitTests", dependencies: ["TVShelfKit"]),
    ]
)
