// swift-tools-version: 5.5
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
        .target(name: "CDroidJNI"),
        .target(name: "JNIKit", dependencies: [
            .target(name: "CDroidJNI"),
            .product(name: "Logging", package: "swift-log")
        ]),
        .testTarget(name: "JNIKitTests", dependencies: ["JNIKit"]),
    ]
)
