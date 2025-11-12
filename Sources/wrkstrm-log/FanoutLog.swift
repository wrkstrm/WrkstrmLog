import Logging

/// A simple group of logs that forwards each call to every member.
public struct LogGroup: Sendable {
  public let logs: [Log]
  public init(_ logs: [Log]) { self.logs = logs }

  @inline(__always)
  private func forEach(_ body: (Log) -> Void) {
    for log in logs { body(log) }
  }

  public func trace(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) { forEach { $0.trace(describable, file: file, function: function, line: line) } }

  public func debug(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) { forEach { $0.debug(describable, file: file, function: function, line: line) } }

  public func verbose(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) { forEach { $0.verbose(describable, file: file, function: function, line: line) } }

  public func info(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) { forEach { $0.info(describable, file: file, function: function, line: line) } }

  public func notice(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) { forEach { $0.notice(describable, file: file, function: function, line: line) } }

  public func warning(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) { forEach { $0.warning(describable, file: file, function: function, line: line) } }

  public func error(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) { forEach { $0.error(describable, file: file, function: function, line: line) } }

  public func `guard`(
    _ describable: Any? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) -> Never {
    // Emit to all but let the first perform the fatal error.
    if let first = logs.first {
      // Emit to the rest at critical
      for log in logs.dropFirst() {
        log.error(describable ?? "", file: file, function: function, line: line)
      }
      first.guard(describable, file: file, function: function, line: line)
    } else {
      fatalError("LogGroup.guard called with no logs configured")
    }
  }
}
