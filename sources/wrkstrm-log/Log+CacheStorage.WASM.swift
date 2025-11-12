// Minimal cache for WASM builds: no Foundation, no OSLog, print backend only.
#if os(WASI) || arch(wasm32)
import Logging

extension Log {
  final class Cache: @unchecked Sendable {
    static let shared = Cache()

    struct PathInfo {
      let url: String
      let fileName: String
      let lastPathComponent: String
    }

    // Global exposure level; defaults mirror non-WASM behavior.
    #if DEBUG
    private var exposureLevel: Logging.Logger.Level = .trace
    #else
    private var exposureLevel: Logging.Logger.Level = .critical
    #endif

    func pathInfo(for file: String) -> PathInfo {
      // Derive last path component without Foundation.
      let last = file.split(separator: "/").last.map(String.init) ?? file
      let trimmed = last.hasSuffix(".swift") ? String(last.dropLast(6)) : last
      return PathInfo(url: file, fileName: trimmed, lastPathComponent: last)
    }

    // Debug overrides are no-ops on WASM.
    #if DEBUG
    func overrideLevel(for logger: Log, to level: Logging.Logger.Level) {}
    func overrideMask(for logger: Log) -> Log.LevelMask? { nil }
    func removeOverride(for logger: Log) -> Log.LevelMask? { nil }
    #endif

    func reset() {
      #if DEBUG
      exposureLevel = .trace
      #else
      exposureLevel = .critical
      #endif
    }

    var swiftCount: Int { 0 }
    var pathInfoCount: Int { 0 }

    var globalExposureLevel: Logging.Logger.Level {
      get { exposureLevel }
      set { exposureLevel = newValue }
    }

    // MARK: - Compatibility surface with non-WASM Cache

    /// Single-context identifier placeholder (non-threaded on WASM).
    func currentThreadContextID() -> UInt64 { 0 }

    /// Execute body without context switching (WASM single-context).
    func withContext<T>(_ id: UInt64, _ body: () throws -> T) rethrows -> T { try body() }

    /// Provide a SwiftLog logger for the given `Log`. No caching on WASM.
    func logger(for log: Log, effectiveLevel: Logging.Logger.Level) -> Logging.Logger {
      var logger = Logging.Logger(label: log.system)
      logger.logLevel = effectiveLevel
      return logger
    }
  }
}
#endif
