import Foundation
import Testing

@testable import WrkstrmLog

@Suite("Backends Array & Wrappers", .serialized)
struct BackendsArrayTests {

  // Capture stdout while executing a block and return captured string.
  private func captureOutput(_ block: () -> Void) -> String {
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

  /// Defaults resolve via Inject.setBackends and report primary = index 0.
  @Test
  func arrayBackendsResolution() {
    Log.reset()
    // Validate that a logger constructed with explicit backends uses index 0 as primary
    // and emits print-formatted output (avoid relying on global injection across suites).
    let log = Log(
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backends: [PrintLogBackend(), SwiftLogBackend()]
    )
    let out = captureOutput {
      log.info("hello", file: "File.swift", function: "fn", line: 1)
    }
    #expect(out.contains("sys:cat:"))
  }

  /// When multiple backends are provided, index 0 is treated as primary.
  @Test
  func primaryIsIndexZero() {
    Log.reset()
    Log.globalExposureLevel = .trace

    // Primary = Print
    let printPrimary = Log(
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backends: [PrintLogBackend(), SwiftLogBackend()]
    )
    let out1 = captureOutput {
      printPrimary.info("hello", file: "X.swift", function: "f", line: 1)
    }
    #expect(out1.contains("sys:cat:"))

    // Primary = SwiftLog — formatting differs and typically lacks sys:cat prefix
    let swiftPrimary = Log(
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backends: [SwiftLogBackend(), PrintLogBackend()]
    )
    let out2 = captureOutput {
      swiftPrimary.info("hello", file: "Y.swift", function: "g", line: 2)
    }
    #expect(!out2.contains("sys:cat:"))
  }

  /// Suppression gates prevent backend work when below effective level.
  @Test
  func suppressionGates() {
    Log.reset()
    Log.globalExposureLevel = .error  // suppress info

    let log = Log(
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backends: [PrintLogBackend()]
    )

    let out = captureOutput {
      log.info("suppressed", file: "Z.swift", function: "h", line: 3)
    }
    #expect(out.isEmpty)
  }

  /// Appending a backend adds to the end and preserves the primary at index 0.
  @Test
  func appendBackendPreservesPrimary() {
    Log.reset()
    Log.Inject.setBackends([.swift])
    Log.Inject.appendBackend(.print)
    let kinds = Log.Inject.currentBackends()
    #expect(kinds == [.swift, .print])
  }

  /// Removing a backend updates the array and primary accordingly.
  @Test
  func removeBackendUpdatesOrdering() {
    Log.reset()
    Log.Inject.setBackends([.print, .swift])
    // Remove non-primary: primary stays .print
    Log.Inject.removeBackend(.swift)
    var kinds = Log.Inject.currentBackends()
    #expect(kinds == [.print])

    // Reset and remove primary: primary becomes next element
    Log.Inject.setBackends([.print, .swift])
    Log.Inject.removeBackend(.print)
    kinds = Log.Inject.currentBackends()
    #expect(kinds.first == .swift)
  }

  /// Decorated backend overrides the logger's default decorator.
  @Test
  func decoratedBackendOverridesLoggerDecorator() {
    Log.reset()
    Log.globalExposureLevel = .trace

    var log = Log(
      system: "sys",
      category: "cat",
      maxExposureLevel: .trace,
      options: [.prod],
      backends: [PrintLogBackend().decorated(with: Log.Decorator.Plain())]
    )
    // Set a different default decorator on the logger; backend wrapper should win.
    log.decorator = Log.Decorator.Current()
    let out = captureOutput {
      log.info("hello-decor")
    }
    #expect(out.contains("sys:cat:"))
    #expect(!out.contains("|"))
    #expect(out.contains("hello-decor"))
  }

  /// Removing all custom backends resets to platform default selection.
  @Test
  func removeAllResetsToDefault() {
    Log.reset()
    Log.Inject.setBackends([.print, .swift])
    Log.Inject.removeAllCustomBackends()
    let kinds = Log.Inject.currentBackends()
    #if os(WASI) || arch(wasm32)
    #expect(kinds == [.print])
    #elseif canImport(os)
    #expect(kinds == [.os])
    #else
    #expect(kinds == [.swift])
    #endif
  }

  /// Convenience setter selects a single kind as the primary.
  @Test
  func setBackendConvenience() {
    Log.reset()
    Log.Inject.setBackend(.print)
    let kinds = Log.Inject.currentBackends()
    #expect(kinds.first == .print)
    Log.Inject.removeAllCustomBackends()
  }

  /// Appending an existing kind is a no-op (no duplicates).
  @Test
  func appendDoesNotDuplicate() {
    Log.reset()
    Log.Inject.setBackends([.swift])
    Log.Inject.appendBackend(.swift)
    let kinds = Log.Inject.currentBackends()
    #expect(kinds == [.swift])
  }

  /// Removing a non-existent kind is a no-op.
  @Test
  func removeNonexistentKindNoOp() {
    Log.reset()
    Log.Inject.setBackends([.swift])
    Log.Inject.removeBackend(.print)
    let kinds = Log.Inject.currentBackends()
    #expect(kinds == [.swift])
  }

}
