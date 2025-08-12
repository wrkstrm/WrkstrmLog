# WrkstrmLog 🗂️

| CI System | Status |
|-----------|--------|
| Swift Package Index | [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog) |
| GitHub Action Status | [![Lint Status][lint-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swiftlint.yml) [![Test Status][test-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml) |

WrkstrmLog is a logging framework for Swift that provides consistent, configurable log output across Linux, macOS, and Xcode. It offers multiple logging styles and can be completely disabled for production builds. 🔧

## ✨ Key Features

- 🌐 Adaptive logging across Linux, Xcode, and the macOS terminal
- 💼 Support for print, OSLog, and SwiftLog styles
- 🔧 Customizable to fit specific logging requirements
- 🚀 Simple integration with Swift Package Manager
- 🔕 Optional disabled mode to silence logs
- 🚦 Global exposure control via `Log.globalExposureLevel` and per-logger `maxExposureLevel` (replaces `Log.removeExposureLimit`)
- 🆕 Swift 6 `#fileID` support for concise output

## 🖥️ Compatibility

- 🍎 macOS
- 🐧 Linux

## 📦 Installation

### 🛠️ Swift Package Manager

Add WrkstrmLog as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "1.2.1"))
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

   Create a logger with your system and category. By default, each logger suppresses messages below the `.critical` level. Set a `maxExposureLevel` to allow additional levels:

   ```swift
   let logger = Log(system: "YourSystem", category: "YourCategory", maxExposureLevel: .info)
   ```

3. **Log messages** 📝

   Use the provided methods such as `debug`, `verbose`, `info`, `notice`, `warning`, `error`, and `guard`. `verbose` logs are emitted at the debug level.

   ```swift
   logger.debug("Debug message")
   logger.verbose("Verbose message")
   logger.info("Info message")
   logger.notice("Notice message")
   logger.warning("Warning message")
   logger.error("Error message")
   Log.guard("Critical error")
   ```

   Each level maps to a visual emoji for quick scanning:

   | Level    | Emoji |
   |----------|:-----:|
   | trace    | 🔍 |
   | debug    | 🐞 |
   | info     | ℹ️ |
   | notice   | 📝 |
   | warning  | ⚠️ |
   | error    | ❗ |
   | critical | 🚨 |

4. **Disable or enable logging in production** 🔇

   Loggers default to `.disabled` in release builds. Use the `.prod` option to keep them active or the `.disabled` style for a silent logger.

   ```swift
   let silent = Log.disabled
   let active = Log(style: .swift, options: [.prod])
   ```

5. **Control log level** 🎚️

   Set a minimum log level when creating a logger. Messages below this level are ignored. In `DEBUG` builds, you can temporarily override a logger's level:

   ```swift
   var logger = Log(system: "YourSystem", category: "Networking", level: .error)
   logger.info("Ignored")

   Log.overrideLevel(for: logger, to: .debug)
   logger.info("Logged")
   ```

6. **Limit log exposure** 🚦

   Logging is suppressed to `.critical` messages by default. Set a global minimum level during application startup to expose additional logs. The global setting is clamped by each logger's `maxExposureLevel`, requiring libraries to opt in before emitting more verbose messages:

   ```swift
   Log.globalExposureLevel = .warning
   
   // Inspect how far this logger is willing to expose messages
   print(logger.maxExposureLevel) // .info
   if logger.maxExposureLevel >= .debug {
       print("Debug logs may be exposed")
   }
   ```

   The global limit is configured via `Log.globalExposureLevel`. Each logger exposes its
   opt-in ceiling through `maxExposureLevel`, ensuring verbose logs are only emitted
   when both the global and per-logger limits allow. When raising the global limit,
   compare it with each logger's `maxExposureLevel` to avoid surfacing unintended
   verbosity from loggers that opt in to higher levels. The former
   `Log.removeExposureLimit` API has been removed, making explicit configuration
   of `Log.globalExposureLevel` a required step.

## 🧩 Customization

WrkstrmLog can be extended or modified to suit project-specific needs. Use the sample formatters as a foundation for custom implementations.

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

For a narrative overview of the project's goals 🎶, see [Sources/WrkstrmLog/Documentation.docc/Articles/UnifyingTheSymphony.md](Sources/WrkstrmLog/Documentation.docc/Articles/UnifyingTheSymphony.md).

[lint-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swiftlint.yml/badge.svg
[test-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml/badge.svg
