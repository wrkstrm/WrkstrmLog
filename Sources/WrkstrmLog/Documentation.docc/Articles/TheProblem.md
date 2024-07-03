# WrkstrmLog: Simplifying Logging in Swift Projects

In the world of Swift development, logging is a crucial aspect of debugging and monitoring applications. However, managing logs across different environments and configurations can quickly become complex. Enter WrkstrmLog, a flexible and extensible logging utility designed to streamline this process.

## The Problem: Logging Inconsistencies and Default Behaviors

Let's delve deeper into the inconsistencies of default logging behaviors across different environments:


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

1. Inconsistent logging across different parts of the application
2. Difficulty in filtering logs based on severity or category
3. Limited control over log output in different environments (debug, release, etc.)
4. Lack of easy integration with external logging or monitoring systems

Moreover, a significant issue with base logging frameworks is the inconsistent experience when calling from different environments:

- Command Line
- Xcode
- Linux

Each environment may handle logs differently, leading to inconsistencies in output format, log levels, and even the presence of certain log messages. This can make debugging across different platforms and environments challenging and time-consuming.

For example, consider the following scenario:

```swift
import os

let logger = Logger(subsystem: "com.example.app", category: "network")

func fetchData() {
  logger.info("Fetching data...")
  // Fetch logic here
  logger.debug("Data fetched successfully")
}
```

When run from Xcode, you might see nicely formatted logs in the console. However, when running the same code from the command line or on a Linux server, the output might be different or even missing certain log levels.

## Introducing WrkstrmLog

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

With WrkstrmLog, the logging experience remains consistent whether you're running your app from Xcode, the command line, or on a Linux server. This consistency is achieved through intelligent handling of different environments and logging backends.

## Key Features of WrkstrmLog

1. **Unified Interface**: Consistent logging across your entire project.
2. **Flexible Configuration**: Easy to set up for different environments (debug, release, etc.).
3. **Categorization**: Log messages can be categorized for easier filtering and analysis.
4. **Multiple Output Styles**: Supports console output, Apple's Unified Logging System, and Swift's logging framework.
5. **Cross-Environment Consistency**: Provides the same logging experience across Xcode, command line, and Linux environments.
6. **Extensibility**: Can be easily extended to support additional logging destinations.

### Default Behavior of WrkstrmLog's Shared Logger

WrkstrmLog provides a shared logger instance (`Log.shared`) that's preconfigured for immediate use. By default:

1. It uses the system name "wrkstrm" and category "shared".
2. The logging style is automatically selected based on the environment:

| Environment | WrkstrmLog Behavior | Default Swift Logging Behavior |
|-------------|---------------------|--------------------------------|
| Xcode | Uses `.os` style, leveraging `os.Logger`. Logs appear in the debug console, allowing you to use all of Xcode's advanced filtering features. | `print()` and `os.Logger` messages appear in the debug console. |
| macOS Terminal | Uses `.print` style. Logs are output to `stdout` using `print()`, ensuring immediate visibility. | `print()` outputs to stdout. `os.Logger` messages are not visible in the terminal by default. They can be viewed using the Console app or the `log` command-line tool. |
| Linux | Uses `.swift` style, based on Swift's `Logging` framework. Logs are consistently output, bridging the gap left by the absence of `os.Logger`. | `print()` works as expected, outputting to stdout. While `os.Logger` is not available, the Swift `Logging` framework can be used for more advanced logging capabilities. |

This smart defaulting ensures that logs are visible and consistent across all platforms without any additional configuration.

```swift
// This will work consistently across Xcode, Terminal, and Linux
Log.shared.info("Application started")
```

The key advantage of WrkstrmLog is that it provides a unified interface that adapts to each environment, ensuring that your logging code remains consistent and functional regardless of where it's running. This is particularly valuable for cross-platform Swift development, where maintaining consistent behavior across different environments can be challenging.

It's worth noting that on macOS, while `os.Logger` messages are not immediately visible in the terminal, they are captured by the system. These logs can be accessed and filtered using the Console app, which provides a powerful interface for viewing and analyzing system logs. Additionally, the `log` command-line tool can be used to access these logs from the terminal, offering flexibility for developers who prefer command-line tools.

On Linux, while `os.Logger` is not available as it's part of Apple's ecosystem, the Swift `Logging` framework provides a robust alternative. WrkstrmLog leverages this framework on Linux, ensuring that you have access to advanced logging capabilities even in non-Apple environments.

## Challenges We Overcame

Developing WrkstrmLog presented its own set of challenges:

1. **Cross-Platform Compatibility**:
   Challenge: Ensuring the logger works consistently across iOS, macOS, and other Apple platforms, as well as Linux.
   Solution: We used conditional compilation and platform-agnostic APIs where possible, with specific adaptations for each environment.

2. **Performance Optimization**:
   Challenge: Minimizing the performance impact of logging, especially in release builds.
   Solution: Implemented lazy evaluation of log messages and efficient log level filtering.

3. **Flexibility vs Simplicity**:
   Challenge: Balancing the need for a flexible system with ease of use.
   Solution: Designed a simple API that can be extended for more complex use cases.

4. **Integration with Existing Systems**:
   Challenge: Ensuring WrkstrmLog can work alongside or replace existing logging solutions.
   Solution: Provided adapters for common logging frameworks and made it easy to redirect logs to custom destinations.

5. **Environment-Specific Behavior**:
   Challenge: Maintaining consistent behavior across different development and deployment environments.
   Solution: Implemented environment detection and adaptive logging strategies to ensure uniform output regardless of the execution context.

## Using WrkstrmLog in Your Project

Here's how you can use WrkstrmLog in your Swift package:

```swift
import WrkstrmLog

struct MyNetworkManager {
  private let log = Log(system: "com.myapp.networking", category: "api")

  func fetchData() {
    log.info("Starting data fetch")

    // Fetch logic here

    if let error = fetchError {
      log.error("Data fetch failed: \(error)")
    } else {
      log.debug("Data fetch successful")
    }
  }
}
```

You can configure WrkstrmLog globally for your entire application:

```swift
Log.shared = Log(system: "com.myapp", category: "main")
Log.shared.style = .os  // Use Apple's Unified Logging System
```

## Conclusion

WrkstrmLog transforms logging from a necessary chore into a powerful tool for understanding and debugging your Swift applications. By providing a flexible, consistent, and extensible logging solution that works uniformly across all environments, it helps developers focus on writing great code rather than wrestling with log management and environmental discrepancies.

While creating WrkstrmLog had its challenges, the result is a logging utility that we believe will significantly improve the development workflow for Swift projects of all sizes, regardless of where they're run or deployed.

Stay tuned for our next post, where we'll dive deeper into advanced features and customization options in WrkstrmLog!
