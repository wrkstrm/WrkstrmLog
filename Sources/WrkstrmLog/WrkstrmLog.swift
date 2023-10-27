import Foundation
import Logging
import os

public enum Log: Hashable {

  public static var style: Log = .os(system: "com.wrkstrm.os-log", category: "default")

  public static var maxFunctionLength: Int?

  private static var swiftLoggers: [Log: Logging.Logger] = [:]

  private static var osLoggers: [Log: OSLog] = [:]

  case print(system: String, category: String)
  case os(system: String, category: String)
  case swift(system: String, category: String)

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
    case .print(let system, category: _):
      Swift.print("\(system)::\(emoji) \(fileName):\(String(line))|\(functionString)| " + string)

    case let .os(system, category):
      let logger = Self.osLoggers[
        Self.style, default: OSLog(subsystem: system, category: category)
      ]
      os_log(
        level.toOSType,
        dso: dso,
        log: logger,
        "%s-%i|%s| %s",
        url.lastPathComponent,
        line,
        functionString,
        string)

    case .swift(system: _, category: _):
      let logger = Self.swiftLoggers[
        Self.style,
        default: {
          var logger = Logger(label: "com.wrkstrm.swift-log.default")
          logger.logLevel = .debug
          return logger
        }()
      ]
      logger.log(
        level: level,
        "\(line)|\(functionString)| \(string)",
        source: url.lastPathComponent,
        file: file,
        function: functionString,
        line: line)
    }
  }

  public func verbose(
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

  public func error(
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

  public func `guard`(
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
  func log(
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
    let functionString = Self.formattedFunction(function)
    switch self {
    case .print(let system, category: _):
      Swift.print("\(system)::\(emoji) \(fileName):\(String(line))|\(functionString)| " + string)

    case let .os(system, category):
      let logger = Self.osLoggers[
        Self.style, default: OSLog(subsystem: system, category: category)
      ]
      os_log(
        level.toOSType,
        dso: dso,
        log: logger,
        "%s-%i|%s| %s",
        url.lastPathComponent,
        line,
        functionString,
        string)

    case .swift(let system, category: _):
      let logger = Self.swiftLoggers[
        Self.style,
        default: {
          var logger = Logger(label: system)
          logger.logLevel = .debug
          return logger
        }()
      ]
      logger.log(
        level: level,
        "\(line)|\(functionString)| \(string)",
        source: url.lastPathComponent,
        file: file,
        function: functionString,
        line: line)
    }
  }
}
