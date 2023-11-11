// swift-tools-version:5.9
import PackageDescription

extension SwiftSetting {
  static let profile: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

let package = Package(
  name: "WrkstrmLog",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .tvOS(.v16),
    .watchOS(.v9),
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
        .profile
      ]),
    .testTarget(name: "WrkstrmLogTests", dependencies: ["WrkstrmLog"]),
  ])
