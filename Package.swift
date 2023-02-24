// swift-tools-version: 5.5
import PackageDescription
import Foundation

let package = Package(
    name: "JNIKit",
    products: [
        .library(name: "JNIKit", targets: ["JNIKit"]),
    ],
    dependencies: [],
    targets: [
        .systemLibrary(name: "CAndroidLog"),
        .target(name: "CDroidJNI"),
        .target(name: "JNIKit", dependencies: [
            "CAndroidLog",
            .target(name: "CDroidJNI"),
        ]),
        .testTarget(name: "JNIKitTests", dependencies: ["JNIKit"]),
    ]
)
