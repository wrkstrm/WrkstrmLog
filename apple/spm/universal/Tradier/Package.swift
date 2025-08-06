// swift-tools-version:6.1
import PackageDescription

let package = Package(
  name: "Tradier",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .macCatalyst(.v13),
    .tvOS(.v16),
    .visionOS(.v1),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "TradierQuote", targets: ["TradierQuote"])
  ],
  dependencies: [
    .package(path: "../../../../")
  ],
  targets: [
    .target(
      name: "TradierQuote",
      dependencies: ["WrkstrmLog"],
      path: "Sources/TradierQuote"
    )
  ]
)
