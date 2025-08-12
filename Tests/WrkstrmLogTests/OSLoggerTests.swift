import Testing

#if canImport(os)
  import os
  @testable import WrkstrmLog

  @Suite("OSLogger", .serialized)
  struct OSLoggerTests {
    /// Confirms that an `OSLogger` instance is reused across mutations.
    @Test
    func osLoggerReuse() {
      Log.reset()
      Log.globalExposureLevel = .trace
      let log = Log(style: .os, maxExposureLevel: .trace, options: [.prod])
      #expect(Log.osLoggerCount == 0)
      log.info("first")
      #expect(Log.osLoggerCount == 1)

      var mutated = log
      mutated.maxFunctionLength = 10
      mutated.info("second")
      #expect(Log.osLoggerCount == 1)
    }

    /// Ensures `.prod` loggers still record messages at allowed levels.
    @Test
    func logLevelWorksInProd() {
      Log.reset()
      Log.globalExposureLevel = .trace
      let log = Log(style: .os, maxExposureLevel: .trace, options: [.prod])
      log.info("not ignored")
      #expect(Log.osLoggerCount == 1)
    }

    /// Verifies `OSLog` reuse across subsystem/category pairs and suppression when
    /// global exposure is low.
    @Test
    func osLogReuseAcrossSubsystemsAndSuppressedLevels() {
      Log.reset()
      Log.globalExposureLevel = .trace
      let first = Log(
        system: "one", category: "first", style: .os, maxExposureLevel: .trace, options: [.prod])
      first.info("initial")
      #expect(Log.osLoggerCount == 1)

      let second = Log(
        system: "two", category: "second", style: .os, maxExposureLevel: .trace, options: [.prod])
      second.info("next")
      #expect(Log.osLoggerCount == 2)

      let firstDuplicate = Log(
        system: "one", category: "first", style: .os, maxExposureLevel: .trace, options: [.prod])
      firstDuplicate.info("again")
      #expect(Log.osLoggerCount == 2)

      Log.globalExposureLevel = .error
      let suppressed = Log(
        system: "three", category: "third", style: .os, maxExposureLevel: .trace, options: [.prod])
      suppressed.debug("ignored")
      #expect(Log.osLoggerCount == 2)
      #expect(!Log.Cache.shared.hasOSLogger(for: suppressed))
    }
  }
#endif
