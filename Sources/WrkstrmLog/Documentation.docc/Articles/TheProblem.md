# 📝 WrkstrmLog: Simplifying Logging in Swift Projects

###### Synopsis
Managing logs across different environments and configurations can quickly become complex. Introducing `WrkstrmLog`, a flexible and extensible logging utility designed to streamline this process.

## 🎭 The Challenge: Cross-Platform Swift Logging

In the world of Swift development, logging is a crucial aspect of debugging and monitoring applications. However, managing logs across different environments and configurations can quickly become complex. 😓

Let's consider a typical logging scenario in a Swift project:

```swift
import Foundation

func someFunction() {
  #if DEBUG
  print("Debug: Entering someFunction")
  #endif

  // Function logic here

  if let error = performOperation() {
    print("Error occurred: \(error)")
  }

  #if DEBUG
  print("Debug: Exiting someFunction")
  #endif
}
```

This approach has several drawbacks:

1. 🔀 Inconsistent logging across different parts of the application
2. 🔍 Difficulty in filtering logs based on severity or category
3. 🎛️ Limited control over log output in different environments (debug, release, etc.)
4. 🔌 Lack of easy integration with external logging or monitoring systems

Moreover, a significant issue with base logging frameworks is the inconsistent experience when calling from different environments:

- 💻 Command Line
- 🖥️ Xcode
- 🐧 Linux

Each environment may handle logs differently, leading to inconsistencies in output format, log levels, and even the presence of certain log messages. This can make debugging across different platforms and environments challenging and time-consuming.

For example, consider this scenario:

```swift
import os

let logger = Logger(subsystem: "com.example.app", category: "network")

func fetchData() {
  logger.info("Fetching data...")
  // Fetch logic here
  logger.debug("Data fetched successfully")
}
```

When run from Xcode, you might see nicely formatted logs in the console. However, when running the same code from the command line or on a Linux server, the output might be different or even missing certain log levels. 😕

## 🚀 Enter WrkstrmLog: A Swift Solution
WrkstrmLog addresses these issues by providing a unified, flexible logging interface that ensures consistency across all environments. Here's a glimpse of how it works:

```swift
import WrkstrmLog

let log = Log(system: "com.myapp", category: "networking")

func someFunction() {
  log.debug("Entering someFunction")

  // Function logic here

  if let error = performOperation() {
    log.error("Operation failed: \(error)")
  }

  log.debug("Exiting someFunction")
}
```

With WrkstrmLog, the logging experience remains consistent whether you're running your app from Xcode, the command line, or on a Linux server. This consistency is achieved through intelligent handling of different environments and logging backends. 🌟

## 💎 Core Features and Benefits
1. 🎯 **Unified Interface**: Consistent logging across your entire project.
2. 🌈 **Flexible Configuration**: Easy to set up for different environments (debug, release, etc.).
3. 🏷️ **Categorization**: Log messages can be categorized for easier filtering and analysis.
4. 🔀 **Multiple Output Styles**: Supports console output, Apple's Unified Logging System, and Swift's logging framework.
5. 🌍 **Cross-Environment Consistency**: Provides the same logging experience across Xcode, command line, and Linux environments.
6. 🧩 **Extensibility**: Can be easily extended to support additional logging destinations.

## 🏁 Getting Started

### 📦 Installation

Add the following to your `Package.swift` file:
```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "1.1.0"))
]
```

### 🔰 Basic Usage

```swift
import WrkstrmLog

let log = Log.shared
log.info("Application started")
```

## 🎓 Advanced Usage and Best Practices

### Default Behavior of WrkstrmLog's Shared Logger

WrkstrmLog provides a shared logger instance (`Log.shared`) that's preconfigured for immediate use. By default:

1. It uses the system name "wrkstrm" and category "shared".
2. The logging style is automatically selected based on the environment:

| Environment | WrkstrmLog Behavior | Default Swift Logging Behavior |
|-------------|---------------------|--------------------------------|
| Xcode 🖥️ | Uses `.os` style, leveraging `os.Logger`. Logs appear in the debug console, allowing you to use all of Xcode's advanced filtering features. | `print()` and `os.Logger` messages appear in the debug console. |
| macOS Terminal 💻 | Uses `.print` style. Logs are output to `stdout` using `print()`, ensuring immediate visibility. | `print()` outputs to stdout. `os.Logger` messages are not visible in the terminal by default. They can be viewed using the Console app or the `log` command-line tool. |
| Linux 🐧 | Uses `.swift` style, based on Swift's `Logging` framework. Logs are consistently output, bridging the gap left by the absence of `os.Logger`. | `print()` works as expected, outputting to stdout. While `os.Logger` is not available, the Swift `Logging` framework can be used for more advanced logging capabilities. |

This smart defaulting ensures that logs are visible and consistent across all platforms without any additional configuration. 🧠

On macOS, while `os.Logger` messages are not immediately visible in the terminal, they are captured by the system. These logs can be accessed and filtered using the Console app, which provides a powerful interface for viewing and analyzing system logs. Additionally, the `log` command-line tool can be used to access these logs from the terminal, offering flexibility for developers who prefer command-line tools. 🕵️‍♂️

On Linux, while `os.Logger` is not available as it's part of Apple's ecosystem, the Swift `Logging` framework provides a robust alternative. WrkstrmLog leverages this framework on Linux, ensuring that you have access to advanced logging capabilities even in non-Apple environments. 🐧💪

### Controlling Log Levels

Set a minimum level when creating a logger to filter out lower-priority messages:

```swift
let log = Log(system: "com.myapp", category: "network", level: .error)
log.info("Ignored")

Log.overrideLevel(for: log, to: .debug)
log.info("Now logged")
```

`overrideLevel` is available only in `DEBUG` builds and lets you adjust a logger's level at runtime.



## ⚡ Performance Considerations
Developing WrkstrmLog presented its own set of challenges, particularly in terms of performance:

1. **Cross-Platform Compatibility** 🌍:
   Challenge: Ensuring the logger works consistently across iOS, macOS, and other Apple platforms, as well as Linux.
   Solution: We used conditional compilation and platform-agnostic APIs where possible, with specific adaptations for each environment.

2. **Performance Optimization** 🚀:
   Challenge: Minimizing the performance impact of logging, especially in release builds.
   Solution: Implemented lazy evaluation of log messages and efficient log level filtering.

3. **Flexibility vs Simplicity** ⚖️:
   Challenge: Balancing the need for a flexible system with ease of use.
   Solution: Designed a simple API that can be extended for more complex use cases.

4. **Integration with Existing Systems** 🔗:
   Challenge: Ensuring WrkstrmLog can work alongside or replace existing logging solutions.
   Solution: Provided adapters for common logging frameworks and made it easy to redirect logs to custom destinations.

5. **Environment-Specific Behavior** 🎭:
   Challenge: Maintaining consistent behavior across different development and deployment environments.
   Solution: Implemented environment detection and adaptive logging strategies to ensure uniform output regardless of the execution context.

## 🔮 Conclusion and Next Steps
WrkstrmLog transforms logging from a necessary chore into a powerful tool for understanding and debugging your Swift applications. By providing a flexible, consistent, and extensible logging solution that works uniformly across all environments, it helps developers focus on writing great code rather than wrestling with log management and environmental discrepancies. 🚀👨‍💻👩‍💻

While creating WrkstrmLog had its challenges, the result is a logging utility that we believe will significantly improve the development workflow for Swift projects of all sizes, regardless of where they're run or deployed.

Stay tuned for our next post, where we'll dive deeper into advanced features and customization options in WrkstrmLog! 📚🔍

---

For more information, visit our [GitHub repository](https://github.com/wrkstrm/WrkstrmLog) or the [SPI site](https://swiftpackageindex.com/wrkstrm/WrkstrmLog). Happy logging! 🎉📝
