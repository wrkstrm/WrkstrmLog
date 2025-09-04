#if canImport(os)
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
    let subsystem = context.system(for: logger)
    let category = context.category(for: logger)
    let oslog = OSLog(subsystem: subsystem, category: category)
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
