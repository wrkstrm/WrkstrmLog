import Testing

@testable import WrkstrmLog

@Suite("WrkstrmLog")
struct WrkstrmLogTests {
  @Test
  func example() {
    Log.error("This is interesting.")
    Log.verbose("This is a log.")
    #expect(true)
  }

  @Test
  func swiftLoggerReuse() {
    Log._reset()
    let log = Log(system: "sys", category: "cat")
    log.info("first")
    #expect(log._hasSwiftLogger())

    log.info("second")
    #expect(log._hasSwiftLogger())
  }

}
