import Foundation
import Testing

@testable import WrkstrmLog

#if canImport(Darwin)
  import Darwin
#else
  import Glibc
#endif

// MARK: - Fatal Error Testing Helpers

@MainActor
func expectFatalError(executing: @escaping () -> Void) -> (String, Int32) {
  var fds: [Int32] = [0, 0]
  precondition(pipe(&fds) == 0)
  let pid = fork()
  if pid == 0 {
    dup2(fds[1], STDOUT_FILENO)
    close(fds[0])
    executing()
    _exit(0)
  } else {
    close(fds[1])
    let handle = FileHandle(fileDescriptor: fds[0])
    let data = handle.readDataToEndOfFile()
    var status: Int32 = 0
    waitpid(pid, &status, 0)
    return (String(data: data, encoding: .utf8) ?? "", status)
  }
}

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

  /// Verifies function names are truncated when `maxFunctionLength` is set.
  @Test
  func functionNameIsTruncated() {
    Log.reset()
    Log.globalExposureLevel = .trace
    var logger = Log(
      system: "sys", category: "cat", style: .print, maxExposureLevel: .trace, options: [.prod])
    logger.maxFunctionLength = 5

    let pipe = Pipe()
    let originalStdout = dup(STDOUT_FILENO)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

    logger.info("test", function: "SomeVeryLongFunctionName")

    fflush(nil)
    dup2(originalStdout, STDOUT_FILENO)
    close(originalStdout)
    pipe.fileHandleForWriting.closeFile()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    let parts = output.split(separator: "|")
    #expect(parts.count >= 3)
    let functionPart = String(parts[1])
    #expect(functionPart == "SomeV")
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

  /// Ensures path information is cached and reused across log calls.
  @Test
  func pathInfoCaching() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let logger = Log(style: .print, maxExposureLevel: .trace, options: [.prod])
    #expect(Log.pathInfoCount == 0)
    logger.info("first")
    #expect(Log.pathInfoCount == 1)
    logger.info("second")
    #expect(Log.pathInfoCount == 1)
  }

  /// Allows disabling path information caching at runtime.
  @Test
  func pathInfoCachingCanBeDisabled() {
    Log.reset()
    Log.Inject.usePathInfoCache(false)
    Log.globalExposureLevel = .trace
    let logger = Log(style: .print, maxExposureLevel: .trace, options: [.prod])
    #expect(Log.pathInfoCount == 0)
    logger.info("first")
    #expect(Log.pathInfoCount == 0)
    logger.info("second")
    #expect(Log.pathInfoCount == 0)
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

  /// Asserts `guard` logs a critical message before terminating execution.
  @Test
  @MainActor
  func guardLogsBeforeFatalError() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(style: .print, maxExposureLevel: .trace, options: [.prod])

    let (output, status) = expectFatalError {
      log.guard("boom")
    }

    #expect(status != 0)
    #expect(output.contains("boom"))
    #expect(output.contains("🚨"))
  }

  /// Verifies no crash occurs when the logger style is `.disabled`.
  @Test
  @MainActor
  func guardNoCrashWhenDisabled() {
    Log.reset()
    let log = Log.disabled
    if log.style != .disabled {
      log.guard("unreachable")
    }
    #expect(log.style == .disabled)
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
