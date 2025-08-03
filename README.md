# 🗂️ `WrkstrmLog`

| CI System | Status |
|-----------|--------|
| Swift Package Index | [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog) |
| GitHub Action Status | [![Lint Status][lint-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swiftlint.yml) [![Test Status][test-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml) |

---
`WrkstrmLog` is a versatile and flexible logging framework designed for consistent logging across different environments including Linux, Xcode, and macOS terminal. It adapts to various contexts, ensuring that log messages are displayed with consistent formatting regardless of the platform.

## 🔑 Key Features

- **🌐 Adaptive Logging**: Seamless logging across Linux, Xcode, and macOS terminal environments.
- **💼 Multiple Logging Styles**: Choose from print, OSLog, and SwiftLog styles.
- **🔧 Flexible and Customizable**: Extend the framework to fit specific logging requirements.
- **🚀 Easy Integration**: Quick setup with Swift Package Manager.
- **🆕 Swift 6 File IDs**: Cleaner log output using `#fileID`.

## Compatibility

- macOS
- Linux

## 📦 Installation

To integrate `WrkstrmLog` into your project, follow these steps:

### 🛠 Swift Package Manager

Add `WrkstrmLog` as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "0.1.0"))
]
```

Include `WrkstrmLog` in your target dependencies:

```swift
targets: [
    .target(name: "YourTarget", dependencies: ["WrkstrmLog"]),
]
```

## 📚 Usage

Import `WrkstrmLog` and start logging with ease:

1. **📥 Import the Library**:

   ```swift
   import WrkstrmLog
   ```

2. **🔨 Initialize Logger**:
   Create a logger instance with your system and category:

   ```swift
   let logger = Log(system: "YourSystem", category: "YourCategory")
   ```

3. **📝 Log Messages**:
   Use various logging methods like `verbose`, `info`, `error`, and `guard`.
   `verbose` logs are emitted at the debug level, making them lower
   priority than informational messages:

   ```swift
   logger.verbose("Verbose message")
   logger.info("Info message")
   logger.error("Error message")
   Log.guard("Critical error")
   ```

## 🎨 Customization

`WrkstrmLog` offers high customization capabilities. Extend or modify it to suit your project's needs, and utilize the sample formatters as a foundation for custom implementations.

## 🤝 Contributing

🌟 Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

📄 Distributed under the MIT License. See `LICENSE` for more information.

## 📬 Contact

🔗 Project Link: [https://github.com/wrkstrm/WrkstrmLog](https://github.com/wrkstrm/WrkstrmLog)

## 💖 Acknowledgments

- Developed by github.com/@rismay

[lint-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-swiftlint.yml/badge.svg
[test-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml/badge.svg

--- 

# 📝 WrkstrmLog: Unifying the Symphony of Swift Logging 🎼

## 1. 🎭 The Challenge: Taming the Wild Logs
Ever felt like your logs are speaking different languages across platforms? You're not alone! 😅

Swift developers face a common nemesis:
```swift
#if DEBUG
print("Debug: Entering function") // 👀 Only in debug? What about production?
#endif

// ... 🏗️ Your awesome code here ...

if let error = performOperation() {
  print("Error occurred: \(error)") // 😱 Errors in production, but where?
}
```

This approach is like trying to conduct an orchestra with musicians playing from different sheets! 🎻🎺🥁

## 2. 🚀 Enter WrkstrmLog: The Maestro of Swift Logging
WrkstrmLog steps in as the conductor, bringing harmony to your logging chaos. It's like having a universal translator for your logs! 🌐🗣️

```swift
import WrkstrmLog

let log = Log(system: "com.myapp", category: "networking")

func someFunction() {
  log.debug("🎬 Action! Entering someFunction")
  
  // 🏗️ Your symphony of code here
  
  if let error = performOperation() {
    log.error("🚨 Plot twist! Operation failed: \(error)")
  }
  
  log.debug("🎭 Scene end. Exiting someFunction")
}
```

## 3. 💎 Core Features and Benefits
- 🎯 **Unified Interface**: One log to rule them all!
- 🌈 **Flexible Configuration**: Dress your logs for any occasion.
- 🏷️ **Smart Categorization**: Find that needle in the haystack.
- 🔀 **Multi-Style Output**: Console, Apple's Unified Logging, Swift Logging - we speak them all!
- 🌍 **Cross-Platform Consistency**: From Xcode to Linux, we've got you covered.
- 🧩 **Extensibility**: Build your own log empire!

## 4. 🏁 Getting Started

### 📦 Installation
Add this line to your `Package.swift` and let the magic begin:
```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "0.1.0"))
]
```

### 🔰 Basic Usage
```swift
import WrkstrmLog

let log = Log.shared
log.info("🎉 App launched! Time to rock and roll!")
```

## 5. 🎓 Advanced Usage and Best Practices
WrkstrmLog is like a Swiss Army knife for logging. Here's a taste of its power:

| Environment | WrkstrmLog Magic | Default Swift (Boring) Logging |
|-------------|------------------|--------------------------------|
| Xcode | 🔍 Uses `.os` style. Debug console becomes your crystal ball. | Basic `print()` and `os.Logger` in console. |
| macOS Terminal | 🖨️ `.print` style. Logs pop right into stdout. | `print()` works, `os.Logger` plays hide and seek. |
| Linux | 🐧 `.swift` style. Bridging the gap like a boss. | `print()` only. `os.Logger` goes MIA. |

## 6. ⚡ Performance Considerations
We've turbocharged WrkstrmLog:
- 🧠 Lazy evaluation: Logs think before they speak.
- 🚦 Efficient filtering: Only the VIP logs get through.

## 7. 🔮 Conclusion and Next Steps
WrkstrmLog isn't just a logger; it's your ticket to logging nirvana. 🧘‍♂️ Say goodbye to platform-specific headaches and hello to logging bliss!

Stay tuned for our next episode: "WrkstrmLog Advanced: Turning Your Logs into Superheroes!" 🦸‍♂️📚

---

For more mind-blowing details, swing by our [GitHub repo](https://github.com/wrkstrm/WrkstrmLog) or dive deep into our [docs](https://docs.wrkstrm.com/WrkstrmLog). Happy logging! 🎉🔧
