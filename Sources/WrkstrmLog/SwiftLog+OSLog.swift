import Logging
import os

public extension Logging.Logger.Level {

  var toOSType: OSLogType {
    switch self {
    case .critical:
      return .fault

    case .info:
      return .info

    case .trace:
      return .info

    case .debug:
      return .debug

    case .error:
      return .error

    case .notice:
      return .default

    case .warning:
      return .error
    }
  }
}
