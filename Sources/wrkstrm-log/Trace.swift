// Lightweight stderr tracer, opt-in via env var.
// Enable by setting `WRKSTRMLOG_TRACE=1` (all topics) or a comma list of topics
// in `WRKSTRMLOG_TRACE_TOPICS` (e.g., pathInfo,inject,cache,effective).

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
#if canImport(Foundation)
import Foundation
#endif

enum LogTrace {
  #if canImport(Foundation)
  private static let enabled: Bool = {
    let env = ProcessInfo.processInfo.environment
    if let v = env["WRKSTRMLOG_TRACE"]?.lowercased() {
      return v == "1" || v == "true" || v == "yes" || v == "on"
    }
    return false
  }()
  private static let topics: Set<String> = {
    let env = ProcessInfo.processInfo.environment
    guard let raw = env["WRKSTRMLOG_TRACE_TOPICS"], !raw.isEmpty else { return [] }
    return Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
  }()
  #else
  private static let enabled = false
  private static let topics = Set<String>()
  #endif

  static func log(_ topic: String, _ message: @autoclosure () -> String) {
    #if canImport(Darwin) || canImport(Glibc)
    guard enabled || topics.contains(topic) else { return }
    let line = "[WrkstrmLog:\(topic)] \(message())\n"
    #if canImport(Darwin)
    fputs(line, Darwin.stderr)
    #elseif canImport(Glibc)
    fputs(line, Glibc.stderr)
    #endif
    #endif
  }
}

