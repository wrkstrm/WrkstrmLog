import Foundation
import Logging
import os

public struct Log: Hashable {

  public enum Style {
    case print
    case os
    case swift
  }

  public static var shared: Log = .init(system: "wrkstrm", category: "shared") {
    didSet {
      shared.verbose("New Logger: \(shared)")
    }
  }

  public var system: String
  public var category: String
  public var style: Style = .os

  private static var osLoggers: [Log: OSLog] = [:]

  private static var swiftLoggers: [Log: Logging.Logger] = [:]

  public init(system: String, category: String, style: Style = .os) {
    self.system = system
    self.category = category
    self.style = style
  }

  public var maxFunctionLength: Int?

  func formattedFunction(_ function: String) -> String {
    guard let maxLength = maxFunctionLength else {
      return function
    }
    return String(function.prefix(maxLength))
  }

  public static func verbose(
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle
  ) {
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
    dso: UnsafeRawPointer = #dsohandle
  ) {
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
    dso: UnsafeRawPointer = #dsohandle
  ) -> Never {
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
    column: UInt,
    dso: UnsafeRawPointer
  ) {
    Log.shared.log(
      level, emoji: emoji, string: string, file: file, function: function, line: line,
      column: column, dso: dso)
  }

  public func verbose(
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    dso: UnsafeRawPointer = #dsohandle
  ) {
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
    dso: UnsafeRawPointer = #dsohandle
  ) {
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
    dso: UnsafeRawPointer = #dsohandle
  ) -> Never {
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
    dso: UnsafeRawPointer
  ) {
    // swiftlint:disable:next force_unwrapping
    let url = URL(string: file.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    let fileName = url.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    let functionString = formattedFunction(function)
    switch style {
      case .print:
        Swift.print("\(system)::\(emoji) \(fileName):\(String(line))|\(functionString)| " + string)

      case .os:
        let logger = Self.osLoggers[
          self, default: OSLog(subsystem: system, category: category)
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

      case .swift:
        let logger = Self.swiftLoggers[
          self,
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
