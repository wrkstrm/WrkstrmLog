import Logging

public struct PrintLogBackend: LogBackend, Sendable {
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
    let sys = context.system(for: logger)
    let cat = context.category(for: logger)
    let body = logger.decorator.format(
      level,
      message: message(),
      logger: logger,
      file: file,
      function: function,
      line: line,
      context: context
    )
    Swift.print("\(sys):\(cat):\(level.emoji) \(body)")
  }
}
