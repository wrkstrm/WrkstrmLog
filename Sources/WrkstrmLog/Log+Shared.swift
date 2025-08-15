import Foundation

extension Log {
  /// The shared logger instance, often used for default logging.
  /// This shared instance can be conveniently used throughout your application.
  ///
  /// Example usage:
  /// ```
  /// Log.shared.info("Application started")
  /// ```
  public nonisolated(unsafe) static var shared =
    Log(system: "wrkstrm", category: "shared", maxExposureLevel: .trace)
  {
    didSet {
      #if DEBUG
      if let mask = Cache.shared.removeOverride(for: oldValue) {
        Cache.shared.overrideLevel(for: shared, to: mask.minimumLevel)
      }
      #endif
      shared.verbose("New Logger: \(shared)")
    }
  }

  /// Logs a verbose message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public static func verbose(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    Log.shared.verbose(
      describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a debug message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public static func debug(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    Log.shared.debug(
      describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs an info message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public static func info(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    Log.shared.info(
      describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a notice message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public static func notice(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    Log.shared.notice(
      describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a warning message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public static func warning(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    Log.shared.warning(
      describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs an error message with the specified parameters.
  ///
  /// - Parameters:
  ///   - describable: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  public static func error(
    _ describable: Any,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) {
    Log.shared.error(
      describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }

  /// Logs a critical message and triggers a fatal error.
  ///
  /// - Parameters:
  ///   - describable: The message string to log.
  ///   - file: The source file where the log message is generated.
  ///   - function: The name of the function where the log message is generated.
  ///   - line: The line number in the source file where the log message is generated.
  ///   - column: The column number in the source file where the log message is generated.
  ///   - dso: The address of the shared object where the log message is generated.
  /// - Returns: Never, indicating a fatal error.
  public static func `guard`(
    _ describable: Any? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle,
  ) -> Never {
    Log.shared.guard(
      describable,
      file: file,
      function: function,
      line: line,
      column: column,
      dso: dso,
    )
  }
}
