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
}
