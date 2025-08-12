import Dispatch
import Foundation
import Logging

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
      case os  // swiftlint:disable:this identifier_name
    #endif  // canImport(os)
    /// Swift style, logs messages using Swift's built-in logging framework (SwiftLog).
    /// Ideal for server-side Swift applications or when consistent logging behavior across
    /// platforms is desired.
    case swift
    /// Disabled style that suppresses all logging. Recommended for release builds when
    /// log output is not desired.
    case disabled
  }

  /// Configuration options for a logger instance.
  public struct Options: OptionSet, Hashable, Sendable {
    /// The raw bit mask representing the option set.
    public let rawValue: Int

    /// Creates a new set from the given raw value.
    /// - Parameter rawValue: The raw bit mask value.
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Indicates the logger should remain active in production builds.
    public static let prod = Options(rawValue: 1 << 0)
  }

  /// The system name for the logger. Typically represents the application or module name.
  public let system: String

  /// The category name for the logger. Used to categorize and filter log messages.
  public let category: String

  /// The logging style used by the logger. Defaults to `.os` on Apple
  /// platforms and `.swift` elsewhere, but is disabled in production unless
  /// the `.prod` option is specified.
  public let style: Style

  /// Options describing when the logger should be active.
  public let options: Options

  /// Internal maximum log level this logger is permitted to expose.
  private let maxExposureLevelLimit: Logging.Logger.Level

  /// The maximum log level this logger can emit.
  public var maxExposureLevel: Logging.Logger.Level { maxExposureLevelLimit }

  #if canImport(os)
    @usableFromInline static let defaultStyle: Style = .os
  #else  // canImport(os)
    @usableFromInline static let defaultStyle: Style = .swift
  #endif  // canImport(os)

  /// Storage for SwiftLog loggers, keyed by `Log` instance.
  /// Access is synchronized using `loggerQueue`.
  private nonisolated(unsafe) static var swiftLoggers: [Log: Logging.Logger] =
    [:]

  /// Serial queue used to synchronize access to static logger storage.
  static let loggerQueue = DispatchQueue(label: "wrkstrm.log.logger")

  /// Current number of cached SwiftLog loggers. Used in tests.
  static var _swiftLoggerCount: Int {  // swiftlint:disable:this identifier_name
    loggerQueue.sync { swiftLoggers.count }
  }

  /// Removes all cached loggers. Intended for tests.
  static func _reset() {  // swiftlint:disable:this identifier_name
    loggerQueue.sync {
      swiftLoggers.removeAll()
      #if DEBUG
        overrideLevelMasks.removeAll()
      #endif
      #if canImport(os)
        osLoggers.removeAll()
      #endif
      exposureLevel = .critical
    }
  }

  /// Indicates whether a Swift logger exists for the given instance. Used in tests.
  func _hasSwiftLogger() -> Bool {  // swiftlint:disable:this identifier_name
    Self.loggerQueue.sync { Self.swiftLoggers[self] != nil }
  }

  /// A convenience logger instance with logging disabled.
  /// Useful for cases where a logger must be provided but logging should be suppressed.
  public static let disabled = Log(style: .disabled)

  #if canImport(os)
    /// Storage for OSLog loggers, keyed by `Log` instance.
    /// Access is synchronized using `loggerQueue`.
    private nonisolated(unsafe) static var osLoggers: [Log: OSLog] = [:]

    /// Indicates whether an OS logger exists for the given instance. Used in tests.
    func _hasOSLogger() -> Bool {  // swiftlint:disable:this identifier_name
      Self.loggerQueue.sync { Self.osLoggers[self] != nil }
    }

    /// Current number of cached OSLog loggers. Used in tests.
    static var _osLoggerCount: Int {  // swiftlint:disable:this identifier_name
      loggerQueue.sync { osLoggers.count }
    }
  #endif  // canImport(os)

  /// Initializes a new `Log` instance.
  ///
  /// - Parameters:
  ///   - system: The system name for the logger. Defaults to an empty string.
  ///   - category: The category name for the logger. Defaults to an empty string.
  ///   - style: The logging style used by the logger (`.print`, `.swift`, `.os`, `.disabled`).
  ///     Defaults to the platform-specific `defaultStyle`.
  ///   - maxExposureLevel: The maximum log level permitted for this logger. Defaults to `.critical`.
  ///   - options: Configuration options for the logger. Use `.prod` to keep the
  ///     logger active in production. Defaults to an empty set.
  ///
  /// Example:
  /// ```
  /// let networkLogger = Log(system: "MyApp", category: "Networking")
  /// ```
  public init(
    system: String = "",
    category: String = "",
    style: Style = ProcessInfo.inXcodeEnvironment ? defaultStyle : .print,
    maxExposureLevel: Logging.Logger.Level = .critical,
    options: Options = []
  ) {
    self.system = system
    self.category = category
    self.options = options
    self.maxExposureLevelLimit = maxExposureLevel
    #if DEBUG
      self.style = style
    #else
      self.style = options.contains(.prod) ? style : .disabled
    #endif
  }

  /// Maximum length for the function name in log messages.
  public var maxFunctionLength: Int?

  public static func == (lhs: Log, rhs: Log) -> Bool {
    lhs.system == rhs.system && lhs.category == rhs.category
      && lhs.style == rhs.style
      && lhs.options == rhs.options
      && lhs.maxExposureLevelLimit == rhs.maxExposureLevelLimit
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(system)
    hasher.combine(category)
    hasher.combine(style)
    hasher.combine(options)
    hasher.combine(maxExposureLevelLimit)
  }

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
  /// Verbose output is mapped to the `.debug` log level so it can be
  /// easily filtered separately from informational logs.
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
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    guard style != .disabled else { return }
    // Verbose messages are lower priority than standard informational logs.
    // Map them to the debug log level so they can be filtered separately.
    log(
      .debug,
      describable: describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a debug message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The object or string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public func debug(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    guard style != .disabled else { return }
    log(
      .debug,
      describable: describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs an informational message with the specified parameters.
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
    file: String = #fileID,
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

  /// Logs a notice message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The object or string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public func notice(
    _ describable: Any = "",
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    guard style != .disabled else { return }
    log(
      .notice,
      describable: describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a warning message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The object or string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public func warning(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    guard style != .disabled else { return }
    log(
      .warning,
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
    file: String = #fileID,
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
    file: String = #fileID,
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

 private func log(
   _ level: Logging.Logger.Level,
   describable: Any,
   file: String,
   function: String,
   line: UInt,
   column _: UInt,
   dso: UnsafeRawPointer
 ) {
   guard let effectiveLevel = effectiveLevel(for: level) else { return }
   let url = URL(fileURLWithPath: file)
   let fileName = url.lastPathComponent.replacingOccurrences(
     of: ".swift",
     with: ""
   )
   let functionString = formattedFunction(function)
   switch style {
   case .print:
     logPrint(
       level,
       fileName: fileName,
       function: functionString,
       line: line,
       describable: describable
     )
   #if canImport(os)
   case .os:
     logOS(
       level,
       describable: describable,
       url: url,
       function: functionString,
       line: line,
       dso: dso
     )
   #endif  // canImport(os)
   case .swift:
     logSwift(
       level,
       effectiveLevel: effectiveLevel,
       describable: describable,
       url: url,
       function: functionString,
       file: file,
       line: line
     )
   case .disabled:
     break
   }
 }

 internal func effectiveLevel(
   for level: Logging.Logger.Level
 ) -> Logging.Logger.Level? {
   guard style != .disabled else { return nil }
   let globalExposure = Self.globalExposureLevel
   #if DEBUG
     let overrideMask = Self.loggerQueue.sync { Self.overrideLevelMasks[self] }
     var resolvedMask: LevelMask
     if let overrideMask {
       resolvedMask = overrideMask
     } else {
       resolvedMask = .threshold(level)
     }
     let clampedExposure =
       globalExposure.naturalIntegralValue
         <= self.maxExposureLevelLimit.naturalIntegralValue
       ? globalExposure : self.maxExposureLevelLimit
     resolvedMask.formIntersection(.threshold(clampedExposure))
     guard resolvedMask.contains(.single(level)) else { return nil }
     return resolvedMask.minimumLevel
   #else
     let configuredLevel = self.maxExposureLevelLimit
     let clampedExposure =
       globalExposure.naturalIntegralValue
         <= self.maxExposureLevelLimit.naturalIntegralValue
       ? globalExposure : self.maxExposureLevelLimit
     let effectiveLevel: Logging.Logger.Level
     if clampedExposure > configuredLevel {
       effectiveLevel = clampedExposure
     } else {
       effectiveLevel = configuredLevel
     }
     guard level >= effectiveLevel else { return nil }
     return effectiveLevel
   #endif
 }

  private func logPrint(
    _ level: Logging.Logger.Level,
    fileName: String,
    function: String,
    line: UInt,
    describable: Any
  ) {
    Swift
      .print(
        "\(system):\(category):\(level.emoji) \(fileName):\(String(line))|\(function)| "
          + String(describing: describable)
      )
  }

 #if canImport(os)
   private func logOS(
     _ level: Logging.Logger.Level,
     describable: Any,
     url: URL,
     function: String,
     line: UInt,
     dso: UnsafeRawPointer
   ) {
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
       function,
       String(describing: describable)
     )
   }
 #endif  // canImport(os)

 private func logSwift(
   _ level: Logging.Logger.Level,
   effectiveLevel: Logging.Logger.Level,
   describable: Any,
   url: URL,
   function: String,
   file: String,
   line: UInt
 ) {
   let logger: Logging.Logger = Self.loggerQueue.sync {
     if var existing = Self.swiftLoggers[self] {
       existing.logLevel = effectiveLevel
       Self.swiftLoggers[self] = existing
       return existing
     }
     var newLogger = Logging.Logger(label: system)
     newLogger.logLevel = effectiveLevel
     Self.swiftLoggers[self] = newLogger
     return newLogger
   }
  logger.log(
    level: level,
    "\(line)|\(function)| \(String(describing: describable))",
    source: url.lastPathComponent,
    file: file,
    function: function,
    line: line
  )
  }

}

extension Log {

  /// Determines whether logging is enabled for the provided level based on
  /// both the logger's `maxExposureLevel` and the global exposure level.
  ///
  /// - Parameter level: The level to evaluate.
  /// - Returns: `true` if logging at the specified level is enabled.
  public func isEnabled(for level: Logging.Logger.Level) -> Bool {
    level >= self.maxExposureLevel && level >= Log.globalExposureLevel
  }

  /// Invokes `body` only when logging is enabled for the given level.
  ///
  /// - Parameters:
  ///   - level: The level to evaluate.
  ///   - body: A closure executed when logging is enabled for `level`.
  public func ifEnabled(for level: Logging.Logger.Level, _ body: (Log) throws -> Void) rethrows {
    guard isEnabled(for: level) else { return }
    try body(self)
  }
}

extension Logging.Logger.Level {
  /// A numeric representation of the log level where lower values
  /// indicate more severe messages.
  internal var naturalIntegralValue: Int {
    switch self {
    case .critical:
      return 0
    case .error:
      return 1
    case .warning:
      return 2
    case .notice:
      return 3
    case .info:
      return 4
    case .debug:
      return 5
    case .trace:
      return 6
    }
  }
}
