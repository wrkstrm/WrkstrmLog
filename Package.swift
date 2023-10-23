// swift-tools-version:5.8
import PackageDescription

let package = Package(
  name: "WrkstrmLog",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v12),
    .watchOS(.v5),
  ],
  products: [
    .library(name: "Lumberjack", type: .dynamic, targets: ["Lumberjack"]),
    .library(name: "WrkstrmLog", targets: ["WrkstrmLog"]),
    .library(name: "WSMLogger", type: .dynamic, targets: ["WSMLogger"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
  ],
  targets: [
    .target(name: "Lumberjack", dependencies: []),
    .target(name: "WrkstrmLog", dependencies: [
      .product(name: "Logging", package: "swift-log")
    ]),
    .target(name: "WSMLogger", dependencies: ["Lumberjack"]),
    .testTarget(name: "WrkstrmLogTests", dependencies: ["WrkstrmLog"]),
  ])
