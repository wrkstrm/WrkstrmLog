import Foundation
import WrkstrmLog

@main
struct WrkstrmPerformanceCLI {
  static func main() throws {
    let arguments = CommandLine.arguments
    guard arguments.count > 1 else {
      print("Usage: WrkstrmPerformance <command> [arguments...]")
      return
    }
    let command = arguments[1]
    let commandArgs = Array(arguments.dropFirst(2))
    let runner = PerformanceRunner()
    let process = try runner.run(command: command, arguments: commandArgs)
    process.waitUntilExit()
    // TODO: Emit collected performance metrics here.
  }
}
