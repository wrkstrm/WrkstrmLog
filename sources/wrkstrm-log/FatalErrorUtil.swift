#if canImport(Foundation) && !os(WASI)
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
#else
final class FatalErrorStorage: @unchecked Sendable {
  var handler: (String, StaticString, UInt) -> Never

  init() {
    handler = { message, file, line in
      // WASM: Foundation not available; still trap reliably.
      Swift.fatalError(message, file: file, line: line)
    }
  }
}

let fatalErrorStorage = FatalErrorStorage()

@inline(__always)
func fatalErrorHandler(
  _ message: @autoclosure () -> String = "",
  file: StaticString = #fileID,
  line: UInt = #line
) -> Never {
  fatalErrorStorage.handler(message(), file, line)
}
#endif
