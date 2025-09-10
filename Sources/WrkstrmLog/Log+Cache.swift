import Logging

extension Log {
  /// Global log exposure level applied across all loggers.
  /// Clamped by each logger's `maxExposureLevel`.
  public static var globalExposureLevel: Logging.Logger.Level {
    get { Cache.shared.globalExposureLevel }
    set { Cache.shared.globalExposureLevel = newValue }
  }

  #if DEBUG
  /// Overrides the minimum logging level for the specified logger.
  /// Available only in debug builds.
  /// - Parameters:
  ///   - logger: The logger to override.
  ///   - level: The new minimum level to expose.
  public static func overrideLevel(
    for logger: Log,
    to level: Logging.Logger.Level
  ) {
    Cache.shared.overrideLevel(for: logger, to: level)
  }
  #endif

  // MARK: - Internal helpers for tests
  static func reset() {
    Cache.shared.reset()
    Inject.usePathInfoCache(true)
    Inject.resetInjection()
  }

  static var swiftCount: Int {
    Cache.shared.swiftCount
  }

  static var pathInfoCount: Int {
    Cache.shared.pathInfoCount
  }

  #if canImport(os)
  static var osCount: Int {
    Cache.shared.osCount
  }
  #endif
}
