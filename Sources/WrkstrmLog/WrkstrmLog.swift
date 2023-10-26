import Foundation
import Logging
import os

let swiftLogger: Logging.Logger = { () -> Logging.Logger in
  var logger = Logger(label: "com.wrkstrm.swift-log.default")
  logger.logLevel = .debug
  return logger
}()

let osLogger = OSLog(subsystem: "com.wrkstrm.os-log", category: "default")

public enum Log {

  public static var style: Log = .os

  public static var maxFunctionLength: Int?

  case print
  case os
  case swift

  static func formattedFunction(_ function: String) -> String {
    let functionString: String
    if let maxLength = maxFunctionLength {
      functionString = String(function.prefix(maxLength))
    } else {
      functionString = function
    }
    return functionString
  }

  public static func verbose(
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle)
  {
    log(
      .info, emoji: "ℹ️", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
  }

  public static func error(
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle)
  {
    log(
      .error, emoji: "⚠️", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
  }

  public static func `guard`(
    _ string: String = "",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle) -> Never
  {
    log(
      .critical, emoji: "❌", string: string,
      file: file, function: function, line: line, column: column, dso: dso)
    fatalError()
  }

  // swiftlint:disable:next function_parameter_count
  static func log(
    _ level: Logging.Logger.Level,
    emoji: String,
    string: String,
    file: String,
    function: String,
    line: UInt,
    column _: UInt,
    dso: UnsafeRawPointer)
  {
    // swiftlint:disable:next force_unwrapping
    let url = URL(string: file.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    let fileName = url.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    let functionString = formattedFunction(function)
    switch style {
    case .print:
      Swift.print("\(emoji) \(fileName):\(String(line))|\(functionString)| " + string)

    case .os:
      os_log(
        level.toOSType,
        dso: dso,
        log: osLogger,
        "%s-%i|%s| %s",
        url.lastPathComponent,
        line,
        functionString,
        string)

    case .swift:
      swiftLogger.log(
        level: level,
        "\(line)|\(functionString)| \(string)",
        source: url.lastPathComponent,
        file: file,
        function: functionString,
        line: line)
    }
  }
}
