import Logging

#if os(Linux)
// Needed because DispatchQueue isn't Sendable on Linux
@preconcurrency import Foundation
#else  // os(Linux)
import Foundation
import os
#endif  // os(Linux)

/// A flexible and extensible logging utility that supports multiple styles and destinations for
/// logging messages.
public struct Log: Hashable {
  /// Enum defining different logging styles.
  public enum Style {
    /// Print style, logs messages to standard output.
    case print
#if canImport(os)
    /// OSLog style, logs messages using Apple's Unified Logging System (OSLog).
    case os
#endif  // canImport(os)
    /// Swift style, logs messages using Swift's built-in logging framework (SwiftLog).
    case swift
  }

  /// The shared logger instance, often used for default logging.
  public static var shared = Log(system: "wrkstrm", category: "shared") {
    didSet {
      shared.verbose("New Logger: \(shared)")
    }
  }

  /// The system name for the logger.
  public var system: String

  /// The category name for the logger.
  public var category: String

#if canImport(os)
  /// The logging style used by the logger.
  public var style: Style = .os
#else  // canImport(os)
  /// The logging style used by the logger.
  public var style: Style = .swift
#endif  // canImport(os)

  private static var swiftLoggers: [Log: Logging.Logger] = [:]

#if canImport(os)
  private static var osLoggers: [Log: OSLog] = [:]

  /// Initializes a new Log instance with the specified system, category, and style.
  ///
  /// - Parameters:
  ///   - system: The system name for the logger.
  ///   - category: The category name for the logger.
  ///   - style: The logging style used by the logger.
  public init(system: String, category: String, style: Style = .os) {
    self.system = system
    self.category = category
    self.style = style
  }

#else  // canImport(os)
  /// Initializes a new Log instance with the specified system, category, and style.
  ///
  /// - Parameters:
  ///   - system: The system name for the logger.
  ///   - category: The category name for the logger.
  ///   - style: The logging style used by the logger.
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
  public static func verbose(
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle)
  {
    log(
      .info, emoji: "ℹ️", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
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
  public static func error(
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle)
  {
    log(
      .error, emoji: "⚠️", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
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
  public static func `guard`(
    _ string: String = "",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle) -> Never
  {
    log(
      .critical, emoji: "❌", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
    fatalError()
  }

  // swiftlint:disable:next function_parameter_count
  private static func log(
    _ level: Logging.Logger.Level,
    emoji: String,
    string: String,
    file: String,
    function: String,
    line: UInt,
    column: UInt,
    dso: UnsafeRawPointer)
  {
    Log.shared.log(
      level, emoji: emoji, string: string, file: file, function: function, line: line,
      column: column, dso: dso)
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
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle)
  {
    log(
      .info, emoji: "ℹ️", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
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
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle)
  {
    log(
      .error, emoji: "⚠️", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
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
    _ string: String = "",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle) -> Never
  {
    log(
      .critical, emoji: "❌", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
    fatalError()
  }

  // swiftlint:disable:next function_parameter_count
  private func log(
    _ level: Logging.Logger.Level,
    emoji: String,
    string: String,
    file: String,
    function: String,
    line: UInt,
    column _: UInt,
    dso: UnsafeRawPointer)
  {
    let url: URL = .init(
      string:
      file
        // swiftlint:disable:next force_unwrapping
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    let fileName = url.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    let functionString = formattedFunction(function)
    switch style {
      case .print:
        Swift.print("\(system)::\(emoji) \(fileName):\(String(line))|\(functionString)| " + string)

#if canImport(os)

      case .os:
        let logger = Self.osLoggers[
          self, default: OSLog(subsystem: system, category: category)
        ]
        os_log(
          level.toOSType,
          dso: dso,
          log: logger,
          "%s-%i|%s| %s",
          url.lastPathComponent,
          line,
          functionString,
          string)
#endif  // canImport(os)

      case .swift:
        let logger = Self.swiftLoggers[
          self,
          default: {
            var logger = Logger(label: system)
            logger.logLevel = .debug
            return logger
          }()
        ]
        logger.log(
          level: level,
          "\(line)|\(functionString)| \(string)",
          source: url.lastPathComponent,
          file: file,
          function: functionString,
          line: line)
    }
  }
}
