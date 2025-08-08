import Logging
import Testing

@testable import WrkstrmLog

#if canImport(os)
  import os
#endif

@Suite("Logging.Level extensions", .serialized)
struct LevelExtensionsTests {
  /// Ensures each logging level maps to the expected emoji.
  @Test
  func emojiMapping() {
    #expect(Logging.Logger.Level.trace.emoji == "🔍")
    #expect(Logging.Logger.Level.debug.emoji == "🐞")
    #expect(Logging.Logger.Level.info.emoji == "ℹ️")
    #expect(Logging.Logger.Level.notice.emoji == "📝")
    #expect(Logging.Logger.Level.warning.emoji == "⚠️")
    #expect(Logging.Logger.Level.error.emoji == "❗")
    #expect(Logging.Logger.Level.critical.emoji == "🚨")
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
