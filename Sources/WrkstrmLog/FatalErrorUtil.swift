import Foundation

final class FatalErrorStorage: @unchecked Sendable {
  var handler: (String, StaticString, UInt) -> Never

  init() {
    handler = { message, file, line in
      Swift.fatalError(message, file: file, line: line)
    }
  }
}

let fatalErrorStorage = FatalErrorStorage()

func fatalErrorHandler(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #fileID,
  line: UInt = #line
) -> Never {
  fatalErrorStorage.handler(message(), file, line)
}
