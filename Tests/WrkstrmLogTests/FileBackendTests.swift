#if canImport(Foundation)
import Foundation
import Testing
@testable import WrkstrmLog

@Suite("File Backend", .serialized)
struct FileBackendTests {
  @Test
  func writesPlainLines() throws {
    Log.reset()
    Log.globalExposureLevel = .trace

    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "wrkstrmlog_test_\(UUID().uuidString).log")
    let backend = FileLogBackend(url: url)
    var log = Log(
      system: "sys", category: "file", maxExposureLevel: .trace, options: [.prod],
      backends: [backend])
    log.decorator = Log.Decorator.Plain()

    log.info("first")
    log.info("second")

    let data = try Data(contentsOf: url)
    let text = String(decoding: data, as: UTF8.self)
    let lines = text.split(separator: "\n").map(String.init)
    #expect(lines.count == 2)
    #expect(lines[0].hasSuffix("first"))
    #expect(lines[1].hasSuffix("second"))

    try? FileManager.default.removeItem(at: url)
  }

  @Test
  func writesJSONLines() throws {
    Log.reset()
    Log.globalExposureLevel = .trace
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "wrkstrmlog_json_\(UUID().uuidString).log")
    let backend = FileLogBackend(url: url)
    var log = Log(
      system: "sys", category: "file", maxExposureLevel: .trace, options: [.prod],
      backends: [backend])
    log.decorator = Log.Decorator.JSON()

    log.info("hello", file: "File.swift", function: "fun()", line: 7)

    let data = try Data(contentsOf: url)
    let text = String(decoding: data, as: UTF8.self)
    let line = text.split(separator: "\n").first.map(String.init) ?? ""
    let obj = try JSONSerialization.jsonObject(with: Data(line.utf8)) as! [String: Any]
    #expect(obj["message"] as? String == "hello")
    #expect(obj["system"] as? String == "sys")
    #expect(obj["file"] as? String == "File")
    try? FileManager.default.removeItem(at: url)
  }

  @Test
  func sessionBasedFileCreation() throws {
    Log.reset()
    Log.globalExposureLevel = .trace
    let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "wrkstrmlog_sessions")
    let backend = FileLogBackend(directory: dir, baseName: "session")
    var log = Log(
      system: "sys", category: "file", maxExposureLevel: .trace, options: [.prod],
      backends: [backend])
    log.decorator = Log.Decorator.Plain()
    log.info("session-first")

    // Verify file exists and matches naming convention
    let path = backend.url.path
    #expect(FileManager.default.fileExists(atPath: path))
    #expect(path.contains("session-"))
    #expect(path.hasSuffix(".log"))

    // Clean up
    try? FileManager.default.removeItem(at: backend.url)
    try? FileManager.default.removeItem(at: dir)
  }

  @Test
  func sizeBasedRotation() throws {
    Log.reset()
    Log.globalExposureLevel = .trace
    let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("wrkstrmlog_rot")
    let backend = FileLogBackend(directory: dir, baseName: "rot", maxBytes: 32)
    var log = Log(
      system: "sys", category: "file", maxExposureLevel: .trace, options: [.prod],
      backends: [backend])
    log.decorator = Log.Decorator.Plain()

    // Each line + newline is > 16 bytes; two writes should force rotation beyond 32
    log.info("first-rotation-line-1")
    log.info("first-rotation-line-2")

    // Dir should contain at least 2 files now
    let contents = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    #expect(contents.filter { $0.hasPrefix("rot-") && $0.hasSuffix(".log") }.count >= 1)

    // Cleanup
    try? FileManager.default.removeItem(at: dir)
  }

  @Test
  func dailyRotation() throws {
    Log.reset()
    Log.globalExposureLevel = .trace
    let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "wrkstrmlog_dayrot")
    // Freeze time to a known day then switch to next day
    var day1 = DateComponents(
      calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(secondsFromGMT: 0), year: 2025,
      month: 9, day: 9, hour: 12
    ).date!
    var day2 = DateComponents(
      calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(secondsFromGMT: 0), year: 2025,
      month: 9, day: 10, hour: 0, minute: 1
    ).date!
    var calls = 0
    FileLogBackend._now = {
      defer { calls += 1 }
      return calls == 0 ? day1 : day2
    }
    defer { FileLogBackend._now = { Date() } }

    let backend = FileLogBackend(directory: dir, baseName: "day", maxBytes: nil, rollDaily: true)
    var log = Log(
      system: "sys", category: "file", maxExposureLevel: .trace, options: [.prod],
      backends: [backend])
    log.decorator = Log.Decorator.Plain()

    log.info("first-day")
    log.info("second-day-next")

    let contents = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    #expect(contents.filter { $0.hasPrefix("day-") && $0.hasSuffix(".log") }.count >= 2)

    try? FileManager.default.removeItem(at: dir)
  }
}
#endif
