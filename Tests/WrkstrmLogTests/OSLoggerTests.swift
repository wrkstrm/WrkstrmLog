import Testing

@testable import WrkstrmLog

@Suite("OSLogger", .serialized)
struct OSLoggerTests {
  /// Confirms that an `OSLogger` instance is reused across mutations.
  @Test
  func osLoggerReuse() {
    Log._reset()
    Log.globalExposureLevel = .trace
    let log = Log(style: .os, maxExposureLevel: .trace, options: [.prod])
    #expect(Log._osLoggerCount == 0)
    log.info("first")
    #expect(Log._osLoggerCount == 1)

    var mutated = log
    mutated.maxFunctionLength = 10
    mutated.info("second")
    #expect(Log._osLoggerCount == 1)
  }

  /// Ensures `.prod` loggers still record messages at allowed levels.
  @Test
  func logLevelWorksInProd() {
    Log._reset()
    Log.globalExposureLevel = .trace
    let log = Log(style: .os, maxExposureLevel: .trace, options: [.prod])
    log.info("not ignored")
    #expect(Log._osLoggerCount == 1)
  }
}
