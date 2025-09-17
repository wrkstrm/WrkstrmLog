#if canImport(Dispatch)
import Foundation
import Dispatch
import Logging

/// Appends log entries to a file as lines. The line body is produced by the logger's decorator.
/// Combine with `Log.Decorator.JSON` for NDJSON, or `Plain` for message-only lines.
public struct FileLogBackend: LogBackend, Sendable {
  // Testable time source
  internal nonisolated(unsafe) static var _now: () -> Date = { Date() }
  private final class Sink: @unchecked Sendable {
    var url: URL
    let queue = DispatchQueue(label: "wrkstrm.log.file.sink")
    var handle: FileHandle?

    // Rotation config (active only when directory-based initializer is used)
    let rotationDirectory: URL?
    let rotationBaseName: String?
    let maxBytes: Int64?
    let rollDaily: Bool
    let timeZone: TimeZone
    var currentDayStamp: String?

    init(
      url: URL,
      rotationDirectory: URL? = nil,
      rotationBaseName: String? = nil,
      maxBytes: Int64? = nil,
      rollDaily: Bool = false,
      timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!
    ) {
      self.url = url
      self.rotationDirectory = rotationDirectory
      self.rotationBaseName = rotationBaseName
      self.maxBytes = maxBytes
      self.rollDaily = rollDaily
      self.timeZone = timeZone
    }

    func openIfNeeded() throws {
      if handle != nil { return }
      let fm = FileManager.default
      let dir = url.deletingLastPathComponent()
      try fm.createDirectory(at: dir, withIntermediateDirectories: true)
      if !fm.fileExists(atPath: url.path) {
        fm.createFile(atPath: url.path, contents: nil)
      }
      let h = try FileHandle(forWritingTo: url)
      if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.5, *) {
        try h.seekToEnd()
      } else {
        h.seekToEndOfFile()
      }
      handle = h
    }

    func append(line: String) {
      queue.sync {
        do {
          try openIfNeeded()
          guard let h = handle else { return }
          if let data = (line + "\n").data(using: .utf8) {
            // Daily roll
            if rollDaily, let dir = rotationDirectory, let base = rotationBaseName {
              let dayFormatter = DateFormatter()
              dayFormatter.locale = Locale(identifier: "en_US_POSIX")
              dayFormatter.timeZone = timeZone
              dayFormatter.dateFormat = "yyyyMMdd"
              let today = dayFormatter.string(from: FileLogBackend._now())
              if currentDayStamp == nil { currentDayStamp = today }
              if currentDayStamp != today {
                // Close current file and create a new one for the new day
                if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.5, *) {
                  try? h.close()
                } else {
                  h.closeFile()
                }
                handle = nil
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.timeZone = timeZone
                df.dateFormat = "yyyyMMdd-HHmmss"
                let stamp = df.string(from: FileLogBackend._now())
                let name = "\(base)-\(stamp)-\(UUID().uuidString).log"
                url = dir.appendingPathComponent(name)
                currentDayStamp = today
                try openIfNeeded()
              }
            }

            // Size-based rotation
            if let limit = maxBytes, limit > 0 {
              let currentSize: Int64 = {
                guard #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.5, *) else {
                  return Int64(h.seekToEndOfFile())
                }
                do { return Int64(try h.offset()) } catch { return 0 }
              }()
              if currentSize + Int64(data.count) > limit,
                let dir = rotationDirectory,
                let base = rotationBaseName
              {
                // Close current file
                if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.5, *) {
                  try? h.close()
                } else {
                  h.closeFile()
                }
                handle = nil
                // Build new timestamped file
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.timeZone = timeZone
                df.dateFormat = "yyyyMMdd-HHmmss"
                let stamp = df.string(from: FileLogBackend._now())
                let name = "\(base)-\(stamp)-\(UUID().uuidString).log"
                url = dir.appendingPathComponent(name)
                try openIfNeeded()
              }
            }
            if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.5, *) {
              try h.write(contentsOf: data)
            } else {
              h.write(data)
            }
          }
        } catch {
          // Silently ignore write failures in the backend to avoid cascading errors.
        }
      }
    }
  }

  private nonisolated(unsafe) static var sinks: [URL: Sink] = [:]
  private static let sinksLock = NSLock()
  private static func sink(for url: URL) -> Sink {
    sinksLock.lock()
    defer { sinksLock.unlock() }
    if let existing = sinks[url] { return existing }
    let created = Sink(url: url)
    sinks[url] = created
    return created
  }

  private let sink: Sink
  /// The concrete URL this backend appends to.
  public var url: URL { sink.url }

  public init(url: URL) { self.sink = Self.sink(for: url) }
  public init(path: String) { self.init(url: URL(fileURLWithPath: path)) }

  /// Creates a new session log file in the given directory with a timestamped filename.
  /// The filename pattern is: `<baseName>-yyyyMMdd-HHmmss-UUID.log`.
  /// Optionally sets a maximum size in bytes; when exceeded, rolls to a new timestamped file.
  public init(
    directory: URL, baseName: String = "log", maxBytes: Int64? = nil, rollDaily: Bool = false,
    timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!
  ) {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    df.dateFormat = "yyyyMMdd-HHmmss"
    let stamp = df.string(from: Date())
    let name = "\(baseName)-\(stamp)-\(UUID().uuidString).log"
    let url = directory.appendingPathComponent(name)
    // Do not share rotation-enabled sinks globally; keep per-backend instance
    self.sink = Sink(
      url: url, rotationDirectory: directory, rotationBaseName: baseName, maxBytes: maxBytes,
      rollDaily: rollDaily, timeZone: timeZone)
  }

  public func log(
    _ level: Logging.Logger.Level,
    message: @autoclosure () -> Any,
    logger: Log,
    file: String,
    function: String,
    line: UInt,
    context: any CommonLogContext
  ) {
    let body = logger.decorator.format(
      level,
      message: message(),
      logger: logger,
      file: file,
      function: function,
      line: line,
      context: context
    )
    sink.append(line: body)
  }
}
#endif
