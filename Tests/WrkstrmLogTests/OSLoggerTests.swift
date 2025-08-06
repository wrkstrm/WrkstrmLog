#if canImport(os)
  import os
  import Testing
  @testable import WrkstrmLog

  @Suite("OSLogger", .serialized)
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

    @Test
    func logLevelFiltersMessages() {
      Log._reset()
      let log = Log(style: .os, level: .error, options: [.prod])
      log.info("ignored")
      #expect(Log._osLoggerCount == 0)
    }

    #if DEBUG
      @Test
      func overrideLevelAdjustsLoggingInDebug() {
        Log._reset()
        let log = Log(style: .os, level: .error, options: [.prod])
        log.info("suppressed")
        #expect(Log._osLoggerCount == 0)
        Log.overrideLevel(for: log, to: .debug)
        log.info("logged")
        #expect(Log._osLoggerCount == 1)
      }
    #else
      @Test
      func overrideLevelNoEffectInRelease() {
        Log._reset()
        let log = Log(style: .os, level: .error, options: [.prod])
        log.info("suppressed")
        #expect(Log._osLoggerCount == 0)
        Log.overrideLevel(for: log, to: .debug)
        log.info("still suppressed")
        #expect(Log._osLoggerCount == 0)
      }
    #endif
  }
#endif
