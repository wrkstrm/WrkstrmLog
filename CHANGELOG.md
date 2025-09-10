# Changelog

## [Unreleased]

### Added

- Log.Inject runtime management helpers:
  - `setBackend(_:)` convenience (single-kind)
  - `setBackends(_:)` (ordered kinds; primary = index 0)
  - `appendBackend(_:)` (no-dup append)
  - `removeBackend(_:)` (kind removal; preserves order)
  - `removeAllCustomBackends()` (clear selection; revert to platform default)
- Log.Decorator:
  - `Decorator.Current` (default): preserves existing formatted body
  - `Decorator.Plain`: message-only body (no file/function/line)
  - `Decorator.JSON` (Foundation-only): JSON-encodes message + metadata keys

## [3.0.0] - TBD

### Breaking

- Rename public “style” APIs to backend/backend(s). The `Log.Style` type and
  `init(style:)` initializer are removed. Use explicit backend instances or
  arrays of backends instead. See Migration below.

### Added

- Backend-first API surface with support for multi-backend fan-out (primary =
  index 0). Injection APIs support setting an ordered list of backends.
- Soft deprecation wrappers retained for `Log.Style` and `Inject.setBackend(_:)` to
  enable incremental migration; new `Log.init(backends:)` and `Inject.setBackends(_:)` added.

### Changed

- Docs and examples updated to prefer `backend(s)` terminology and patterns.

### Removed

- `Log.Style` and `init(style:)`.
- Any remaining `style` accessors in the public API; prefer backend inspection
  helpers instead.

### Migration

- Style to backend mapping (one-to-one):
  - `init(style: .os)` → `init(backends: [OSLogBackend()])`
  - `init(style: .swift)` → `init(backends: [SwiftLogBackend()])`
  - `init(style: .print)` → `init(backends: [PrintLogBackend()])`
  - `style == .os` → `primaryBackendKind == .os`

- Injection:
  - `Log.Inject.setBackend(.os)` → `Log.Inject.setBackends([OSLogBackend()])`
  - `Log.Inject.setBackend(.swift)` → `Log.Inject.setBackends([SwiftLogBackend()])`
  - `Log.Inject.setBackend(.print)` → `Log.Inject.setBackends([PrintLogBackend()])`
  - `Log.Inject.setBackend(.auto)` → omit, or set a single default backend explicitly.

Notes:

- Multi-backend is optional; default remains a single backend with identical
  behavior to prior releases when using the platform default.

## [2.0.0] - 2025-08-13

### Added

- Introduce a global exposure level to restrict logging output across libraries. The level defaults
  to `.critical` and must be configured at startup to enable more verbose logging.
- Provide a per-logger max exposure level defaulting to `.critical`, exposing a public
  `maxExposureLevel` for consumers to inspect.
- Clamp global exposure raises to each logger's `maxExposureLevel`, ensuring opt-in behavior for
  more verbose logging.
- Install SwiftLint on Ubuntu runners in CI to enable linting across platforms.

### Removed

- Remove `Log.removeExposureLimit` in favor of requiring explicit `globalExposureLevel`
  configuration.

## [1.1.2] - 2024-08-29

### Added

- Adopt Swift 6 `#fileID` identifiers for cleaner, more consistent log output across platforms.
- Lower verbose log level and update documentation to reflect the new severity.
- Improve URL initialization and path handling, adding unit tests to verify behavior.
- Introduce an immutable logger cache key with comprehensive test coverage.
- Refine linting and formatting guidance, running `swift-format` and scoping SwiftLint suppressions.
