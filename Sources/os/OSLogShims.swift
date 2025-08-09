#if !canImport(Darwin)
  import Foundation

  public struct OSLog {
    public init(subsystem: String, category: String) {}
  }

  public struct OSLogType: RawRepresentable, Equatable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let debug = OSLogType(rawValue: 0)
    public static let info = OSLogType(rawValue: 1)
    public static let `default` = OSLogType(rawValue: 2)
    public static let error = OSLogType(rawValue: 3)
    public static let fault = OSLogType(rawValue: 4)
  }
  // swift-format-ignore: AlwaysUseLowerCamelCase
  public func os_log(
    _ type: OSLogType,
    dso: UnsafeRawPointer?,
    log: OSLog,
    _ format: UnsafePointer<CChar>,
    _ args: CVarArg...
  ) {
    // no-op stub
  }
#endif
