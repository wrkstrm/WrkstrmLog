import Foundation
import os

public enum Log {

  public static var usePrint = false

  public static var maxFunctionLength: Int?

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
    column: UInt = #column)
  {
    log(
      .info, emoji: "ℹ️", string: string,
      file: file, function: function, line: line, column: column)
  }

  public static func error(
    _ string: String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column)
  {
    log(
      .error, emoji: "⚠️", string: string,
      file: file, function: function, line: line, column: column)
  }

  public static func `guard`(
    _ string: String = "",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column) -> Never
  {
    log(
      .fault, emoji: "❌", string: string,
      file: file, function: function, line: line, column: column)
    fatalError()
  }

  // swiftlint:disable:next function_parameter_count
  static func log(
    _ level: OSLogType,
    emoji: String,
    string: String,
    file: String,
    function: String,
    line: UInt,
    column _: UInt)
  {
    // swiftlint:disable:next force_unwrapping
    let url = URL(string: file.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    let fileName = url.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    let functionString = formattedFunction(function)
    if usePrint {
      print("\(emoji) \(fileName):\(String(line))-\(functionString)| " + string)
    } else {
      os_log(level, "%s %s-%i-%s: %s", emoji, url.lastPathComponent, line, functionString, string)
    }
  }
}
