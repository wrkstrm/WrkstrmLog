#if canImport(os)
import os
import Testing
@testable import WrkstrmLog

@Suite("OSLogger")
struct OSLoggerTests {
  @Test
  func osLoggerReuse() {
    Log._reset()
    let log = Log(system: "sys", category: "cat")
    log.info("first")
    #expect(log._hasOSLogger())

    log.info("second")
    #expect(log._hasOSLogger())
  }
}
#endif
