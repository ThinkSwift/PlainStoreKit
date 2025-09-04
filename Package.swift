import PackageDescription

let package = Package(
    name: "PlainStoreKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "PlainStoreKit", targets: ["PlainStoreKit"]),
    ],
    targets: [
        .target(name: "PlainStoreKit"),
        .testTarget(name: "PlainStoreKitTests", dependencies: ["PlainStoreKit"]),
    ]
)
