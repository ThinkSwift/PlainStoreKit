// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlainStoreKit",
    platforms: [
        .iOS(.v17),   // SwiftData
        .macOS(.v14)
    ],
    products: [
        .library(name: "PlainStoreKit", targets: ["PlainStoreKit"])
    ],
    targets: [
        .target(
            name: "PlainStoreKit",
            path: "Sources/PlainStoreKit"
        )
    ]
)
