import Logging
import os

public extension Logging.Logger.Level {

  var toOSType: OSLogType {
    switch self {
    case .critical:
      .fault

    case .info:
      .info

    case .trace:
      .info

    case .debug:
      .debug

    case .error:
      .error

    case .notice:
      .default

    case .warning:
      .error
    }
  }
}
