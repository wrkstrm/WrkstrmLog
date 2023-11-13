## Installation

To install `WrkstrmLog`, simply add it to your project using SPM.

## Status

[![Build Status][build-badge]](https://github.com/wrkstrm/laussat/actions/workflows/wrkstrm-log-swift.yml)
[![Test Status][test-badge]](https://github.com/wrkstrm/laussat/actions/workflows/wrkstrm-log-tests-swift.yml)

## Usage

To use `WrkstrmLog` in your project, simply import the library and start logging. The library includes four different types of logging systems, each with its own set of features and benefits.

## Customization

`WrkstrmLog` is highly customizable and can be extended or modified to fit your specific needs. The library includes a number of sample formatters that can be used as a starting point for creating custom formatters.

## Documentation

For more information about using and customizing `WrkstrmLog`, please refer to the project's wiki on GitHub.



### Introduction

# `WrkstrmLog`

- **Multiple Logging Systems**: Includes print, OSLog, Swift, and another system, each with unique features.
- **User-Friendly**: Easily integrates with projects using Swift Package Manager (SPM).

### Features

- **Three Logging Systems**: Choose from print, OSLog, and SwiftLog to best fit your project needs.
- **Ease of Use**: Simple integration into your project using Swift Package Manager (SPM).

#### Installation

##### Swift Package Manager

To integrate `WrkstrmLog` into your iOS or macOS project using SPM, add the following as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/Wrkstrm-Log.git", .upToNextMajor(from: "1.0.0"))
]
```

And then add `WrkstrmLog` to your target dependencies:

```swift
targets: [
    .target( 
        name: "YourTarget",
        dependencies: ["WrkstrmLog"])
]
```


#### Installation

To integrate `WrkstrmLog` into your project, simply add it via SPM.

#### Usage

1. **Importing the Library**:
   Begin by importing `WrkstrmLog` in the Swift file where you want to use the logging functionality.

   ```swift
   import WrkstrmLog
   ```

2. **Initialization**:
   Initialize the logger with your desired system and category:

   ```swift
   let logger = Log(system: "YourSystem", category: "YourCategory")
   ```

3. **Logging**:
   Utilize the various logging methods like `verbose`, `error`, etc., based on your requirements.

   ```swift
   logger.verbose("This is a verbose log message")
   logger.error("This is an error log message")
   ```

#### Customization

`WrkstrmLog` is built with flexibility in mind. Utilize the provided sample formatters to create custom formatters that perfectly align with your project's requirements.

### Documentation

Visit our [GitHub Wiki](https://github.com/wrkstrm/WrkstrmLog/wiki) for comprehensive information on using and customizing `WrkstrmLog`.

---

[build-badge]: https://github.com/wrkstrm/laussat/actions/workflows/wrkstrm-log-swift.yml/badge.svg
[test-badge]: https://github.com/wrkstrm/laussat/actions/workflows/wrkstrm-log-tests-swift.yml/badge.svg
