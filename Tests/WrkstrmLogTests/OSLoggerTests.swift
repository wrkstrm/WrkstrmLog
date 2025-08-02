#if canImport(os)
import os
import Testing
@testable import WrkstrmLog

@Suite("OSLogger")
struct OSLoggerTests {
  @Test
  func osLoggerReuse() {
    Log._reset()
    var log = Log()
    log.info("first")
    #expect(Log._osLoggerCount == 1)

    var mutated = log
    mutated.maxFunctionLength = 10
    mutated.info("second")
    #expect(Log._osLoggerCount == 1)
  }
}
#endif
