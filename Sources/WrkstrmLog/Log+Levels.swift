import Logging

extension Log {
  #if DEBUG
    /// Bit mask describing which log levels are enabled.
    struct LevelMask: OptionSet, Sendable {
      /// The raw bit mask value.
      let rawValue: UInt8

      /// Creates a new mask from the given raw value.
      /// - Parameter rawValue: The raw bit mask value.
      init(rawValue: UInt8) { self.rawValue = rawValue }

      /// Individual log level bits. The log level increases with frequency.
      static let trace = LevelMask(rawValue: 1 << 6)
      static let debug = LevelMask(rawValue: 1 << 5)
      static let info = LevelMask(rawValue: 1 << 4)
      static let notice = LevelMask(rawValue: 1 << 3)
      static let warning = LevelMask(rawValue: 1 << 2)
      static let error = LevelMask(rawValue: 1 << 1)
      static let critical = LevelMask(rawValue: 1 << 0)

      /// A mask containing all levels from the specified minimum level upward.
      /// - Parameter level: The minimum included level.
      static func threshold(_ level: Logging.Logger.Level) -> LevelMask {
        switch level {
        case .trace:
          return [.trace, .debug, .info, .notice, .warning, .error, .critical]
        case .debug:
          return [.debug, .info, .notice, .warning, .error, .critical]
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

    /// Override level masks used during debugging.
    /// Access is synchronized using `loggerQueue`.
    nonisolated(unsafe) static var overrideLevelMasks: [Log: LevelMask] = [:]
  #endif

  /// Global minimum log level applied to all loggers to limit message exposure.
  /// Defaults to `.critical` and must be configured explicitly to expose additional levels.
  #if DEBUG
    nonisolated(unsafe) static var exposureLevel: Logging.Logger.Level = .trace
  #else
    nonisolated(unsafe) static var exposureLevel: Logging.Logger.Level = .critical
  #endif

  /// Overrides the minimum logging level for a specific logger. Only
  /// available in debug builds.
  /// - Parameters:
  ///   - logger: The logger to override.
  ///   - level: The new minimum logging level.
  public static func overrideLevel(
    for logger: Log,
    to level: Logging.Logger.Level
  ) {
    #if DEBUG
      loggerQueue.sync {
        overrideLevelMasks[logger] = LevelMask.threshold(level)
      }
    #endif
  }

  /// Global log exposure level applied across all loggers.
  ///
  /// The value is clamped by each logger's `maxExposureLevel`, ensuring
  /// libraries must explicitly opt in before more verbose logging is emitted.
  /// Invoke during application initialization to expose additional logs beyond
  /// the default `.critical` level.
  public static var globalExposureLevel: Logging.Logger.Level {
    get { loggerQueue.sync { exposureLevel } }
    set { loggerQueue.sync { exposureLevel = newValue } }
  }
}
