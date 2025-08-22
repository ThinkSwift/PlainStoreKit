// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlainStoreKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PlainStoreKit", targets: ["PlainStoreKit"])
    ],
    targets: [
        .target(name: "PlainStoreKit"),
        .testTarget(name: "PlainStoreKitTests", dependencies: ["PlainStoreKit"], path: "Tests")
    ]
)
