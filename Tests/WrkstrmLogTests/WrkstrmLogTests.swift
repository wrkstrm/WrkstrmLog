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
  func pathEncoding() {
    let logger = Log(system: "Test", category: "Encoding", style: .print)
    logger.info("Testing path", file: "/tmp/Some Folder/File Name.swift")
    #expect(true)
  }
}
