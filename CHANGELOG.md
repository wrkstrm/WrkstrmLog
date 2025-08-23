# Changelog

## [Unreleased]

## [2.0.0] - 2025-08-13
### Added
- Introduce a global exposure level to restrict logging output across libraries. The level
  defaults to `.critical` and must be configured at startup to enable more verbose logging.
- Provide a per-logger max exposure level defaulting to `.critical`, exposing a public
  `maxExposureLevel` for consumers to inspect.
- Clamp global exposure raises to each logger's `maxExposureLevel`, ensuring
  opt-in behavior for more verbose logging.
- Install SwiftLint on Ubuntu runners in CI to enable linting across platforms.
### Removed
- Remove `Log.removeExposureLimit` in favor of requiring explicit `globalExposureLevel` configuration.

## [1.1.2] - 2024-08-29
### Added
- Adopt Swift 6 `#fileID` identifiers for cleaner, more consistent log output across platforms.
- Lower verbose log level and update documentation to reflect the new severity.
- Improve URL initialization and path handling, adding unit tests to verify behavior.
- Introduce an immutable logger cache key with comprehensive test coverage.
- Refine linting and formatting guidance, running `swift-format` and scoping SwiftLint suppressions.
