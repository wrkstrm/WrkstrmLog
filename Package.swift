// swift-tools-version:5.9
import PackageDescription

let package: Package = .init(
  name: "WrkstrmLog",
  platforms: [
    .iOS(.v15),
    .macOS(.v13),
    .tvOS(.v12),
    .watchOS(.v5),
  ],
  products: [
    .library(name: "WrkstrmLog", targets: ["WrkstrmLog"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "WrkstrmLog",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
      ],
      swiftSettings: [
        .unsafeFlags([
          "-Xfrontend",
          "-warn-long-expression-type-checking=50",
        ]),
      ]),
    .testTarget(name: "WrkstrmLogTests", dependencies: ["WrkstrmLog"]),
  ])
