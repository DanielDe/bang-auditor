// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bang-auditor",
    dependencies: [
      .package(url: "https://github.com/apple/swift-syntax.git", .exact("0.50100.0")),
      .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "bang-auditor",
            dependencies: ["SwiftSyntax", "Rainbow"]),
        .testTarget(
            name: "bang-auditorTests",
            dependencies: ["bang-auditor"]),
    ]
)
