import Logging

#if canImport(Foundation)
import Foundation
#endif
// OSLog only when available (not on WASM)
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
  /// Concrete backend used by this logger instance.
  private let backend: any LogBackend
  internal let contextID: UInt64
  /// Decorator for message formatting. Defaults to current style.
  public var decorator: any LogDecorator = Decorator.Current()

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

  /// Options describing when the logger should be active.
  public let options: Options

  /// Internal maximum log level this logger is permitted to expose.
  private let maxExposureLevelLimit: Logging.Logger.Level

  /// When true, this logger is forced disabled regardless of build/options.
  private let forceDisabled: Bool

  /// The maximum log level this logger can emit.
  public var maxExposureLevel: Logging.Logger.Level { maxExposureLevelLimit }

  /// Whether this logger is enabled for output given build configuration and options.
  /// In Debug, logging is enabled; in Release, require `.prod` to remain active.
  public var isEnabled: Bool {
    if forceDisabled { return false }
    #if DEBUG
    return true
    #else
    return options.contains(.prod)
    #endif
  }

  /// Initializes a new `Log` instance.
  ///
  /// - Parameters:
  ///   - system: The system name for the logger. Defaults to an empty string.
  ///   - category: The category name for the logger. Defaults to an empty string.
  ///   - maxExposureLevel: The maximum log level permitted for this logger. Defaults to `.critical`.
  ///   - options: Configuration options for the logger. Use `.prod` to keep the
  ///     logger active in production. Defaults to an empty set.
  ///   - backend: Provide a concrete backend to override the default platform selection.
  ///
  /// Example:
  /// ```
  /// let networkLogger = Log(system: "MyApp", category: "Networking")
  /// ```
  public init(
    system: String = "",
    category: String = "",
    maxExposureLevel: Logging.Logger.Level = .critical,
    options: Options = [],
    backend: (any LogBackend)? = nil
  ) {
    let contextID = Cache.shared.currentThreadContextID()
    self.system = system
    self.category = category
    self.options = options
    self.maxExposureLevelLimit = maxExposureLevel
    self.forceDisabled = false
    self.backend = backend ?? Log.makeDefaultBackend()
    self.contextID = contextID
  }

  /// Initializes a new `Log` instance using an ordered list of backends.
  /// The first backend is treated as the primary.
  public init(
    system: String = "",
    category: String = "",
    maxExposureLevel: Logging.Logger.Level = .critical,
    options: Options = [],
    backends: [any LogBackend]
  ) {
    let contextID = Cache.shared.currentThreadContextID()
    self.system = system
    self.category = category
    self.options = options
    self.maxExposureLevelLimit = maxExposureLevel
    self.forceDisabled = false
    if let first = backends.first {
      self.backend = first
    } else {
      self.backend = Log.makeDefaultBackend()
    }
    self.contextID = contextID
  }

  // Private designated initializer for factory helpers
  private init(
    system: String,
    category: String,
    options: Options,
    maxExposureLevel: Logging.Logger.Level,
    forceDisabled: Bool,
    backend: any LogBackend,
    contextID: UInt64
  ) {
    self.system = system
    self.category = category
    self.options = options
    self.maxExposureLevelLimit = maxExposureLevel
    self.forceDisabled = forceDisabled
    self.backend = backend
    self.contextID = contextID
  }

  /// A convenience logger instance with logging disabled regardless of build configuration.
  public static let disabled: Log = .init(
    system: "",
    category: "",
    options: [],
    maxExposureLevel: .critical,
    forceDisabled: true,
    backend: Log.makeDefaultBackend(),
    contextID: Cache.shared.currentThreadContextID()
  )

  /// Maximum length for the function name in log messages.
  public var maxFunctionLength: Int?

  public static func == (lhs: Log, rhs: Log) -> Bool {
    lhs.system == rhs.system && lhs.category == rhs.category
      && lhs.options == rhs.options
      && lhs.maxExposureLevelLimit == rhs.maxExposureLevelLimit
      && lhs.forceDisabled == rhs.forceDisabled
      && lhs.contextID == rhs.contextID
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(system)
    hasher.combine(category)
    hasher.combine(options)
    hasher.combine(maxExposureLevelLimit)
    hasher.combine(forceDisabled)
    hasher.combine(contextID)
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

  /// Logs a trace message with the specified parameters.
  ///
  /// Trace output is mapped to the `.trace` log level so that it has to be enabled manually.
  /// This is to avoid clogging the console.
  ///
  /// - Parameters:
  ///   - describable: The object or value to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public func trace(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    // Trace messages are lower priority and higher frequency than standard logs.
    // Map them to the trace log level so they can be filtered separately.
    log(
      .trace,
      describable: describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a verbose message with the specified parameters.
  ///
  /// Verbose output is mapped to the `.debug` log level so it can be
  /// easily filtered separately from informational logs.
  ///
  /// - Parameters:
  ///   - describable: The object or value to log.
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
    // Verbose messages are lower priority than standard informational logs.
    // Map them to the trace log level so they can be filtered separately.
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
  ///   - describable: The object or value to log.
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
  ///   - describable: The object or value to log.
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
    guard isEnabled else { fatalErrorHandler() }
    log(
      .critical,
      describable: describable ?? "",
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
    fatalErrorHandler("Guard failed: \(String(describing: describable))")
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
    Cache.shared.withContext(contextID) {
      guard isEnabled else { return }
      guard effectiveLevel(for: level) != nil else { return }
      let functionString = formattedFunction(function)
      // Pass through to the selected concrete backend.
      let context: any CommonLogContext = SwiftCommonLogContext()
      backend.log(
        level,
        message: String(describing: describable),
        logger: self,
        file: file,
        function: functionString,
        line: line,
        context: context
      )
    }
  }

  internal func effectiveLevel(
    for level: Logging.Logger.Level
  ) -> Logging.Logger.Level? {
    guard isEnabled else { return nil }
    let globalExposure = Cache.shared.globalExposureLevel
    #if DEBUG
    let overrideMask = Cache.shared.overrideMask(for: self)
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
    let contains = resolvedMask.contains(.single(level))
    #if WRKSTRMLOG_INTERNAL_TRACE
    LogTrace.log(
      "effective",
      "level=\(level) global=\(globalExposure) max=\(self.maxExposureLevelLimit) resolved.contains=\(contains) min=\(String(describing: resolvedMask.minimumLevel))"
    )
    #endif
    guard contains else { return nil }
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
    let allowed = level >= effectiveLevel
    #if WRKSTRMLOG_INTERNAL_TRACE
    LogTrace.log(
      "effective",
      "level=\(level) global=\(globalExposure) max=\(self.maxExposureLevelLimit) effective=\(effectiveLevel) allow=\(allowed)"
    )
    #endif
    guard allowed else { return nil }
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
    pathInfo: Cache.PathInfo,
    function: String,
    line: UInt,
    dso: UnsafeRawPointer
  ) {
    let logger = Cache.shared.osLogger(for: self)
    os_log(
      level.toOSType,
      dso: dso,
      log: logger,
      "%s-%i|%s| %s",
      pathInfo.lastPathComponent,
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
    pathInfo: Cache.PathInfo,
    function: String,
    file: String,
    line: UInt
  ) {
    let logger = Cache.shared.logger(for: self, effectiveLevel: effectiveLevel)
    logger.log(
      level: level,
      "\(line)|\(function)| \(String(describing: describable))",
      source: pathInfo.lastPathComponent,
      file: file,
      function: function,
      line: line
    )
  }

}

// MARK: - Backend defaults

extension Log {
  /// Choose a default backend at compile time based on platform.
  internal static func makeDefaultBackend() -> any LogBackend {
    // Resolve from injected selection first (primary = index 0),
    // otherwise choose a sensible platform default.
    switch Inject.currentBackend() {
    case .print:
      return PrintLogBackend()
    case .swift:
      return SwiftLogBackend()
    #if canImport(os)
    case .os:
      return OSLogBackend()
    #endif
    case .disabled:
      return DisabledLogBackend()
    case .auto:
      // Fall through to platform default below
      #if os(WASI) || arch(wasm32)
      return PrintLogBackend()
      #elseif canImport(Foundation) && !os(WASI)
      if !ProcessInfo.inXcodeEnvironment {
        return PrintLogBackend()
      }
      #endif
      #if canImport(os)
      return OSLogBackend()
      #else
      return SwiftLogBackend()
      #endif
    }
  }
}

extension Log {

  /// Determines whether logging is enabled for the provided level based on
  /// both the logger's `maxExposureLevel` and the global exposure level.
  ///
  /// - Parameter level: The level to evaluate.
  /// - Returns: `true` if logging at the specified level is enabled.
  public func isEnabled(for level: Logging.Logger.Level) -> Bool {
    level >= self.maxExposureLevel && level >= Cache.shared.globalExposureLevel
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
