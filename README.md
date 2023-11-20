# 🗂️ `WrkstrmLog`

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwrkstrm%2FWrkstrmLog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/wrkstrm/WrkstrmLog)
[![Test Status][test-badge]](https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml)

---

`WrkstrmLog` is a versatile and flexible logging framework designed for consistent logging across different environments including Linux, Xcode, and macOS terminal. It adapts to various contexts, ensuring that log messages are displayed with consistent formatting regardless of the platform.

## 🔑 Key Features

- **🌐 Adaptive Logging**: Seamless logging across Linux, Xcode, and macOS terminal environments.
- **💼 Multiple Logging Styles**: Choose from print, OSLog, and SwiftLog styles.
- **🔧 Flexible and Customizable**: Extend the framework to fit specific logging requirements.
- **🚀 Easy Integration**: Quick setup with Swift Package Manager.

## Compatibility

- macOS
- Linux

## 📦 Installation

To integrate `WrkstrmLog` into your project, follow these steps:

### 🛠 Swift Package Manager

Add `WrkstrmLog` as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", .upToNextMajor(from: "0.0.0"))
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
   Use various logging methods like `verbose`, `info`, `error`, and `guard`:

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

---

[test-badge]: https://github.com/wrkstrm/WrkstrmLog/actions/workflows/wrkstrm-log-tests-swift.yml/badge.svg
