## `WrkstrmLog`

`WrkstrmLog` is a versatile and flexible logging framework designed for consistent logging across different environments including Linux, Xcode, and macOS terminal. It adapts to various contexts, ensuring that log messages are displayed with consistent formatting regardless of the platform.

## Key Features

- **Adaptive Logging**: Seamless logging across Linux, Xcode, and macOS terminal environments.
- **Multiple Logging Styles**: Choose from print, OSLog, and SwiftLog styles.
- **Flexible and Customizable**: Extend the framework to fit specific logging requirements.
- **Easy Integration**: Quick setup with Swift Package Manager.

### Installation

To integrate `WrkstrmLog` into your project, simply add it via Swift Package Manager (SPM).

#### Swift Package Manager

Add `WrkstrmLog` as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "1.0.0"))
]
```

Include `WrkstrmLog` in your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["WrkstrmLog"])
]
```

### Status

#### Platforms

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog)

### Usage

Import `WrkstrmLog` and start logging with ease:

1. **Import the Library**:

   ```swift
   import WrkstrmLog
   ```

2. **Initialize Logger**:
   Create a logger instance with your system and category:

   ```swift
   let logger = Log(system: "YourSystem", category: "YourCategory")
   ```

3. **Log Messages**:
   Use various logging methods like `verbose`, `info`, `error`, and `guard`:

   ```swift
   logger.verbose("Verbose message")
   logger.info("Info message")
   logger.error("Error message")
   Log.guard("Critical error")
   ```

### Customization

`WrkstrmLog` offers high customization capabilities. Extend or modify it to suit your project's needs, and utilize the sample formatters as a foundation for custom implementations.

### Documentation

For detailed usage and customization instructions, visit the [GitHub Wiki](https://github.com/wrkstrm/WrkstrmLog/wiki).
