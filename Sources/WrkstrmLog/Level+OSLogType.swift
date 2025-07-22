#if canImport(os)
  import Logging
  import os

  extension Logging.Logger.Level {
    /// Converts a `Logging.Logger.Level` to an `OSLogType`.
    ///
    /// This extension allows for mapping Swift Log levels to their equivalent OSLog types, which is
    /// useful for compatibility when using both logging frameworks.
    ///
    /// - Returns: An `OSLogType` equivalent to the Swift Log level.
    public var toOSType: OSLogType {
      switch self {
      case .trace:
        .debug

      case .debug:
        .debug

      case .info:
        .info

      case .notice:
        .default

      case .warning:
        .error

      case .error:
        .error

      case .critical:
        .fault
      }
    }
  }
#endif  // canImport(os)
