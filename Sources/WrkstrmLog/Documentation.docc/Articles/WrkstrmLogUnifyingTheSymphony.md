# WrkstrmLog: Unifying the Symphony of Swift Logging 🎶

This document explains the motivation and design philosophy behind WrkstrmLog.

## 1. The Challenge: Inconsistent Logs 😵‍💫

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

## 2. WrkstrmLog: A Consistent Approach 🎼

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

## 3. Core Features and Benefits 💎

- 🎯 Unified interface
- 🧩 Flexible configuration
- 🏷️ Smart categorization
- 🔀 Multiple output styles: console, Apple's unified logging, and SwiftLog
- 🌍 Consistent behavior on Linux, macOS, and in Xcode
- 🔌 Extensibility
- 📴 Disabled mode for silent logging

## 4. Getting Started 🚀

### Installation 📦

Add WrkstrmLog to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "1.1.2"))
]
```

### Basic Usage 🔰

```swift
import WrkstrmLog

let log = Log.shared
log.info("App launched")
```

## 5. Advanced Usage and Best Practices 🎓

| Environment | WrkstrmLog Style | Default Swift Logging |
|-------------|-----------------|-----------------------|
| Xcode | `.os` style for debug console output 🔍 | `print()` and `os.Logger` |
| macOS Terminal | `.print` style for stdout 🖨️ | `print()`; `os.Logger` is not visible |
| Linux | `.swift` style 🐧 | `print()` only; `os.Logger` unavailable |

## 6. Performance Considerations ⚡

- 🧠 Lazy evaluation
- 🚦 Efficient message filtering

## 7. Next Steps 🎯

WrkstrmLog aims to provide a unified approach to logging across Swift platforms. Feedback and contributions are welcome. 🙌
