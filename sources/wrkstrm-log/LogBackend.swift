import Logging

/// Backend interface for emitting log entries.
///
/// Backends are expected to be stateless and thread-safe. Implementations
/// should perform minimal work when the message will be dropped by their
/// destination and avoid allocating when possible.
public protocol LogBackend: Sendable {
  /// Core requirement: pass the call straight to the concrete backend.
  func log(
    _ level: Logging.Logger.Level,
    message: @autoclosure () -> Any,
    logger: Log,
    file: String,
    function: String,
    line: UInt,
    context: any CommonLogContext
  )
}

extension LogBackend {
  public func trace(
    _ message: @autoclosure () -> Any, log logger: Log, file: String, function: String, line: UInt,
    context: any CommonLogContext
  ) {
    log(
      .trace, message: message(), logger: logger, file: file, function: function, line: line,
      context: context)
  }
  public func debug(
    _ message: @autoclosure () -> Any, log logger: Log, file: String, function: String, line: UInt,
    context: any CommonLogContext
  ) {
    log(
      .debug, message: message(), logger: logger, file: file, function: function, line: line,
      context: context)
  }
  public func info(
    _ message: @autoclosure () -> Any, log logger: Log, file: String, function: String, line: UInt,
    context: any CommonLogContext
  ) {
    log(
      .info, message: message(), logger: logger, file: file, function: function, line: line,
      context: context)
  }
  public func notice(
    _ message: @autoclosure () -> Any, log logger: Log, file: String, function: String, line: UInt,
    context: any CommonLogContext
  ) {
    log(
      .notice, message: message(), logger: logger, file: file, function: function, line: line,
      context: context)
  }
  public func warning(
    _ message: @autoclosure () -> Any, log logger: Log, file: String, function: String, line: UInt,
    context: any CommonLogContext
  ) {
    log(
      .warning, message: message(), logger: logger, file: file, function: function, line: line,
      context: context)
  }
  public func error(
    _ message: @autoclosure () -> Any, log logger: Log, file: String, function: String, line: UInt,
    context: any CommonLogContext
  ) {
    log(
      .error, message: message(), logger: logger, file: file, function: function, line: line,
      context: context)
  }
  public func critical(
    _ message: @autoclosure () -> Any, log logger: Log, file: String, function: String, line: UInt,
    context: any CommonLogContext
  ) {
    log(
      .critical, message: message(), logger: logger, file: file, function: function, line: line,
      context: context)
  }
}
