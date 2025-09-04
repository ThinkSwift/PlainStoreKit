// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlainStoreKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
        // Catalyst도 쓴다면: .macCatalyst(.v17) // Xcode 15.4+ 문법
    ],
    products: [
        .library(name: "PlainStoreKit", targets: ["PlainStoreKit"]),
    ],
    targets: [
        .target(name: "PlainStoreKit"),
        .testTarget(name: "PlainStoreKitTests", dependencies: ["PlainStoreKit"]),
    ]
)
