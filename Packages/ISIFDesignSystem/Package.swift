// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ISIFDesignSystem",
    platforms: [ .iOS(.v16) ],
    products: [ .library(name: "ISIFDesignSystem", targets: ["ISIFDesignSystem"]) ],
    targets: [
        .target(name: "ISIFDesignSystem", path: "Sources/ISIFDesignSystem",
                resources: [.process("Resources")]),
        .testTarget(name: "ISIFDesignSystemTests",
                    dependencies: ["ISIFDesignSystem"],
                    path: "Tests/ISIFDesignSystemTests")
    ]
)
