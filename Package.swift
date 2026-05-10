// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "RowingKit",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
    products: [
        .library(name: "RowingProtocols", targets: ["RowingProtocols"]),
        .library(name: "RowingBLE", targets: ["RowingBLE"]),
    ],
    targets: [
        .target(name: "RowingProtocols"),
        .target(name: "RowingBLE", dependencies: ["RowingProtocols"]),
        .testTarget(name: "RowingProtocolsTests", dependencies: ["RowingProtocols"]),
        .testTarget(name: "RowingBLETests", dependencies: ["RowingBLE"]),
    ],
    swiftLanguageModes: [.v6]
)
