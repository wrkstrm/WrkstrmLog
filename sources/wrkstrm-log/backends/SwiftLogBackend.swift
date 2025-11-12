import Logging

public struct SwiftLogBackend: LogBackend, Sendable {
  public init() {}

  public func log(
    _ level: Logging.Logger.Level,
    message: @autoclosure () -> Any,
    logger: Log,
    file: String,
    function: String,
    line: UInt,
    context: any CommonLogContext
  ) {
    // Reuse cached Swift logger for compatibility and performance.
    // We do not compute effective level here; use the current level as a floor.
    let swiftLogger = Log.Cache.shared.logger(for: logger, effectiveLevel: level)
    let body = logger.decorator.format(
      level,
      message: message(),
      logger: logger,
      file: file,
      function: function,
      line: line,
      context: context
    )
    swiftLogger.log(
      level: level, "\(body)", source: context.source(for: file), file: file, function: function,
      line: line)
  }
}
