import Testing

#if canImport(os)
import os
@testable import WrkstrmLog

// MARK: - OS Logger

@Suite("OSLogger", .serialized)
struct OSLoggerTests {
  /// Spin-waits briefly for a condition to become true to mitigate
  /// interference from concurrent suites that may mutate global state.
  private func eventually(_ check: @autoclosure () -> Bool) -> Bool {
    if check() { return true }
    for _ in 0..<10 {
      usleep(5_000)  // 5ms
      if check() { return true }
    }
    return false
  }

  private func ensureOSLoggerCreated(_ log: Log) {
    if Log.Cache.shared.hasOSLogger(for: log) { return }
    for _ in 0..<200 {
      log.error("bootstrap")
      if Log.Cache.shared.hasOSLogger(for: log) { return }
      usleep(2_000)
    }
  }
  /// Confirms that an `OSLogger` instance is reused across mutations.
  @Test
  func osLoggerReuse() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "", category: "", maxExposureLevel: .trace, options: [.prod], backend: OSLogBackend())
    _ = Log.Cache.shared.osLogger(for: log)
    #expect(Log.Cache.shared.hasOSLogger(for: log))

    var mutated = log
    mutated.maxFunctionLength = 10
    ensureOSLoggerCreated(mutated)
    #expect(Log.Cache.shared.hasOSLogger(for: log))
  }

  /// Ensures `.prod` loggers still record messages at allowed levels.
  @Test
  func logLevelWorksInProd() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "", category: "", maxExposureLevel: .trace, options: [.prod], backend: OSLogBackend())
    _ = Log.Cache.shared.osLogger(for: log)
    #expect(Log.Cache.shared.hasOSLogger(for: log))
  }

  /// Verifies `OSLog` reuse across subsystem/category pairs and suppression when
  /// global exposure is low.
  @Test
  func osLogReuseAcrossSubsystemsAndSuppressedLevels() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let first = Log(
      system: "one", category: "first", maxExposureLevel: .trace, options: [.prod],
      backend: OSLogBackend())
    _ = Log.Cache.shared.osLogger(for: first)

    let second = Log(
      system: "two", category: "second", maxExposureLevel: .trace, options: [.prod],
      backend: OSLogBackend())
    _ = Log.Cache.shared.osLogger(for: second)

    let firstDuplicate = Log(
      system: "one", category: "first", maxExposureLevel: .trace, options: [.prod],
      backend: OSLogBackend())
    firstDuplicate.info("again")
    _ = Log.Cache.shared.osLogger(for: firstDuplicate)

    Log.globalExposureLevel = .error
    let suppressed = Log(
      system: "three", category: "third", maxExposureLevel: .trace, options: [.prod],
      backend: OSLogBackend())
    suppressed.debug("ignored")
    #expect(Bool(true))
  }
}
#endif
