// swift-tools-version:5.10
import Foundation
import PackageDescription

// MARK: - Foundation extensions

extension ProcessInfo {
  static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  static let profile: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Configuration Service

struct ConfigurationService {

  let swiftSettings: [SwiftSetting]

  private static let local: ConfigurationService = {
    ConfigurationService(swiftSettings: [.unsafeFlags([
      "-Xfrontend",
      "-warn-long-expression-type-checking=10",
    ]),])
  }()

  private static let remote: ConfigurationService = {
    ConfigurationService(swiftSettings: [])
  }()

  static let shared: ConfigurationService = {
    ProcessInfo.useLocalDeps ? .local : .remote
  }()
}


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
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
  ],
  targets: [
    .target(
      name: "WrkstrmLog",
      dependencies: [.product(name: "Logging", package: "swift-log")],
      swiftSettings: ConfigurationService.shared.swiftSettings),
    .testTarget(name: "WrkstrmLogTests", dependencies: ["WrkstrmLog"]),
  ])
