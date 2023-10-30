#if canImport(os)
import Logging
import os

extension Logging.Logger.Level {
  /// Converts an OSLogType to a Swift Log Logger Level.
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
