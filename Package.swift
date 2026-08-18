// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

import class Foundation.ProcessInfo

let package = Package(
  name: "sarif",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "SARIF",
      targets: ["SARIFRecords"],
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-collections",
      .upToNextMajor(from: "1.3.0"))
  ],
  targets: [
    .target(
      name: "ImmutableJSON",
      dependencies: []
    ),
    .target(
      name: "SARIFRecords",
      dependencies: [
        .product(name: "OrderedCollections", package: "swift-collections")
      ],
      exclude: [
        "SARIFRecords.md"
      ],
    ),
    .target(
      name: "SARIFTestUtilities",
      dependencies: [],
    ),
    .testTarget(
      name: "SARIFRecordsTests",
      dependencies: [
        "ImmutableJSON",
        "SARIFRecords",
        "SARIFTestUtilities",
      ],
    ),
  ],
  swiftLanguageModes: [.v6]
)
