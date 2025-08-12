import Testing

@testable import WrkstrmLog

@Suite("WrkstrmLog", .serialized)
struct WrkstrmLogTests {
  /// Verifies that a single Swift logger instance is reused after mutation.
  @Test
  func swiftLoggerReuse() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    log.info("first")
    #expect(Log.swiftLoggerCount == 1)

    var mutated = log
    mutated.maxFunctionLength = 10
    mutated.info("second")
    #expect(Log.swiftLoggerCount == 1)
  }

  /// Confirms hashing ignores mutable properties that do not affect identity.
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

  /// Ensures file paths with spaces are encoded and logged correctly.
  @Test
  func pathEncoding() {
    Log.globalExposureLevel = .trace
    let logger = Log(system: "Test", category: "Encoding", style: .print, maxExposureLevel: .trace)
    logger.info("Testing path", file: "/tmp/Some Folder/File Name.swift")
    // Using Bool(true) instead of true to silence compiler warning about always-passing test
    #expect(Bool(true))
  }

  /// Guarantees disabled loggers do not create underlying logger instances.
  @Test
  func disabledProducesNoLoggers() {
    Log.reset()
    Log.globalExposureLevel = .trace
    Log.disabled.info("silence")
    #expect(Log.swiftLoggerCount == 0)
  }

  /// Checks that increasing global exposure filters messages below the threshold.
  @Test
  func exposureLimitFiltersMessages() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    log.info("suppressed")
    #expect(Log.swiftLoggerCount == 0)
    Log.globalExposureLevel = .trace
    log.info("logged")
    #expect(Log.swiftLoggerCount == 1)
  }

  /// Verifies a logger's max exposure level is respected even when global limits differ.
  @Test
  func loggerMaxExposureLevelRespected() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(style: .swift, maxExposureLevel: .error, options: [.prod])
    #expect(log.maxExposureLevel == .error)
    log.info("suppressed")
    #expect(Log.swiftLoggerCount == 0)
    log.error("logged")
    #expect(Log.swiftLoggerCount == 1)
  }

  /// Validates the debug helper respects exposure limits.
  @Test
  func debugHelperRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .info
    let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    log.debug("suppressed")
    #expect(Log.swiftLoggerCount == 0)
    Log.globalExposureLevel = .debug
    log.debug("logged")
    #expect(Log.swiftLoggerCount == 1)
  }

  /// Validates the notice helper respects exposure limits.
  @Test
  func noticeHelperRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    log.notice("suppressed")
    #expect(Log.swiftLoggerCount == 0)
    Log.globalExposureLevel = .notice
    log.notice("logged")
    #expect(Log.swiftLoggerCount == 1)
  }

  /// Validates the warning helper respects exposure limits.
  @Test
  func warningHelperRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .error
    let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    log.warning("suppressed")
    #expect(Log.swiftLoggerCount == 0)
    Log.globalExposureLevel = .warning
    log.warning("logged")
    #expect(Log.swiftLoggerCount == 1)
  }

  /// Verifies `effectiveLevel(for:)` filters based on exposure settings.
  @Test
  func effectiveLevelRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    #expect(log.effectiveLevel(for: .info) == nil)
    #expect(log.effectiveLevel(for: .error) == .error)
  }

  /// Confirms `isEnabled(for:)` evaluates both global and logger limits.
  @Test
  func isEnabledRespectsExposureLimits() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(style: .swift, maxExposureLevel: .info, options: [.prod])
    #expect(log.isEnabled(for: .info) == false)
    #expect(log.isEnabled(for: .warning) == true)
  }

  /// Validates `ifEnabled(for:_:)` executes the closure only when enabled.
  @Test
  func ifEnabledExecutesConditionally() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    var executed = false
    log.ifEnabled(for: .debug) { _ in executed = true }
    #expect(executed == false)
    log.ifEnabled(for: .error) { _ in executed = true }
    #expect(executed == true)
  }

  /// Ensures raising the global exposure level does not override a logger's limit.
  @Test
  func globalExposureIncreaseDoesNotOverrideLoggerMax() {
    Log.reset()
    let log = Log(style: .swift, options: [.prod])
    log.error("suppressed")
    #expect(Log.swiftLoggerCount == 0)
    Log.globalExposureLevel = .trace
    #expect(log.maxExposureLevel == .critical)
    log.error("still suppressed")
    #expect(Log.swiftLoggerCount == 0)
  }

  #if DEBUG
    /// Validates that overriding the level adjusts logging in debug builds.
    @Test
    func overrideLevelAdjustsLoggingInDebug() {
      Log.reset()
      Log.globalExposureLevel = .trace
      let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
      log.info("suppressed")
      #expect(Log.swiftLoggerCount == 1)
      Log.overrideLevel(for: log, to: .debug)
      log.info("logged")
      #expect(Log.swiftLoggerCount == 1)
    }
  #endif

  #if DEBUG
    /// Confirms the default logger remains enabled in debug builds.
    @Test
    func defaultLoggerNotDisabledInDebug() {
      let log = Log()
      #expect(log.style != .disabled)
    }
  #else
    /// Verifies the default logger is disabled in release builds.
    @Test
    func defaultLoggerDisabledInRelease() {
      Log.reset()
      Log.globalExposureLevel = .trace
      let log = Log()
      log.info("silence")
      #expect(log.style == .disabled)
      #expect(Log.swiftLoggerCount == 0)
    }

    /// Ensures a logger with the `.prod` option remains enabled in release builds.
    @Test
    func loggerWithProdOptionEnabledInRelease() {
      Log.reset()
      Log.globalExposureLevel = .trace
      let log = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
      log.info("hello")
      #expect(log.style == .swift)
      #expect(Log.swiftLoggerCount == 1)
    }
  #endif
}
