// swift-tools-version:6.1
import Foundation
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
    .library(name: "WrkstrmLog", targets: ["WrkstrmLog"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
  ],
  targets: [
    .target(
      name: "WrkstrmLog",
      dependencies: [.product(name: "Logging", package: "swift-log")],
      path: "Sources/wrkstrm-log",
      swiftSettings: Package.Inject.shared.swiftSettings
    ),
    .testTarget(
      name: "WrkstrmLogTests",
      dependencies: ["WrkstrmLog"],
      path: "Tests/wrkstrm-log-tests"
    ),
  ],
)

// MARK: - Package Service

extension Package {
  @MainActor
  public struct Inject {
    public static let version = "0.0.1"

    public var swiftSettings: [SwiftSetting] = []
    var dependencies: [PackageDescription.Package.Dependency] = []

    public static let shared: Inject = ProcessInfo.useLocalDeps ? .local : .remote

    static var local: Inject = .init(swiftSettings: [.local])
    static var remote: Inject = .init()
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
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

// PACKAGE_SERVICE_END_V0_0_1
