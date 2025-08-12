# WrkstrmLog: Unifying the Symphony of Swift Logging 🎶

Managing logs across environments can be messy. WrkstrmLog provides a consistent, extensible logging API for Swift projects.

## The Challenge: Inconsistent Logs 😵‍💫

Swift code often relies on platform-specific log statements:

```swift
#if DEBUG
print("Debug: Entering function")
#endif

if let error = performOperation() {
  print("Error occurred: \(error)")
}
```

This approach leads to inconsistent behavior across environments. 🎭

## WrkstrmLog: A Consistent Approach 🎼

WrkstrmLog provides a single interface that adapts to each platform. 🌐

```swift
import WrkstrmLog

let log = Log(system: "com.myapp", category: "networking")

func someFunction() {
  log.debug("Entering someFunction")

  // application code

  if let error = performOperation() {
    log.error("Operation failed: \(error)")
  }

  log.debug("Exiting someFunction")
}
```

### Core Features and Benefits 💎

- 🎯 Unified interface
- 🌈 Flexible configuration
- 🏷️ Smart categorization
- 🔀 Multiple output styles: console, Apple's unified logging, and SwiftLog
- 🌍 Consistent behavior on Linux, macOS, and in Xcode
- 🔌 Extensibility
- 📏 Configurable global and per-logger exposure limits
- 🔇 Disabled mode for silent logging

## Getting Started 🚀

### Installation 📦

Add WrkstrmLog to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "2.0.0"))
]
```

### Basic Usage 🔰

```swift
import WrkstrmLog

let log = Log.shared
log.info("App launched")
```

## Advanced Usage and Best Practices 🎓

### Default Behavior of WrkstrmLog's Shared Logger

WrkstrmLog provides a shared logger instance (`Log.shared`) that's preconfigured for immediate use. By default:

| Environment | WrkstrmLog Style | Default Swift Logging |
|-------------|-----------------|-----------------------|
| Xcode 🖥️ | `.os` style for debug console output 🔍 | `print()` and `os.Logger` |
| macOS Terminal 💻 | `.print` style for stdout 🖨️ | `print()`; `os.Logger` is not visible |
| Linux 🐧 | `.swift` style 🐧 | `print()` only; `os.Logger` unavailable |

### Controlling Log Levels

Set a minimum level when creating a logger to filter out lower-priority messages:

```swift
let log = Log(system: "com.myapp", category: "network", level: .error)
log.info("Ignored")

Log.overrideLevel(for: log, to: .debug)
log.info("Now logged")
```

`overrideLevel` is available only in `DEBUG` builds and lets you adjust a logger's level at runtime.

## Performance Considerations ⚡

- 🌍 Cross-platform compatibility
- 🚀 Lazy evaluation of log messages
- ⚖️ Balance between flexibility and simplicity
- 🔗 Integration with existing systems
- 🎭 Environment-specific behavior handled consistently

## Next Steps 🎯

WrkstrmLog aims to provide a unified approach to logging across Swift platforms. Feedback and contributions are welcome. 🙌
