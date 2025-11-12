import Logging

/// No-op backend that discards all log messages.
public struct DisabledLogBackend: LogBackend, Sendable {
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
    // Intentionally no-op
  }
}
