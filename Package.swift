// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "WrkstrmLog",
  platforms: [
    .iOS(.v14),
    .macOS(.v13),
    .tvOS(.v12),
    .watchOS(.v5),
  ],
  products: [
    .library(name: "WSMLogger", type: .dynamic, targets: ["WSMLogger"]),
    .library(name: "WrkstrmLog", targets: ["WrkstrmLog"]),
    .library(name: "Lumberjack", type: .dynamic, targets: ["Lumberjack"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
  ],
  targets: [
    .target(name: "Lumberjack", dependencies: []),
    .target(
      name: "WrkstrmLog",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
      ]),
    .target(name: "WSMLogger", dependencies: ["Lumberjack"]),
    .testTarget(name: "WrkstrmLogTests", dependencies: ["WrkstrmLog"]),
  ])
