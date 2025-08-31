# WrkstrmLog - Swift Logging Library

WrkstrmLog is a Swift Package Manager library providing adaptive logging across macOS, Linux, and
Xcode with support for print, OSLog, and SwiftLog styles. The library includes configurable exposure
limits and can be completely disabled for production builds.

**Always reference these instructions first and fallback to search or bash commands only when you
encounter unexpected information that does not match the info here.**

## Working Effectively

### Essential Setup Commands

Run these commands in order to bootstrap the development environment:

1. **Check Swift version and basic setup:**

   ```bash
   swift --version  # Should be Swift 6.1+
   cd /path/to/WrkstrmLog
   ```

2. **Install dependencies and describe package:**

   ```bash
   swift package resolve  # Resolves dependencies (~1 second)
   swift package describe --type json  # Shows package structure
   ```

3. **Build the library:**

   ```bash
   swift build --target WrkstrmLog  # Takes 13-16 seconds. NEVER CANCEL. Set timeout to 30+ minutes.
   ```

4. **Run tests:**

   ```bash
   swift test --enable-code-coverage --parallel --filter WrkstrmLogTests  # Takes 16 seconds. NEVER CANCEL. Set timeout to 30+ minutes.
   ```

### Linting Setup and Validation

**ALWAYS run linting before committing changes or CI will fail:**

1. **Install SwiftLint on Ubuntu/Linux:**

   ```bash
   curl -L https://github.com/realm/SwiftLint/releases/latest/download/swiftlint_linux.zip -o swiftlint_linux.zip
   unzip swiftlint_linux.zip -d swiftlint_tmp
   sudo mv swiftlint_tmp/swiftlint /usr/local/bin/
   rm -rf swiftlint_tmp swiftlint_linux.zip
   ```

2. **Download required SwiftLint configuration:**

   ```bash
   curl -O https://raw.githubusercontent.com/wrkstrm/configs/main/linting/.swiftlint.yml
   ```

3. **Run SwiftLint:**

   ```bash
   swiftlint  # Takes ~3 seconds
   ```

### Build Timing and Cancellation Warnings

- **Initial build:** 13-16 seconds. NEVER CANCEL. Set timeout to 30+ minutes.
- **Incremental builds:** 1-3 seconds
- **Full test suite:** 16 seconds. NEVER CANCEL. Set timeout to 30+ minutes.
- **SwiftLint:** 3 seconds
- **Clean build:** 13-16 seconds after `swift package clean`

## Validation and Testing

### Manual Library Validation

**ALWAYS test library functionality after making changes.** Create a test application to verify the
library works:

1. **Create test project structure:**

   ```bash
   mkdir -p /tmp/wrkstrmlog-test/Sources/WrkstrmLogTest
   cd /tmp/wrkstrmlog-test
   ```

2. **Create Package.swift:**

   ```swift
   // swift-tools-version:6.1
   import PackageDescription

   let package = Package(
       name: "WrkstrmLogTest",
       platforms: [.macOS(.v13)],
       dependencies: [
           .package(path: "/path/to/WrkstrmLog")
       ],
       targets: [
           .executableTarget(
               name: "WrkstrmLogTest",
               dependencies: ["WrkstrmLog"]
           )
       ]
   )
   ```

3. **Create test main.swift:**

   ```swift
   import WrkstrmLog

   @main
   struct TestApp {
       static func main() {
           Log.globalExposureLevel = .info
           let logger = Log(system: "TestApp", category: "Main", maxExposureLevel: .trace)

           logger.verbose("Verbose message")
           logger.info("Info message")
           logger.error("Error message")

           let silentLogger = Log.disabled
           silentLogger.info("This should not appear")

           print("✅ Test completed successfully!")
       }
   }
   ```

4. **Build and run test:**

   ```bash
   swift build  # Should build successfully
   ./.build/debug/WrkstrmLogTest  # Should output log messages and complete
   ```

### Expected Test Output

The test application should produce output similar to:

```
TestApp:Main:ℹ️ main:X|main()| Info message
TestApp:Main:❗ main:X|main()| Error message
✅ Test completed successfully!
```

## Common Tasks and Commands

### Build and Development

- **Clean build:** `swift package clean && swift build`
- **Show dependencies:** `swift package show-dependencies`
- **Run specific tests:** `swift test --filter WrkstrmLogTests`
- **Build all targets:** `swift build` (builds WrkstrmLog library by default)

### Documentation

- **Documentation generation fails** due to system permission issues but library builds successfully
- **SwiftLint configuration** comes from external wrkstrm/configs repository and must be downloaded

### CI Integration

The GitHub Actions workflows require:

- Ubuntu runners with Swift 6.1+
- SwiftLint installed via binary download
- SwiftLint configuration from wrkstrm/configs/main/linting/.swiftlint.yml
- Environment variable `SPM_CI_USE_LOCAL_DEPS=false` for CI builds

## Key Project Structure

```
WrkstrmLog/
├── Package.swift                     # Swift Package Manager definition
├── README.md                         # Comprehensive usage documentation
├── Sources/WrkstrmLog/              # Main library source code
│   ├── Log.swift                    # Core logging implementation
│   ├── Log+Shared.swift            # Shared logging utilities
│   ├── Level+Emoji.swift           # Log level emoji mappings
│   ├── Level+OSLogType.swift       # OSLog integration
│   ├── ProcessInfo+Xcode.swift     # Xcode detection utilities
│   └── Documentation.docc/         # DocC documentation
├── Tests/WrkstrmLogTests/           # Test suite
│   ├── WrkstrmLogTests.swift       # Main test cases
│   ├── LevelExtensionsTests.swift  # Level extension tests
│   ├── OSLoggerTests.swift         # OSLog specific tests
│   └── ProcessInfoXcodeTests.swift # Xcode detection tests
└── .github/workflows/               # CI configuration
    ├── wrkstrm-log-swift.yml       # Build workflow
    ├── wrkstrm-log-tests-swift.yml # Test workflow
    └── wrkstrm-log-swiftlint.yml   # Linting workflow
```

## Troubleshooting

### Common Issues

- **SwiftLint warnings/errors:** Current codebase has known linting violations. Focus on new changes
  rather than fixing existing issues.
- **Documentation generation fails:** This is expected due to system permissions. The library builds
  and functions correctly.
- **Test warnings about `#expect(true)`:** These are existing test issues and should be ignored
  unless directly related to your changes.

### Build Failures

- **Missing dependencies:** Run `swift package resolve` first
- **Permission errors:** Ensure proper write access to `.build` directory
- **SwiftLint config missing:** Download from wrkstrm/configs repository as shown above

## Critical Notes

- **Log.guard() is fatal:** Calling `Log.guard()` will crash the application with a fatal error by
  design
- **Exposure levels:** Global exposure defaults to `.critical`, libraries must opt-in to higher
  verbosity levels
- **Platform support:** Library works on macOS (.v13+) and Linux, designed for iOS (.v16+), tvOS
  (.v16+), watchOS (.v9+), visionOS (.v1+)
- **Swift 6 compatibility:** Uses `#fileID` for cleaner log output

## Dependencies

- **swift-log (1.6.0+):** Apple's Swift Logging API
- **swift-docc-plugin (1.4.0+):** Documentation generation (build dependency only)

## Performance Characteristics

- **Minimal overhead:** Disabled loggers produce no runtime cost
- **Configurable verbosity:** Global and per-logger exposure controls
- **Cross-platform:** Adapts logging style based on environment (print, OSLog, SwiftLog)
