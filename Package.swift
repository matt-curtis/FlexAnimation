// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlexAnimation",
    platforms: [ .iOS(.v11) ],
    products: [
        .library(
            name: "FlexAnimation",
            targets: ["FlexAnimation"]
        )
    ],
    targets: [
        .target(
            name: "FlexAnimation",
            dependencies: []
        ),
        .testTarget(
            name: "FlexAnimationTests",
            dependencies: ["FlexAnimation"]
        )
    ]
)
