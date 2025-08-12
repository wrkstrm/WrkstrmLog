import Logging
import Testing

@testable import WrkstrmLog

#if canImport(os)
  import os
#endif

// MARK: - Level Extensions

@Suite("Logging.Level extensions", .serialized)
struct LevelExtensionsTests {
  /// Ensures each logging level maps to the expected emoji.
  @Test
  func emojiMapping() {
    let mappings: [(Logging.Logger.Level, String)] = [
      (.trace, "🔍"),
      (.debug, "🐞"),
      (.info, "ℹ️"),
      (.notice, "📝"),
      (.warning, "⚠️"),
      (.error, "❗"),
      (.critical, "🚨"),
    ]
    for (level, emoji) in mappings {
      #expect(level.emoji == emoji)
    }
  }

  #if canImport(os)
    /// Verifies that logging levels convert to the correct `OSLogType` values.
    @Test
    func osLogTypeMapping() {
      #expect(Logging.Logger.Level.trace.toOSType == .debug)
      #expect(Logging.Logger.Level.debug.toOSType == .debug)
      #expect(Logging.Logger.Level.info.toOSType == .info)
      #expect(Logging.Logger.Level.notice.toOSType == .default)
      #expect(Logging.Logger.Level.warning.toOSType == .error)
      #expect(Logging.Logger.Level.error.toOSType == .error)
      #expect(Logging.Logger.Level.critical.toOSType == .fault)
    }
  #endif
}
