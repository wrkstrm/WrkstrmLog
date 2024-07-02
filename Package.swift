// swift-tools-version:5.10
import PackageDescription

// MARK: - Package Declaration

let package = Package(
  name: "WrkstrmLog",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .macCatalyst(.v13),
    .tvOS(.v16),
    .visionOS(.v1),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "WrkstrmLog", targets: ["WrkstrmLog"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
  ],
  targets: [
    .target(
      name: "WrkstrmLog",
      dependencies: [.product(name: "Logging", package: "swift-log")],
      swiftSettings: Package.Service.inject.swiftSettings),
    .testTarget(name: "WrkstrmLogTests", dependencies: ["WrkstrmLog"]),
  ])

// PACKAGE_SERVICE_START_V1_HASH:{{CONFIG_HASH}}
import Foundation

// MARK: - Package Service

extension Package {
  public struct Service {
    public static let version = "0.0.1"

    public var swiftSettings: [SwiftSetting] = []
    var dependencies: [PackageDescription.Package.Dependency] = []

    public static let inject: Package.Service = ProcessInfo.useLocalDeps ? .local : .remote

    static var local: Package.Service = .init(swiftSettings: [.localSwiftSettings])
    static var remote: Package.Service = .init()
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let localSwiftSettings: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// PACKAGE_SERVICE_END_V1_HASH:{{CONFIG_HASH}}
