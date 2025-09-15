// Exclude this Foundation/OSLog-backed cache on WASM builds.
#if !(os(WASI) || arch(wasm32))
import Dispatch
#if canImport(Foundation)
import Foundation
#endif
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

    private struct ContextState {
      var swiftLoggers: [Log: Logging.Logger] = [:]
      #if canImport(os)
      var osLoggers: [Log: OSLog] = [:]
      #endif
      #if DEBUG
      var overrideLevelMasks: [Log: Log.LevelMask] = [:]
      var exposureLevel: Logging.Logger.Level = .trace
      #else
      var overrideLevelMasks: [Log: Log.LevelMask] = [:]
      var exposureLevel: Logging.Logger.Level = .critical
      #endif
      var pathInfos: [String: PathInfo] = [:]
    }

    private let queue = DispatchQueue(label: "wrkstrm.log.logger")
    private var contexts: [UInt64: ContextState] = [0: ContextState()]
    private var nextContextID: UInt64 = 1

    private static let threadContextKey = "WrkstrmLog.Cache.ContextID"

    struct PathInfo {
      let url: URL
      let fileName: String
      let lastPathComponent: String
    }

    private init() {}

    // MARK: - Context Management

    func currentThreadContextID() -> UInt64 {
      if let number = Thread.current.threadDictionary[Self.threadContextKey] as? NSNumber {
        return number.uint64Value
      }
      return 0
    }

    func resetForCurrentThread() {
      let newID = queue.sync { () -> UInt64 in
        let identifier = nextContextID
        nextContextID += 1
        contexts[identifier] = ContextState()
        return identifier
      }
      Thread.current.threadDictionary[Self.threadContextKey] = NSNumber(value: newID)
    }

    func withContext<T>(_ id: UInt64, _ body: () throws -> T) rethrows -> T {
      let dictionary = Thread.current.threadDictionary
      let previous = dictionary[Self.threadContextKey]
      dictionary[Self.threadContextKey] = NSNumber(value: id)
      defer {
        if let previous {
          dictionary[Self.threadContextKey] = previous
        } else {
          dictionary.removeObject(forKey: Self.threadContextKey)
        }
      }
      return try body()
    }

    private func updateContext<R>(id: UInt64, _ body: (inout ContextState) -> R) -> R {
      queue.sync {
        var state = contexts[id] ?? ContextState()
        let result = body(&state)
        contexts[id] = state
        return result
      }
    }

    private func readContext<R>(id: UInt64, _ body: (ContextState) -> R) -> R {
      queue.sync {
        let state = contexts[id] ?? ContextState()
        return body(state)
      }
    }

    // MARK: - Logger Caches

    /// Returns the cached Swift logger for the provided `Log` instance, creating
    /// one if necessary and updating its log level to `effectiveLevel`.
    func logger(for log: Log, effectiveLevel: Logging.Logger.Level) -> Logging.Logger {
      updateContext(id: log.contextID) { state in
        if var existing = state.swiftLoggers[log] {
          existing.logLevel = effectiveLevel
          state.swiftLoggers[log] = existing
          return existing
        }
        var newLogger = Logging.Logger(label: log.system)
        newLogger.logLevel = effectiveLevel
        state.swiftLoggers[log] = newLogger
        return newLogger
      }
    }

    #if canImport(os)
    /// Returns the cached `OSLog` instance for the provided `Log`, creating one
    /// if necessary.
    func osLogger(for log: Log) -> OSLog {
      updateContext(id: log.contextID) { state in
        if let existing = state.osLoggers[log] {
          return existing
        }
        let created = OSLog(subsystem: log.system, category: log.category)
        state.osLoggers[log] = created
        return created
      }
    }
    #endif

    func pathInfo(for file: String) -> PathInfo {
      let contextID = currentThreadContextID()
      return updateContext(id: contextID) { state in
        if let existing = state.pathInfos[file] {
          return existing
        }
        let url = URL(fileURLWithPath: file)
        let lastComponent = url.lastPathComponent
        let trimmed = lastComponent.replacingOccurrences(of: ".swift", with: "")
        let info = PathInfo(url: url, fileName: trimmed, lastPathComponent: lastComponent)
        state.pathInfos[file] = info
        return info
      }
    }

    /// Removes all cached loggers and resets the global exposure level for the
    /// current thread context. Intended primarily for tests.
    func reset() {
      resetForCurrentThread()
    }

    /// Current number of cached SwiftLog loggers in the current context.
    var swiftCount: Int {
      let id = currentThreadContextID()
      return readContext(id: id) { $0.swiftLoggers.count }
    }

    var pathInfoCount: Int {
      let id = currentThreadContextID()
      return readContext(id: id) { $0.pathInfos.count }
    }

    /// Returns whether a Swift logger exists for the given `Log` in its context.
    func hasSwiftLogger(for log: Log) -> Bool {
      readContext(id: log.contextID) { $0.swiftLoggers[log] != nil }
    }

    #if canImport(os)
    /// Current number of cached OSLog loggers in the current context.
    var osCount: Int {
      let id = currentThreadContextID()
      return readContext(id: id) { $0.osLoggers.count }
    }

    /// Returns whether an OS logger exists for the given `Log` in its context.
    func hasOSLogger(for log: Log) -> Bool {
      readContext(id: log.contextID) { $0.osLoggers[log] != nil }
    }
    #endif

    /// Global log exposure level applied across all loggers in the current context.
    var globalExposureLevel: Logging.Logger.Level {
      get {
        let id = currentThreadContextID()
        return readContext(id: id) { $0.exposureLevel }
      }
      set {
        let id = currentThreadContextID()
        queue.sync {
          var state = contexts[id] ?? ContextState()
          state.exposureLevel = newValue
          contexts[id] = state
        }
      }
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
      updateContext(id: logger.contextID) { state in
        state.overrideLevelMasks[logger] = Log.LevelMask.threshold(level)
      }
      #endif
    }

    #if DEBUG
    /// Returns the override mask for the specified logger, if any.
    func overrideMask(for logger: Log) -> Log.LevelMask? {
      readContext(id: logger.contextID) { $0.overrideLevelMasks[logger] }
    }

    /// Removes and returns the override mask for the specified logger.
    func removeOverride(for logger: Log) -> Log.LevelMask? {
      updateContext(id: logger.contextID) { state in
        state.overrideLevelMasks.removeValue(forKey: logger)
      }
    }
    #endif
  }
}

#endif  // !(os(WASI) || arch(wasm32))
