// swift-tools-version: 6.1
import PackageDescription
import Foundation

let package = Package(
    name: "JNIKit",
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
