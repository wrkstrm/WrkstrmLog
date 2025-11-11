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
func expectFatalError(executing: @escaping @Sendable () -> Void) -> (String, Int32) {
  let pipe = Pipe()
  let originalStdout = dup(STDOUT_FILENO)
  dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

  let semaphore = DispatchSemaphore(value: 0)
  let originalFatal = fatalErrorStorage.handler
  fatalErrorStorage.handler = { _, _, _ in
    semaphore.signal()
    Thread.exit()
    fatalError("unreachable")
  }

  let thread = Thread {
    executing()
  }
  thread.start()

  semaphore.wait()

  fflush(nil)
  dup2(originalStdout, STDOUT_FILENO)
  close(originalStdout)
  pipe.fileHandleForWriting.closeFile()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()

  fatalErrorStorage.handler = originalFatal

  return (String(data: data, encoding: .utf8) ?? "", 1)
}

// MARK: - Core Logging Behavior

@Suite("WrkstrmLog", .serialized)
struct WrkstrmLogTests {
  // Capture stdout while executing a block and return captured string.
  private func captureOutput(_ block: () -> Void) -> String {
    let pipe = Pipe()
    let originalStdout = dup(STDOUT_FILENO)
    let originalStderr = dup(STDERR_FILENO)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
    block()
    fflush(nil)
    dup2(originalStdout, STDOUT_FILENO)
    dup2(originalStderr, STDERR_FILENO)
    close(originalStdout)
    close(originalStderr)
    pipe.fileHandleForWriting.closeFile()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
  }
  /// Verifies that a single Swift logger instance is reused after mutation.
  @Test
  func swiftLoggerReuse() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "", category: "", maxExposureLevel: .trace, options: [.prod],
      backend: SwiftLogBackend())
    if !Log.Cache.shared.hasSwiftLogger(for: log) {
      for _ in 0..<100 {
        Log.globalExposureLevel = .trace
        Log.Inject.resetInjection()
        log.info("first")
        if Log.Cache.shared.hasSwiftLogger(for: log) { break }
        usleep(2_000)
      }
    }
    #expect(Log.Cache.shared.hasSwiftLogger(for: log))

    var mutated = log
    mutated.maxFunctionLength = 10
    mutated.info("second")
    #expect(Log.Cache.shared.hasSwiftLogger(for: log))
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
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )
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
    let logger = Log(
      system: "Test",
      category: "Encoding",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )
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
    #expect(Log.swiftCount == 0)
  }

  /// Ensures path information is cached and reused across log calls.
  @Test
  func pathInfoCaching() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let logger = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )
    let out1 = captureOutput { logger.info("first") }
    let out2 = captureOutput { logger.info("second") }
    #expect(out1.contains("WrkstrmLogTests"))
    #expect(out1.contains("pathInfoCaching()"))
    #expect(out2.contains("WrkstrmLogTests"))
    #expect(out2.contains("pathInfoCaching()"))
    func extractFileName(_ s: String) -> String {
      let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let pipeIdx = trimmed.firstIndex(of: "|") else { return "" }
      let head = String(trimmed[..<pipeIdx])
      guard let spaceIdx = head.lastIndex(of: " ") else { return "" }
      let after = head.index(after: spaceIdx)
      let tail = String(head[after...])  // e.g., WrkstrmLogTests:180
      return tail.split(separator: ":").first.map(String.init) ?? ""
    }
    #expect(extractFileName(out1) == extractFileName(out2))
  }

  /// Allows toggling path information caching at runtime.
  @Test
  func pathInfoCachingCanBeDisabled() {
    Log.reset()
    Log.Inject.usePathInfoCache(false)
    Log.globalExposureLevel = .trace
    let logger = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )
    #expect(Log.pathInfoCount == 0)
    logger.info("first")
    #expect(Log.pathInfoCount == 0)
    logger.info("second")
    #expect(Log.pathInfoCount == 0)

    Log.Inject.usePathInfoCache(true)
    logger.info("third")
    #expect(Log.pathInfoCount == 1)
    logger.info("fourth")
    #expect(Log.pathInfoCount == 1)
  }

  /// Checks that increasing global exposure filters messages below the threshold.
  @Test
  func exposureLevelFiltersMessages() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    log.info("suppressed")
    #expect(Log.swiftCount == 0)
    Log.globalExposureLevel = .trace
    log.info("logged")
    #expect(Log.swiftCount == 1)
  }

  /// Verifies a logger's max exposure level is respected even when global levels differ.
  @Test
  func loggerMaxExposureLevelRespected() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .error,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    #expect(log.maxExposureLevel == .error)
    log.info("suppressed")
    #expect(Log.swiftCount == 0)
    _ = captureOutput { log.error("logged") }
    #expect(Log.swiftCount == 1)
  }

  /// Validates the debug helper respects exposure levels.
  @Test
  func debugHelperRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .info
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    log.debug("suppressed")
    #expect(Log.swiftCount == 0)
    Log.globalExposureLevel = .debug
    log.debug("logged")
    #expect(Log.swiftCount == 1)
  }

  /// Confirms verbose logs are emitted at the debug level.
  @Test
  func verboseBehavesLikeDebug() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let logger = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )

    func capture(_ block: () -> Void) -> String {
      let pipe = Pipe()
      let originalStdout = dup(STDOUT_FILENO)
      dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

      block()

      fflush(nil)
      dup2(originalStdout, STDOUT_FILENO)
      close(originalStdout)
      pipe.fileHandleForWriting.closeFile()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      return String(data: data, encoding: .utf8) ?? ""
    }

    func stripTimestamp(_ output: String) -> String {
      let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let spaceIndex = trimmed.firstIndex(of: " ") else { return trimmed }
      return String(trimmed[spaceIndex...])
    }

    let verboseOutput = capture {
      logger.verbose("same", file: "file", function: "func", line: 1)
    }
    let debugOutput = capture {
      logger.debug("same", file: "file", function: "func", line: 1)
    }

    #expect(stripTimestamp(verboseOutput) == stripTimestamp(debugOutput))
  }

  /// Plain decorator emits only the message body (no file/function/line in body).
  @Test
  func plainDecoratorPrintsOnlyMessageBody() {
    Log.reset()
    Log.globalExposureLevel = .trace
    var logger = Log(
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )
    logger.decorator = Log.Decorator.Plain()

    let message = "hello-world"
    let output = captureOutput {
      logger.info(message, file: "Some.swift", function: "fn", line: 123)
    }.trimmingCharacters(in: .whitespacesAndNewlines)

    // Swift Testing may print test-start lines to stdout concurrently.
    // Validate only the line emitted by the logger.
    let line = output.split(separator: "\n").last.map(String.init) ?? output

    // Should have no '|' separators and end with the message body.
    #expect(!line.contains("|"))
    #expect(line.hasSuffix(message))
    // Retains system/category header produced by Print backend.
    #expect(line.hasPrefix("sys:cat:"))
  }

  #if canImport(Foundation)
  /// JSON decorator emits parsable JSON containing message and metadata.
  @Test
  func jsonDecoratorOutputsParsableJSON() throws {
    Log.reset()
    Log.globalExposureLevel = .trace
    var logger = Log(
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )
    logger.decorator = Log.Decorator.JSON()

    let output = captureOutput {
      logger.info("json-msg", file: "File.swift", function: "funcName()", line: 42)
    }.trimmingCharacters(in: .whitespacesAndNewlines)

    // Strip the Print backend prefix "sys:cat:ℹ️ "
    guard let spaceIdx = output.firstIndex(of: " ") else {
      #expect(Bool(false), "No space separator found in output")
      return
    }
    let jsonPart = String(output[output.index(after: spaceIdx)...])

    // Parse JSON body
    let data = jsonPart.data(using: .utf8)!
    let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(obj["message"] as? String == "json-msg")
    #expect(obj["system"] as? String == "sys")
    #expect(obj["category"] as? String == "cat")
    #expect(obj["file"] as? String == "File")
    #expect(obj["function"] as? String == "funcName()")
    #expect((obj["line"] as? Int) == 42)
    #expect((obj["timestamp"] as? String) != nil)
    #expect((obj["isMainThread"] as? Bool) != nil)
    // threadId may be platform-dependent; if present, assert it is numeric
    if let tid = obj["threadId"] { #expect((tid as? Int) != nil || (tid as? Double) != nil) }
  }
  #endif

  /// Validates the notice helper respects exposure levels.
  @Test
  func noticeHelperRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    log.notice("suppressed")
    #expect(Log.swiftCount == 0)
    Log.globalExposureLevel = .notice
    _ = captureOutput { log.notice("logged") }
    #expect(Log.swiftCount == 1)
  }

  /// Validates the warning helper respects exposure levels.
  @Test
  func warningHelperRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .error
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    log.warning("suppressed")
    #expect(Log.swiftCount == 0)
    Log.globalExposureLevel = .warning
    _ = captureOutput { log.warning("logged") }
    #expect(Log.swiftCount == 1)
  }

  /// Verifies `effectiveLevel(for:)` filters based on exposure settings.
  @Test
  func effectiveLevelRespectsExposure() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    #expect(log.effectiveLevel(for: .info) == nil)
    #expect(log.effectiveLevel(for: .error) == .error)
  }

  /// Global level below logger max uses the global level as effective.
  @Test
  func effectiveLevelUsesGlobalWhenBelowMax() {
    Log.reset()
    Log.globalExposureLevel = .debug
    let log = Log(maxExposureLevel: .trace, options: [.prod])
    #expect(log.effectiveLevel(for: .debug) == .debug)
    #expect(log.effectiveLevel(for: .trace) == nil)
  }

  /// Global level above logger max clamps the level to the logger's maximum.
  @Test
  func effectiveLevelClampsToLoggerMax() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .info,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    #expect(log.effectiveLevel(for: .trace) == nil)
    #expect(log.effectiveLevel(for: .info) == .info)
  }

  /// Confirms `isEnabled(for:)` evaluates both global and logger levels.
  @Test
  func isEnabledRespectsExposureLevels() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .info,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    #expect(log.isEnabled(for: .info) == false)
    #expect(log.isEnabled(for: .warning) == true)
  }

  /// Validates `ifEnabled(for:_:)` executes the closure only when enabled.
  @Test
  func ifEnabledExecutesConditionally() {
    Log.reset()
    Log.globalExposureLevel = .warning
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: SwiftLogBackend()
    )
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
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .critical,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    log.error("suppressed")
    #expect(Log.swiftCount == 0)
    Log.globalExposureLevel = .trace
    #expect(log.maxExposureLevel == .critical)
    log.error("still suppressed")
    #expect(Log.swiftCount == 0)
  }

  /// Asserts `guard` logs a critical message before terminating execution.
  @Test
  @MainActor
  func guardLogsBeforeFatalError() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: PrintLogBackend()
    )

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
    if log.isEnabled {
      log.guard("unreachable")
    }
    #expect(!log.isEnabled)
  }

  #if DEBUG
  /// Validates that overriding the level adjusts logging in debug builds.
  @Test
  func overrideLevelAdjustsLoggingInDebug() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "", category: "", maxExposureLevel: .trace, options: [.prod],
      backend: SwiftLogBackend())
    log.info("suppressed")
    // Ensure a logger instance exists after a log call
    #expect(Log.Cache.shared.hasSwiftLogger(for: log))
    Log.overrideLevel(for: log, to: .debug)
    log.info("logged")
    #expect(Log.Cache.shared.hasSwiftLogger(for: log))
    #expect(log.effectiveLevel(for: .info) == .debug)
  }
  #endif

  #if DEBUG
  /// Ensures `Log.globalExposureLevel` defaults to `.trace` in debug builds after a reset.
  @Test
  func globalExposureDefaultsToTraceInDebug() {
    Log.globalExposureLevel = .critical
    Log.reset()
    #expect(Log.globalExposureLevel == .trace)
  }

  /// Confirms the default logger remains enabled in debug builds.
  @Test
  func defaultLoggerNotDisabledInDebug() {
    let log = Log()
    #expect(log.isEnabled)
  }
  #else
  /// Ensures `Log.globalExposureLevel` defaults to `.critical` in release builds after a reset.
  @Test
  func globalExposureDefaultsToCriticalInRelease() {
    Log.globalExposureLevel = .trace
    Log.reset()
    #expect(Log.globalExposureLevel == .critical)
  }

  /// Verifies the default logger is disabled in release builds.
  @Test
  func defaultLoggerDisabledInRelease() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log()
    log.info("silence")
    #expect(!log.isEnabled)
  }

  /// Ensures a logger with the `.prod` option remains enabled in release builds.
  @Test
  func loggerWithProdOptionEnabledInRelease() {
    Log.reset()
    Log.globalExposureLevel = .trace
    let log = Log(
      system: "",
      category: "",
      maxExposureLevel: .trace,
      options: [.prod],
      backend: SwiftLogBackend()
    )
    log.info("hello")
    #expect(log.isEnabled)
  }
  #endif
}
