import Testing

@testable import WrkstrmLog

@Suite("WrkstrmLog")
struct WrkstrmLogTests {
  @Test
  func example() {
    #expect(true)
  }

  @Test
  func swiftLoggerReuse() {
    Log._reset()
    var log = Log(style: .swift)
    log.info("first")
    #expect(Log._swiftLoggerCount == 1)

    var mutated = log
    mutated.maxFunctionLength = 10
    mutated.info("second")
    #expect(Log._swiftLoggerCount == 1)
  }

  @Test
  func hashingIgnoresMutableProperties() {
    let log = Log(system: "sys", category: "cat")
    var hasher1 = Hasher()
    log.hash(into: &hasher1)
    let original = hasher1.finalize()

    var mutated = log
    mutated.maxFunctionLength = 12
    var hasher2 = Hasher()
    mutated.hash(into: &hasher2)
    let mutatedHash = hasher2.finalize()

    #expect(original == mutatedHash)
  }

  @Test
  func pathEncoding() {
    let logger = Log(system: "Test", category: "Encoding", style: .print)
    logger.info("Testing path", file: "/tmp/Some Folder/File Name.swift")
    #expect(true)
  }

  @Test
  func disabledProducesNoLoggers() {
    Log._reset()
    Log.disabled.info("silence")
    #expect(Log._swiftLoggerCount == 0)
  }

  #if DEBUG
    @Test
    func defaultLoggerNotDisabledInDebug() {
      let log = Log()
      #expect(log.style != .disabled)
    }
  #else
    @Test
    func defaultLoggerDisabledInRelease() {
      Log._reset()
      let log = Log()
      log.info("silence")
      #expect(log.style == .disabled)
      #expect(Log._swiftLoggerCount == 0)
    }
  #endif
}
