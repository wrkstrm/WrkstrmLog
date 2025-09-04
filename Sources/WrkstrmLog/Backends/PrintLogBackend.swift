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
    let fileName = context.fileName(for: file)
    let fn = context.formattedFunction(function, maxLength: logger.maxFunctionLength)
    Swift.print(
      "\(sys):\(cat):\(level.emoji) \(fileName):\(String(line))|\(fn)| "
        + String(describing: message()))
  }
}
