import Testing

@testable import WrkstrmLog

@Suite("WrkstrmLog", .serialized)
struct WrkstrmLogTests {
  @Test
  func example() {
    #expect(true)
  }

  @Test
  func swiftLoggerReuse() {
    Log._reset()
    Log.limitExposure(to: .trace)
    let log = Log(style: .swift, exposure: .trace, options: [.prod])
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
    Log.limitExposure(to: .trace)
    let logger = Log(system: "Test", category: "Encoding", style: .print, exposure: .trace)
    logger.info("Testing path", file: "/tmp/Some Folder/File Name.swift")
    #expect(true)
  }

  @Test
  func disabledProducesNoLoggers() {
    Log._reset()
    Log.limitExposure(to: .trace)
    Log.disabled.info("silence")
    #expect(Log._swiftLoggerCount == 0)
  }

  @Test
  func logLevelFiltersMessages() {
    Log._reset()
    Log.limitExposure(to: .trace)
    let log = Log(style: .swift, level: .error, exposure: .trace, options: [.prod])
    log.info("ignored")
    #expect(Log._swiftLoggerCount == 0)
  }

  @Test
  func exposureLimitFiltersMessages() {
    Log._reset()
    Log.limitExposure(to: .warning)
    let log = Log(style: .swift, exposure: .trace, options: [.prod])
    log.info("suppressed")
    #expect(Log._swiftLoggerCount == 0)
    Log.limitExposure(to: .trace)
    log.info("logged")
    #expect(Log._swiftLoggerCount == 1)
  }

  @Test
  func loggerExposureLimitRespected() {
    Log._reset()
    Log.limitExposure(to: .trace)
    let log = Log(style: .swift, exposure: .error, options: [.prod])
    #expect(log.maxExposureLevel == .error)
    log.info("suppressed")
    #expect(Log._swiftLoggerCount == 0)
    log.error("logged")
    #expect(Log._swiftLoggerCount == 1)
  }

  @Test
  func globalExposureIncreaseDoesNotOverrideLoggerLimit() {
    Log._reset()
    let log = Log(style: .swift, level: .trace, options: [.prod])
    log.error("suppressed")
    #expect(Log._swiftLoggerCount == 0)
    Log.limitExposure(to: .trace)
    #expect(log.maxExposureLevel == .critical)
    log.error("still suppressed")
    #expect(Log._swiftLoggerCount == 0)
  }

  #if DEBUG
    @Test
    func overrideLevelAdjustsLoggingInDebug() {
      Log._reset()
      Log.limitExposure(to: .trace)
      let log = Log(style: .swift, level: .error, exposure: .trace, options: [.prod])
      log.info("suppressed")
      #expect(Log._swiftLoggerCount == 0)
      Log.overrideLevel(for: log, to: .debug)
      log.info("logged")
      #expect(Log._swiftLoggerCount == 1)
    }
  #else
    @Test
    func overrideLevelNoEffectInRelease() {
      Log._reset()
      Log.limitExposure(to: .trace)
      let log = Log(style: .swift, level: .error, exposure: .trace, options: [.prod])
      log.info("suppressed")
      #expect(Log._swiftLoggerCount == 0)
      Log.overrideLevel(for: log, to: .debug)
      log.info("still suppressed")
      #expect(Log._swiftLoggerCount == 0)
    }
  #endif

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
      Log.limitExposure(to: .trace)
      let log = Log()
      log.info("silence")
      #expect(log.style == .disabled)
      #expect(Log._swiftLoggerCount == 0)
    }

    @Test
    func loggerWithProdOptionEnabledInRelease() {
      Log._reset()
      Log.limitExposure(to: .trace)
      let log = Log(style: .swift, exposure: .trace, options: [.prod])
      log.info("hello")
      #expect(log.style == .swift)
      #expect(Log._swiftLoggerCount == 1)
    }
  #endif
}
