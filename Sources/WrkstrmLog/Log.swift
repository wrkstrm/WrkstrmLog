import Foundation
import Logging
import Dispatch

#if canImport(os)
  import os
#endif

/// A flexible and extensible logging utility supporting multiple styles and destinations for
/// logging messages.
///
/// `Log` provides a unified interface for logging across various platforms and environments. It
/// supports standard output logging,
/// OSLog (on Apple platforms), and Swift's logging framework, allowing for easy configuration and
/// usage.
///
/// Example usage:
/// ```
/// let logger = Log(system: "MyApp", category: "Networking")
/// logger.info("Network request started")
/// ```
@preconcurrency
public struct Log: Hashable, @unchecked Sendable {
  /// Enum defining different logging styles.
  public enum Style: Sendable {
    /// Print style, logs messages to standard output.
    /// Typically used for debugging in local or development environments.
    case print
    #if canImport(os)
      /// OSLog style, logs messages using Apple's Unified Logging System (OSLog).
      /// Recommended for production use on Apple platforms for detailed and performant logging.
      case os
    #endif  // canImport(os)
    /// Swift style, logs messages using Swift's built-in logging framework (SwiftLog).
    /// Ideal for server-side Swift applications or when consistent logging behavior across
    /// platforms is desired.
    case swift

    case disabled
  }

  /// The system name for the logger. Typically represents the application or module name.
  public var system: String

  /// The category name for the logger. Used to categorize and filter log messages.
  public var category: String

  #if canImport(os)
    /// The logging style used by the logger. Defaults to `.os` on Apple platforms.
    public var style: Style = .os
  #else  // canImport(os)
    /// The logging style used by the logger. Defaults to `.swift` on non-Apple platforms.
    public var style: Style = .swift
  #endif  // canImport(os)

  /// Storage for SwiftLog loggers, keyed by `Log` instance.
  /// Access is synchronized using ``loggerQueue``.
  private nonisolated(unsafe) static var swiftLoggers: [Self: Logging.Logger] = [:]

  /// Serial queue used to synchronize access to static logger storage.
  private static let loggerQueue = DispatchQueue(label: "wrkstrm.log.logger")

  #if canImport(os)
    /// Storage for OSLog loggers, keyed by `Log` instance.
    /// Access is synchronized using ``loggerQueue``.
    private nonisolated(unsafe) static var osLoggers: [Self: OSLog] = [:]

    /// Initializes a new Log instance with the specified system, category, and style.
    ///
    /// - Parameters:
    ///   - system: The system name for the logger.
    ///   - category: The category name for the logger.
    ///   - style: The logging style used by the logger (`.print`, `.os`, `.swift`).
    ///
    /// Example:
    /// ```
    /// let networkLogger = Log(system: "MyApp", category: "Networking", style: .os)
    /// ```
    public init(
      system: String,
      category: String,
      style: Style = ProcessInfo.inXcodeEnvironment ? .os : .print,
    ) {
      self.system = system
      self.category = category
      self.style = style
    }

    public static let disabled = Log(system: "", category: "", style: .disabled)

  #else  // canImport(os)
    /// Initializes a new Log instance with the specified system, category, and style.
    ///
    /// - Parameters:
    ///   - system: The system name for the logger.
    ///   - category: The category name for the logger.
    ///   - style: The logging style used by the logger (`.print`, `.swift`).
    ///
    /// Example:
    /// ```
    /// let networkLogger = Log(system: "MyApp", category: "Networking", style: .swift)
    /// ```
    public init(system: String, category: String, style: Style = .swift) {
      self.system = system
      self.category = category
      self.style = style
    }
  #endif  // canImport(os)

  /// Maximum length for the function name in log messages.
  public var maxFunctionLength: Int?

  /// Formats the function name to fit within the specified maximum length.
  ///
  /// - Parameter function: The function name to format.
  /// - Returns: The formatted function name.
  private func formattedFunction(_ function: String) -> String {
    guard let maxLength = maxFunctionLength else {
      return function
    }
    return String(function.prefix(maxLength))
  }

  /// Logs a verbose message with the specified parameters.
  ///
  /// - Parameters:
  ///   - string: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public func verbose(
    _ describable: Any,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    guard style != .disabled else { return }
    log(
      .info,
      describable: describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a informational message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The object or string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public func info(
    _ describable: Any = "",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    guard style != .disabled else { return }
    log(
      .info,
      describable: describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs an error message with the specified parameters.
  ///
  /// - Parameters:
  ///   - string: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public func error(
    _ describable: Any,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    guard style != .disabled else { return }
    log(
      .error,
      describable: describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a critical message and triggers a fatal error.
  ///
  /// - Parameters:
  ///   - string: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  /// - Returns: Never, indicating a fatal error.
  public func `guard`(
    _ describable: Any? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) -> Never {
    guard style != .disabled else { fatalError() }
    log(
      .critical,
      describable: describable ?? "",
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
    fatalError("Guard failed: \(String(describing: describable))")
  }

  // swiftlint:disable:next function_parameter_count
  private func log(
    _ level: Logging.Logger.Level,
    describable: Any,
    file: String,
    function: String,
    line: UInt,
    column _: UInt,
    dso: UnsafeRawPointer,
  ) {
    guard style != .disabled else { return }
    let url: URL = .init(
      string:
        file
        // swiftlint:disable:next force_unwrapping
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
    )!
    let fileName = url.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    let functionString = formattedFunction(function)
    switch style {
    case .print:
      Swift
        .print(
          "\(system)::\(level.emoji) \(fileName):\(String(line))|\(functionString)| "
            + String(describing: describable))

    #if canImport(os)

      case .os:
        let logger: OSLog = Self.loggerQueue.sync {
          if let existing = Self.osLoggers[self] {
            return existing
          }
          let created = OSLog(subsystem: system, category: category)
          Self.osLoggers[self] = created
          return created
        }
        os_log(
          level.toOSType,
          dso: dso,
          log: logger,
          "%s-%i|%s| %s",
          url.lastPathComponent,
          line,
          functionString,
          String(describing: describable),
        )
    #endif  // canImport(os)

      case .swift:
        let logger: Logging.Logger = Self.loggerQueue.sync {
          if let existing = Self.swiftLoggers[self] {
            return existing
          }
          var newLogger = Logging.Logger(label: system)
          newLogger.logLevel = .debug
          Self.swiftLoggers[self] = newLogger
          return newLogger
        }
        logger.log(
        level: level,
        "\(line)|\(functionString)| \(String(describing: describable))",
        source: url.lastPathComponent,
        file: file,
        function: functionString,
        line: line,
      )

    case .disabled: break
    }
  }
}
