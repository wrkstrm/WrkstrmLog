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

  #if DEBUG
    /// Bit mask describing which log levels are enabled.
    struct LevelMask: OptionSet, Sendable {
      /// The raw bit mask value.
      let rawValue: UInt8

      /// Creates a new mask from the given raw value.
      /// - Parameter rawValue: The raw bit mask value.
      init(rawValue: UInt8) { self.rawValue = rawValue }

      /// Individual log level bits.
      static let trace = LevelMask(rawValue: 1 << 0)
      static let debug = LevelMask(rawValue: 1 << 1)
      static let info = LevelMask(rawValue: 1 << 2)
      static let notice = LevelMask(rawValue: 1 << 3)
      static let warning = LevelMask(rawValue: 1 << 4)
      static let error = LevelMask(rawValue: 1 << 5)
      static let critical = LevelMask(rawValue: 1 << 6)

      /// A mask containing all levels from the specified minimum level upward.
      /// - Parameter level: The minimum included level.
      static func threshold(_ level: Logging.Logger.Level) -> LevelMask {
        switch level {
        case .trace: return [.trace, .debug, .info, .notice, .warning, .error, .critical]
        case .debug: return [.debug, .info, .notice, .warning, .error, .critical]
        case .info: return [.info, .notice, .warning, .error, .critical]
        case .notice: return [.notice, .warning, .error, .critical]
        case .warning: return [.warning, .error, .critical]
        case .error: return [.error, .critical]
        case .critical: return [.critical]
        }
      }

      /// A mask representing only the specified level.
      /// - Parameter level: The level to include.
      static func single(_ level: Logging.Logger.Level) -> LevelMask {
        switch level {
        case .trace: return .trace
        case .debug: return .debug
        case .info: return .info
        case .notice: return .notice
        case .warning: return .warning
        case .error: return .error
        case .critical: return .critical
        }
      }

      /// The lowest level contained in the mask.
      var minimumLevel: Logging.Logger.Level {
        if contains(.trace) { return .trace }
        if contains(.debug) { return .debug }
        if contains(.info) { return .info }
        if contains(.notice) { return .notice }
        if contains(.warning) { return .warning }
        if contains(.error) { return .error }
        return .critical
      }
    }
  #endif

  /// The system name for the logger. Typically represents the application or module name.
  public let system: String

  /// The category name for the logger. Used to categorize and filter log messages.
  public let category: String

  #if canImport(os)
    /// The logging style used by the logger. Defaults to `.os` but is disabled in
    /// production unless the `.prod` option is specified.
    public let style: Style
  #else  // canImport(os)
    /// The logging style used by the logger. Defaults to `.swift` but is disabled in
    /// production unless the `.prod` option is specified.
    public let style: Style
  #endif  // canImport(os)

  /// The minimum log level that will be logged.
  /// Messages below this level are ignored.
  public let level: Logging.Logger.Level

  /// Options describing when the logger should be active.
  public let options: Options

  /// Internal maximum log level this logger is permitted to expose.
  private let exposureLimit: Logging.Logger.Level

  /// The maximum log level this logger can emit.
  public var maxExposureLevel: Logging.Logger.Level { exposureLimit }

  #if canImport(os)
    @usableFromInline static let defaultStyle: Style = .os
  #else  // canImport(os)
    @usableFromInline static let defaultStyle: Style = .swift
  #endif  // canImport(os)

  /// Storage for SwiftLog loggers, keyed by `Log` instance.
  /// Access is synchronized using `loggerQueue`.
  private nonisolated(unsafe) static var swiftLoggers: [Self: Logging.Logger] =
    [:]

  #if DEBUG
    /// Override level masks used during debugging.
    /// Access is synchronized using `loggerQueue`.
    nonisolated(unsafe) static var overrideLevelMasks: [Self: LevelMask] = [:]
  #endif

  /// Global minimum log level applied to all loggers to limit message exposure.
  /// Defaults to `.critical` and must be configured explicitly to expose additional levels.
  private nonisolated(unsafe) static var exposureLevel: Logging.Logger.Level = .critical

  /// Serial queue used to synchronize access to static logger storage.
  private static let loggerQueue = DispatchQueue(label: "wrkstrm.log.logger")

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

  /// Overrides the minimum logging level for a specific logger. Only
  /// available in debug builds.
  /// - Parameters:
  ///   - logger: The logger to override.
  ///   - level: The new minimum logging level.
  public static func overrideLevel(for logger: Log, to level: Logging.Logger.Level) {
    #if DEBUG
      loggerQueue.sync {
        overrideLevelMasks[logger] = LevelMask.threshold(level)
      }
    #endif
  }

  /// Sets a global minimum log level applied across all loggers.
  ///
  /// The provided `level` is clamped by each logger's `maxExposureLevel`,
  /// ensuring libraries must explicitly opt in before more verbose logging
  /// is emitted. Invoke during application initialization to expose
  /// additional logs beyond the default `.critical` level.
  ///
  /// - Parameter level: The lowest level that will be emitted globally.
  public static func limitExposure(to level: Logging.Logger.Level) {
    loggerQueue.sync { exposureLevel = level }
  }

  /// Indicates whether a Swift logger exists for the given instance. Used in tests.
  func _hasSwiftLogger() -> Bool {  // swiftlint:disable:this identifier_name
    Self.loggerQueue.sync { Self.swiftLoggers[self] != nil }
  }

  #if canImport(os)
    /// Indicates whether an OS logger exists for the given instance. Used in tests.
    func _hasOSLogger() -> Bool {  // swiftlint:disable:this identifier_name
      Self.loggerQueue.sync { Self.osLoggers[self] != nil }
    }
  #endif

  #if canImport(os)
    /// Storage for OSLog loggers, keyed by `Log` instance.
    /// Access is synchronized using `loggerQueue`.
    private nonisolated(unsafe) static var osLoggers: [Self: OSLog] = [:]

    /// Current number of cached OSLog loggers. Used in tests.
    static var _osLoggerCount: Int {  // swiftlint:disable:this identifier_name
      loggerQueue.sync { osLoggers.count }
    }

    /// Initializes a new `Log` instance.
    ///
    /// - Parameters:
    ///   - system: The system name for the logger. Defaults to an empty string.
    ///   - category: The category name for the logger. Defaults to an empty string.
    ///   - style: The logging style used by the logger (`.print`, `.os`, `.swift`,
    ///     `.disabled`). Defaults to `.os`.
    ///   - level: The minimum log level that will be logged. Defaults to `.info`.
    ///   - exposure: The maximum log level permitted for this logger. Defaults to `.critical`.
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
      style: Style = defaultStyle,
      level: Logging.Logger.Level = .info,
      exposure: Logging.Logger.Level = .critical,
      options: Options = []
    ) {
      self.system = system
      self.category = category
      self.level = level
      self.options = options
      self.exposureLimit = exposure
      #if DEBUG
        self.style = style
      #else
        self.style = options.contains(.prod) ? style : .disabled
      #endif
    }

    /// A convenience logger instance with logging disabled.
    /// Useful for cases where a logger must be provided but logging should be suppressed.
    public static let disabled = Log(style: .disabled)

  #else  // canImport(os)
    /// Initializes a new `Log` instance.
    ///
    /// - Parameters:
    ///   - system: The system name for the logger. Defaults to an empty string.
    ///   - category: The category name for the logger. Defaults to an empty string.
    ///   - style: The logging style used by the logger (`.print`, `.swift`, `.disabled`).
    ///     Defaults to `.swift`.
    ///   - level: The minimum log level that will be logged. Defaults to `.info`.
    ///   - exposure: The maximum log level permitted for this logger. Defaults to `.critical`.
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
      style: Style = defaultStyle,
      level: Logging.Logger.Level = .info,
      exposure: Logging.Logger.Level = .critical,
      options: Options = []
    ) {
      self.system = system
      self.category = category
      self.level = level
      self.options = options
      self.exposureLimit = exposure
      #if DEBUG
        self.style = style
      #else
        self.style = options.contains(.prod) ? style : .disabled
      #endif
    }

    public static let disabled = Log(style: .disabled)
  #endif  // canImport(os)

  /// Maximum length for the function name in log messages.
  public var maxFunctionLength: Int?

  public static func == (lhs: Log, rhs: Log) -> Bool {
    lhs.system == rhs.system && lhs.category == rhs.category
      && lhs.style == rhs.style
      && lhs.level == rhs.level
      && lhs.options == rhs.options
      && lhs.exposureLimit == rhs.exposureLimit
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(system)
    hasher.combine(category)
    hasher.combine(style)
    hasher.combine(level)
    hasher.combine(options)
    hasher.combine(exposureLimit)
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

  // swiftlint:disable:next function_parameter_count function_body_length
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
    let globalExposure = Self.loggerQueue.sync { Self.exposureLevel }
    #if DEBUG
      let overrideMask = Self.loggerQueue.sync { Self.overrideLevelMasks[self] }
      var mask: LevelMask
      if let overrideMask {
        mask = overrideMask
      } else {
        mask = LevelMask.threshold(self.level)
      }
      // Clamp the global exposure to the logger's maximum before evaluating.
      // Choose the more restrictive (higher-severity) level between the global
      // exposure setting and the logger's own limit.
      let clampedExposure =
        globalExposure.naturalIntegralValue <= self.exposureLimit.naturalIntegralValue
          ? globalExposure : self.exposureLimit
      mask.formIntersection(LevelMask.threshold(clampedExposure))
      guard mask.contains(.single(level)) else { return }
      let effectiveLevel = mask.minimumLevel
    #else
      let configuredLevel = self.level
      // Clamp the global exposure to the logger's maximum before evaluating.
      // Choose the more restrictive (higher-severity) level between the global
      // exposure setting and the logger's own limit.
      let clampedExposure =
        globalExposure.naturalIntegralValue <= self.exposureLimit.naturalIntegralValue
          ? globalExposure : self.exposureLimit
      let effectiveLevel: Logging.Logger.Level
      if clampedExposure > configuredLevel {
        effectiveLevel = clampedExposure
      } else {
        effectiveLevel = configuredLevel
      }
      guard level >= effectiveLevel else { return }
    #endif
    let url = URL(fileURLWithPath: file)
    let fileName = url.lastPathComponent.replacingOccurrences(
      of: ".swift",
      with: ""
    )
    let functionString = formattedFunction(function)
    switch style {
    case .print:
      Swift
        .print(
          "\(system):\(category):\(level.emoji) \(fileName):\(String(line))|\(functionString)| "
            + String(describing: describable)
        )

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
        "\(line)|\(functionString)| \(String(describing: describable))",
        source: url.lastPathComponent,
        file: file,
        function: functionString,
        line: line,
      )

    case .disabled:
      break
    }
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
