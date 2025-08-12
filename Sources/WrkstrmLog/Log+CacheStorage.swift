import Dispatch
import Logging

#if canImport(os)
  import os
#endif

extension Log {
  /// Thread-safe cache storing logger instances and global exposure configuration.
  ///
  /// This type is an internal implementation detail used to coordinate logging
  /// across the library. Access is synchronized via an internal serial dispatch
  /// queue to ensure thread safety.
  final class Cache: @unchecked Sendable {
    /// Shared cache used across the library.
    static let shared = Cache()

    private let queue = DispatchQueue(label: "wrkstrm.log.logger")

    private var swiftLoggers: [Log: Logging.Logger] = [:]
    #if canImport(os)
      private var osLoggers: [Log: OSLog] = [:]
    #endif
    #if DEBUG
      private var overrideLevelMasks: [Log: Log.LevelMask] = [:]
    #endif

    #if DEBUG
      private var exposureLevel: Logging.Logger.Level = .trace
    #else
      private var exposureLevel: Logging.Logger.Level = .critical
    #endif

    /// Returns the cached Swift logger for the provided `Log` instance, creating
    /// one if necessary and updating its log level to `effectiveLevel`.
    func logger(for log: Log, effectiveLevel: Logging.Logger.Level) -> Logging.Logger {
      queue.sync {
        if var existing = swiftLoggers[log] {
          existing.logLevel = effectiveLevel
          swiftLoggers[log] = existing
          return existing
        }
        var newLogger = Logging.Logger(label: log.system)
        newLogger.logLevel = effectiveLevel
        swiftLoggers[log] = newLogger
        return newLogger
      }
    }

    #if canImport(os)
      /// Returns the cached `OSLog` instance for the provided `Log`, creating one
      /// if necessary.
      func osLogger(for log: Log) -> OSLog {
        queue.sync {
          if let existing = osLoggers[log] {
            return existing
          }
          let created = OSLog(subsystem: log.system, category: log.category)
          osLoggers[log] = created
          return created
        }
      }
    #endif

    /// Removes all cached loggers and resets the global exposure level. Intended
    /// primarily for tests.
    func reset() {
      queue.sync {
        swiftLoggers.removeAll()
        #if canImport(os)
          osLoggers.removeAll()
        #endif
        #if DEBUG
          overrideLevelMasks.removeAll()
        #endif
        exposureLevel = .critical
      }
    }

    /// Current number of cached SwiftLog loggers. Used in tests.
    var swiftLoggerCount: Int { queue.sync { swiftLoggers.count } }

    /// Returns whether a Swift logger exists for the given `Log`.
    func hasSwiftLogger(for log: Log) -> Bool {
      queue.sync { swiftLoggers[log] != nil }
    }

    #if canImport(os)
      /// Current number of cached OSLog loggers. Used in tests.
      var osLoggerCount: Int { queue.sync { osLoggers.count } }

      /// Returns whether an OS logger exists for the given `Log`.
      func hasOSLogger(for log: Log) -> Bool {
        queue.sync { osLoggers[log] != nil }
      }
    #endif

    /// Global log exposure level applied across all loggers. Clamped by each
    /// logger's `maxExposureLevel`.
    var globalExposureLevel: Logging.Logger.Level {
      get { queue.sync { exposureLevel } }
      set { queue.sync { exposureLevel = newValue } }
    }

    /// Overrides the minimum logging level for the specified logger. Available
    /// only in debug builds.
    /// - Parameters:
    ///   - logger: The logger to override.
    ///   - level: The new minimum level to expose.
    func overrideLevel(
      for logger: Log,
      to level: Logging.Logger.Level
    ) {
      #if DEBUG
        queue.sync { overrideLevelMasks[logger] = Log.LevelMask.threshold(level) }
      #endif
    }

    #if DEBUG
      /// Returns the override mask for the specified logger, if any.
      func overrideMask(for logger: Log) -> Log.LevelMask? {
        queue.sync { overrideLevelMasks[logger] }
      }

      /// Removes and returns the override mask for the specified logger.
      func removeOverride(for logger: Log) -> Log.LevelMask? {
        queue.sync { overrideLevelMasks.removeValue(forKey: logger) }
      }
    #endif

    // MARK: - Private

    private init() {}
  }
}
