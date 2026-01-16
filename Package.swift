// swift-tools-version: 6.0
import PackageDescription
import Foundation

let package = Package(
    name: "JNIKit",
    platforms: [.macOS(.v10_14), .iOS(.v12), .tvOS(.v12), .watchOS(.v5)],
    products: [
        .library(name: "JNIKit", targets: ["JNIKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.6.2")
    ],
    targets: [
        .target(name: "JNIKit", dependencies: [
            .product(name: "Logging", package: "swift-log")
        ]),
        .testTarget(name: "JNIKitTests", dependencies: ["JNIKit"]),
    ]
)
