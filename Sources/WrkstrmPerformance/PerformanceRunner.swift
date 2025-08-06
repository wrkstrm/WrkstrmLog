import Foundation
import WrkstrmLog

/// Scaffolding for running and monitoring a subprocess.
public struct PerformanceRunner {
  public init() {}

  /// Launches a subprocess and returns the running `Process` instance.
  /// - Parameters:
  ///   - command: Path to the executable to run.
  ///   - arguments: Arguments to pass to the executable.
  /// - Returns: A running `Process` instance.
  @discardableResult
  public func run(command: String, arguments: [String]) throws -> Process {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: command)
    process.arguments = arguments
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    // TODO: Capture and report performance metrics.
    try process.run()
    return process
  }
}
