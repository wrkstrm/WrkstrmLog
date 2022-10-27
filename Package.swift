// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "WrkstrmLog",
  platforms: [
    .iOS(.v12),
    .macOS(.v12),
    .tvOS(.v12),
    .watchOS(.v5),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to
    // other packages.
    .library(name: "Lumberjack", type: .dynamic, targets: ["Lumberjack"]),
    .library(name: "WrkstrmLog", targets: ["WrkstrmLog"]),
    .library(name: "WSMLogger", type: .dynamic, targets: ["WSMLogger"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test
    // suite. Targets can depend on other targets in this package, and on products in packages which
    // this package depends on.
    .target(name: "Lumberjack", dependencies: []),
    .target(name: "WrkstrmLog", dependencies: []),
    .target(name: "WSMLogger", dependencies: ["Lumberjack"]),
    .testTarget(name: "WrkstrmLogTests", dependencies: ["WrkstrmLog"]),
  ])
