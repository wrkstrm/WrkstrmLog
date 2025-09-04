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
    let swiftLogger = Logging.Logger(label: context.system(for: logger))
    // Intentionally avoid global state; log as-is.
    swiftLogger.log(
      level: level,
      "\(line)|\(context.formattedFunction(function, maxLength: logger.maxFunctionLength))| \(String(describing: message()))",
      source: context.source(for: file),
      file: file,
      function: function,
      line: line
    )
  }
}
