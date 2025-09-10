#if canImport(Foundation) && !os(WASI) && canImport(os)
import Logging
import os

public struct OSLogBackend: LogBackend, Sendable {
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
    // Reuse cached OSLog for compatibility and performance.
    let oslog = Log.Cache.shared.osLogger(for: logger)
    let last = context.lastPathComponent(for: file)
    let fn = context.formattedFunction(function, maxLength: logger.maxFunctionLength)
    os_log(
      level.toOSType,
      log: oslog,
      "%{public}s-%{public}u|%{public}s| %{public}s",
      last,
      line,
      fn,
      String(describing: message())
    )
  }
}
#endif
