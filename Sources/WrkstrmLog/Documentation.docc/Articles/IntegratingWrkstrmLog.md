# Integrate WrkstrmLog

Learn how to adopt WrkstrmLog in a new SwiftPM target and configure log exposure, backends, and
decorators.

## Add the dependency

### Inside the mono workspace

Reference the local package so CI, sandboxes, and downstream tools stay aligned.

```swift
.package(name: "WrkstrmLog", path: "../../universal/WrkstrmLog"),

.target(
  name: "YourTarget",
  dependencies: [
    .product(name: "WrkstrmLog", package: "WrkstrmLog")
  ]
)
```

Adjust the relative path to match your package layout.

### Outside todo3

Use the published release when you consume WrkstrmLog from another repository.

```swift
.package(url: "https://github.com/wrkstrm/WrkstrmLog.git", from: "2.0.0"),
```

## Establish loggers

Centralize logger construction so call sites inherit consistent metadata and exposure ceilings.

```swift
import WrkstrmLog

enum AppLogger {
  static let core: Log = {
    var log = Log(
      system: "MyApp",
      category: "core",
      maxExposureLevel: .info,
      options: [.prod]
    )
    return log
  }()

  static let network = Log(system: "MyApp", category: "network", maxExposureLevel: .debug)
  static let storage = Log(system: "MyApp", category: "storage", maxExposureLevel: .notice)
}
```

## Configure exposure

Set the global exposure level during startup and use the per-logger `maxExposureLevel` to opt into
higher verbosity only when needed.

```swift
#if DEBUG
Log.globalExposureLevel = .debug
#else
Log.globalExposureLevel = .warning
#endif
```

In debug builds you can temporarily elevate a specific logger.

```swift
#if DEBUG
Log.overrideLevel(for: AppLogger.network, to: .trace)
#endif
```

## Select backends

WrkstrmLog defaults to OSLog on Apple platforms, SwiftLog on Linux, and print on WASM. Override the
selection when you need explicit ordering or fan-out.

```swift
Log.Inject.setBackends([.os, .swift])
Log.Inject.removeAllCustomBackends() // return to platform defaults
```

When you need a custom sink, provide concrete backend instances.

```swift
#if canImport(Foundation)
import Foundation

let fileBackend = FileLogBackend(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
var sessionLog = Log(system: "MyApp", category: "session", backends: [fileBackend])
sessionLog.decorator = Log.Decorator.JSON()
#endif
```

## Decorators and fan-out

Decorators control message formatting.

```swift
var log = AppLogger.core
log.decorator = Log.Decorator.Plain()
log.info("Hello")

log.decorator = Log.Decorator.JSON()
log.info("Hello")
```

Use `LogGroup` to deliver one call to multiple destinations.

```swift
let userLog = AppLogger.core
var auditLog = Log(system: "MyApp", category: "audit", backends: [SwiftLogBackend()])
auditLog.decorator = Log.Decorator.JSON()

let combined = LogGroup([userLog, auditLog])
combined.notice("Session started")
```

## Release readiness checklist

- Instantiate production loggers with the `.prod` option.
- Set `Log.globalExposureLevel` intentionally at startup.
- Document any runtime backend overrides so operators understand the active sinks.
- When tests mutate backend state, call `Log.Inject.removeAllCustomBackends()` or `Log.reset()` to
  avoid leaking configuration between runs.

## Troubleshooting

- **No output in release builds**: ensure the logger sets `.prod` and the global exposure level is
  at or above the message level.
- **Duplicate messages**: avoid appending backends more than once and reset injection state between
  tests.
- **WASM targets**: WASM clamps runtime selection to `.print`; supply `PrintLogBackend()` for
  Foundation-free output.

## See also

- ``Log``
- ``LogGroup``
- ``Log/Inject``
- ``Log/Decorator``
