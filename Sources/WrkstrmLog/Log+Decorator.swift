import Logging

#if canImport(Foundation)
import Foundation
#endif
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public protocol LogDecorator: Sendable {
  func format(
    _ level: Logging.Logger.Level,
    message: @autoclosure () -> Any,
    logger: Log,
    file: String,
    function: String,
    line: UInt,
    context: any CommonLogContext
  ) -> String
}

extension Log {
  public enum Decorator {
    /// Current output style used across backends.
    /// - Print: "filename:line|function| message"
    /// - SwiftLog: same formatted message body; `source` provided separately
    /// - OSLog: decorator not applied (positional os_log formatting remains)
    public struct Current: LogDecorator, Sendable {
      public init() {}

      public func format(
        _ level: Logging.Logger.Level,
        message: @autoclosure () -> Any,
        logger: Log,
        file: String,
        function: String,
        line: UInt,
        context: any CommonLogContext
      ) -> String {
        let fileName = context.fileName(for: file)
        let fn = context.formattedFunction(function, maxLength: logger.maxFunctionLength)
        return "\(fileName):\(String(line))|\(fn)| " + String(describing: message())
      }
    }

    /// Plain output: only the message body; no file/function/line metadata.
    ///
    /// Backends may still include their own headers (e.g., system/category/emoji for Print, or
    /// source/file/line passed separately for SwiftLog).
    public struct Plain: LogDecorator, Sendable {
      public init() {}

      public func format(
        _ level: Logging.Logger.Level,
        message: @autoclosure () -> Any,
        logger: Log,
        file: String,
        function: String,
        line: UInt,
        context: any CommonLogContext
      ) -> String {
        String(describing: message())
      }
    }

    #if canImport(Foundation)
    /// JSON output: encodes message and metadata in a single JSON object string.
    /// Keys: level, message, system, category, file, function, line
    public struct JSON: LogDecorator, Sendable {
      public init() {}

      public func format(
        _ level: Logging.Logger.Level,
        message: @autoclosure () -> Any,
        logger: Log,
        file: String,
        function: String,
        line: UInt,
        context: any CommonLogContext
      ) -> String {
        let fileName = context.fileName(for: file)
        let fn = context.formattedFunction(function, maxLength: logger.maxFunctionLength)
        // Timestamp (ISO8601 when available)
        let timestamp: String = {
          #if canImport(Foundation)
          guard #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) else {
            return String(Date().timeIntervalSince1970)
          }
          let f = ISO8601DateFormatter()
          f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          return f.string(from: Date())
          #else
          return "0"
          #endif
        }()

        // Thread info (best-effort)
        var threadId: UInt64? = nil
        #if canImport(Darwin)
        var tid: UInt64 = 0
        if pthread_threadid_np(nil, &tid) == 0 { threadId = tid }
        #elseif canImport(Glibc)
        let tid = syscall(SYS_gettid)
        if tid > 0 { threadId = UInt64(tid) }
        #endif

        var dict: [String: Any] = [
          "level": String(describing: level),
          "message": String(describing: message()),
          "system": logger.system,
          "category": logger.category,
          "file": fileName,
          "function": fn,
          "line": line,
          "timestamp": timestamp,
          "isMainThread": Thread.isMainThread,
        ]
        if let threadId { dict["threadId"] = threadId }
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
          return String(data: data, encoding: .utf8) ?? String(describing: message())
        }
        return String(describing: message())
      }
    }
    #endif
  }
}
