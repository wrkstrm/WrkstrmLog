<div align="center">

| WrkstrmLog | Swift‑native, multi‑backend logging with decorators and exposure controls. Backends: OSLog (Apple), SwiftLog (portable), and Print (WASM‑friendly). |
| :----: | :---- |

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/wrkstrm/WrkstrmLog?style=social)](https://github.com/wrkstrm/WrkstrmLog/stargazers)

<div>
  <a href="https://wrkstrm.github.io/WrkstrmLog/documentation/wrkstrmlog/" target="_blank"><img alt="Docs" src="https://img.shields.io/badge/📖%20Docs-DocC-blue?style=for-the-badge"></a>
  <a href="#📦-installation"><img alt="Install" src="https://img.shields.io/badge/⚙️%20Install-SPM-orange?style=for-the-badge"></a>
  <a href="CHANGELOG.md" target="_blank"><img alt="Changelog" src="https://img.shields.io/badge/🧾%20Changelog-latest-success?style=for-the-badge"></a>
  <a href="#-key-features"><img alt="Features" src="https://img.shields.io/badge/📚%20Features-overview-informational?style=for-the-badge"></a>
</div>

| Workflow | Badge |
| -------------: | :----: |
| DooC | [![DocC][docc-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/deploy-docc.yml) |
| Linting | [![Format][format-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swift_format.yml) | 
| Build | [![Build][build-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swift.yml) |
| Testing | [![Tests][test-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml) |

🚦 <a href="#-usage">Quick Start</a>

</div>

> "The most effective debugging tool is still careful thought, followed by judiciously placed print
> statements." —Brian Kernighan

WrkstrmLog is a logging framework for Swift that provides consistent, configurable log output across
operating system + development environment combination. Optimal backends are selected at compile time. 
For development ease, logs are automatic in debug. For security, logs are disabled by default in release
builds unless explicitly enabled.

## ✨ Key Features

- 🌐 Adaptive logging across Linux, Xcode, macOS terminal, and WASM
- 💼 Backends: print (WASM), OSLog (Apple), SwiftLog (portable)
- 🔧 Customizable to fit specific logging requirements
- 🚀 Simple integration with Swift Package Manager
- 🔕 Optional disabled mode to silence logs
- 🚦 Global and per-logger exposure levels via `Log.globalExposureLevel` and `maxExposureLevel`
  (replaces `Log.removeExposureLimit`)
- 🆕 Swift 6 `#fileID` support for concise output

## 🔌 Multiple backends

WrkstrmLog supports one or more backends per logger. Provide a single backend or
an ordered list; when multiple are supplied the first entry (index 0) is treated
as the primary.

Examples

```swift
// Single backend
let osLog = Log(system: "App", category: "UI", backends: [OSLogBackend()])
let swiftLog = Log(system: "Srv", category: "Net", backends: [SwiftLogBackend()])

// Multi-backend fan-out; primary is index 0
let capture = /* CapturingLogBackend(...) */
let composed = Log(system: "App", category: "UI", backends: [OSLogBackend(), capture])

// Runtime selection of backend kinds is also available (see next section)
```


## ⚙️ Runtime Backend Selection

Configure the active backend “kinds” at runtime via `Log.Inject`. When multiple kinds are supplied,
index 0 is treated as the primary.

```swift
// Set an ordered list of kinds
Log.Inject.setBackends([.os, .swift])

// Convenience: set a single kind (equivalent to setBackends([.os]))
Log.Inject.setBackend(.os)

// Append/remove kinds
Log.Inject.appendBackend(.print)      // -> [.os, .swift, .print]
Log.Inject.removeBackend(.swift)      // -> [.os, .print]

// Clear custom selection; revert to platform default
Log.Inject.removeAllCustomBackends()  // macOS/iOS: [.os]; Linux: [.swift]; WASM: [.print]

// Inspect current resolution
let kinds = Log.Inject.currentBackends()  // ordered, primary = index 0
```

## 🧩 Decorators

Control message body formatting via a decorator. The default `Decorator.Current` matches the
existing format. To print only the message body without file/function/line metadata, use `Plain`:

```swift
var log = Log(system: "App", category: "UI", maxExposureLevel: .info, backends: [PrintLogBackend()])
log.decorator = Log.Decorator.Plain()
log.info("hello") // Prints: "App:UI:ℹ️ hello"

// JSON decorator: includes metadata (level, system, category, file, function, line,
// timestamp, thread) in a parsable JSON body
#if canImport(Foundation)
log.decorator = Log.Decorator.JSON()
log.info("hello")
// Prints: "App:UI:ℹ️ {\"level\":\"info\",\"message\":\"hello\",\"system\":\"App\",\"category\":\"UI\",\"file\":\"YourFile\",\"function\":\"yourFunc()\",\"line\":123}"
#endif
```

## 📡 Fan-out to Multiple Logs

Use `LogGroup` to forward the same message to multiple `Log` instances. This is handy to keep the
user-facing log as-is while also emitting a basic/plain log to another sink.

```swift
// User-facing log (default decorator)
let userLog = Log(system: "App", category: "UI", maxExposureLevel: .info, backends: [PrintLogBackend()])

// Basic log (plain body) to another sink (e.g., SwiftLog)
let basicLog = {
  var logger = Log(system: "App", category: "basic", maxExposureLevel: .info, backends: [SwiftLogBackend()])
  logger.decorator = Log.Decorator.Plain()
  return logger
}()

let both = LogGroup([userLog, basicLog])
both.info("Launching…")
```

## 🗃️ File Backend (NDJSON-friendly)

Append logs to a file as newline-delimited entries. Pair with the JSON decorator for NDJSON.

```swift
#if canImport(Foundation)
import Foundation

let fileURL = URL(fileURLWithPath: "/tmp/app.log")
let fileBackend = FileLogBackend(url: fileURL)
var fileLog = Log(system: "App", category: "file", maxExposureLevel: .info, backends: [fileBackend])
fileLog.decorator = Log.Decorator.JSON() // NDJSON lines

let both = LogGroup([userLog, fileLog])
both.info("Launching…")
#endif
```

### Session-based (timestamped) log files

Create a new timestamped file per session. Filename pattern:
`<base>-yyyyMMdd-HHmmss-UUID.log`.

```swift
#if canImport(Foundation)
import Foundation

let logsDir = URL(fileURLWithPath: NSTemporaryDirectory())
let sessionBackend = FileLogBackend(directory: logsDir, baseName: "app")
var sessionLog = Log(system: "App", category: "session", maxExposureLevel: .info, backends: [sessionBackend])
sessionLog.decorator = Log.Decorator.JSON()
sessionLog.info("Started session at \(Date())")
print("Session log at: \(sessionBackend.url.path)")
#endif
```

## 📦 Installation

### 🛠️ Swift Package Manager

Add WrkstrmLog as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .from: "2.0.0")
]
```

Include WrkstrmLog in your target dependencies:

```swift
targets: [
    .target(name: "YourTarget", dependencies: ["WrkstrmLog"]),
]
```

## 🚀 Usage

1. **Import the library** 📥

   ```swift
   import WrkstrmLog
   ```

2. **Initialize a logger** ⚙️

   Create a logger with your system and category. By default, each logger suppresses messages below
   the `.critical` level. Set a `maxExposureLevel` to allow additional levels:

   ```swift
   let logger = Log(system: "YourSystem", category: "YourCategory", maxExposureLevel: .info)
   ```

3. **Log messages** 📝

   Use the provided methods such as `debug`, `verbose`, `info`, `notice`, `warning`, `error`, and
   `guard`. `verbose` logs are emitted at the debug level.

   ```swift
   logger.debug("Debug message")
   logger.verbose("Verbose message")
   logger.info("Info message")
   logger.notice("Notice message")
   logger.warning("Warning message")
   logger.error("Error message")
   Log.guard("Critical error")
   ```

## 🏁 Flagship + Docs

WrkstrmLog is a flagship library. We treat it as a reference for logging APIs, observability
patterns, and documentation quality. DocC articles are being added; in the meantime, this README
serves as the primary guide.

Each level maps to a visual emoji for quick scanning:

| Level    | Emoji |
| -------- | :---: |
| trace    |  🔍   |
| debug    |  🐞   |
| info     |  ℹ️   |
| notice   |  📝   |
| warning  |  ⚠️   |
| error    |  ❗   |
| critical |  🚨   |

Each log level represents a different severity and use case. `verbose` messages map to the
`debug` level and are emitted at the same severity.

**trace** captures extremely fine-grained details such as function entry, exit, or loop
iterations—useful for deep troubleshooting during development but rarely enabled in production.

**debug** records diagnostic information like configuration values or request payloads. Enable it
when investigating issues or verifying behavior.

**info** notes general events in the application lifecycle, such as successful network calls or
completed tasks. These messages are useful for understanding normal operation.

**notice** highlights notable events that aren't errors or warnings, like a user signing in or a
cache refresh. They call attention without implying a problem.

**warning** flags potential issues that might require attention, such as retrying a request or
using a deprecated API.

**error** indicates a failure in an operation that the app can often recover from, for example a
failed save that triggers a retry.

**critical** signals serious problems that usually halt execution or result in data loss and
should be addressed immediately.

4. **Disable or enable logging in production** 🔇

   Loggers default to `.disabled` in release builds. Use the `.prod` option to keep them active or
   the `.disabled` style for a silent logger.

   ```swift
   let active = Log(system: "YourSystem", category: "YourCategory", options: [.prod])
   ```

5. **Control log level** 🎚️

   Set a minimum log level when creating a logger. Messages below this level are ignored. In `DEBUG`
   builds, you can temporarily override a logger's level:

   ```swift
   var logger = Log(system: "YourSystem", category: "Networking", level: .error)
   logger.info("Ignored")

   Log.overrideLevel(for: logger, to: .debug)
   logger.info("Logged")
   ```

6. **Limit log exposure** 🚦

   Logging is suppressed to `.critical` messages by default. Set the global exposure level during
   application startup to expose additional logs. The global level is clamped by each logger's
   `maxExposureLevel`, requiring libraries to opt in before emitting more verbose messages:

   ```swift
   Log.globalExposureLevel = .warning

   // Inspect how far this logger is willing to expose messages
   print(logger.maxExposureLevel) // .info
   if logger.maxExposureLevel >= .debug {
       print("Debug logs may be exposed")
   }
   ```

   The global level is configured via `Log.globalExposureLevel`. Each logger exposes its opt-in
   ceiling through `maxExposureLevel`, ensuring verbose logs are only emitted when both the global
   and per-logger levels allow. When raising the global level, compare it with each logger's
   `maxExposureLevel` to avoid surfacing unintended verbosity from loggers that opt in to higher
   levels. The former `Log.removeExposureLimit` API has been removed, making explicit configuration
   of `Log.globalExposureLevel` a required step.

## 🕸️ WASM targeting

- Backend selection is compile-time; on WASM (`#if os(WASI) || arch(wasm32)`) WrkstrmLog uses a
  print-based backend with no Foundation/OSLog/Dispatch dependencies.
- The logging API surface (trace, debug, info, notice, warning, error, critical/guard) is identical
  across platforms.
- Build example (requires a Swift toolchain with WASI support):

  ```bash
  swift build --target WrkstrmLog --triple wasm32-unknown-wasi -c release
  ```

- Notes:
  - On macOS, Xcode/Swift may write caches to `~/Library` during resolution/build. If running in a
    sandbox that blocks this, run the build outside the sandbox or allow SwiftPM caches.
  - No Foundation or OSLog is linked on WASM; output is emitted via `print` in a stable one-line
    format suitable for console capture.

## 🧩 Customization

WrkstrmLog can be extended or modified to suit project-specific needs. Use the sample formatters as
a foundation for custom implementations.

## 🤝 Contributing

Contributions are welcome.

1. Fork the project 🍴
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request 🚀

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.

## 📬 Contact

Project link: [https://github.com/wrkstrm/WrkstrmLog](https://github.com/wrkstrm/WrkstrmLog)

## 🙏 Acknowledgments

Developed by [rismay](https://github.com/rismay)

For a narrative overview of the project's goals 🎶, see
[Sources/WrkstrmLog/Documentation.docc/Articles/UnifyingTheSymphony.md](Sources/WrkstrmLog/Documentation.docc/Articles/UnifyingTheSymphony.md).

[build-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swift.yml/badge.svg
[format-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swift_format.yml/badge.svg
[test-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml/badge.svg
[docc-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/deploy-docc.yml/badge.svg
