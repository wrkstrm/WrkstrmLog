import Logging
import Testing

@testable import WrkstrmLog

// MARK: - Level Masks

#if DEBUG
  @Suite("Log.LevelMask", .serialized)
  struct LevelMaskTests {
    /// Ensures threshold masks include all levels from the given minimum upward.
    @Test
    func thresholdCoversExpectedLevels() {
      let cases: [(Logging.Logger.Level, Log.LevelMask)] = [
        (.trace, [.trace, .debug, .info, .notice, .warning, .error, .critical]),
        (.debug, [.debug, .info, .notice, .warning, .error, .critical]),
        (.info, [.info, .notice, .warning, .error, .critical]),
        (.notice, [.notice, .warning, .error, .critical]),
        (.warning, [.warning, .error, .critical]),
        (.error, [.error, .critical]),
        (.critical, [.critical]),
      ]
      for (level, expected) in cases {
        let mask = Log.LevelMask.threshold(level)
        #expect(mask == expected)
        #expect(mask.minimumLevel == level)
      }
    }

    /// Verifies single-level masks only include the specified level.
    @Test
    func singleIncludesOnlySpecifiedLevel() {
      let cases: [(Logging.Logger.Level, Log.LevelMask)] = [
        (.trace, .trace),
        (.debug, .debug),
        (.info, .info),
        (.notice, .notice),
        (.warning, .warning),
        (.error, .error),
        (.critical, .critical),
      ]
      for (level, expected) in cases {
        let mask = Log.LevelMask.single(level)
        #expect(mask == expected)
        #expect(mask.minimumLevel == level)
      }
    }

    /// Confirms intersections behave like bitmask operations.
    @Test
    func maskIntersections() {
      let warningThreshold = Log.LevelMask.threshold(.warning)
      let errorSingle = Log.LevelMask.single(.error)
      let debugSingle = Log.LevelMask.single(.debug)
      let debugThreshold = Log.LevelMask.threshold(.debug)

      #expect(warningThreshold.intersection(errorSingle) == errorSingle)
      #expect(warningThreshold.intersection(debugSingle).isEmpty)
      #expect(debugThreshold.intersection(warningThreshold) == warningThreshold)
    }

    /// Ensures raw level masks map to the correct minimum level.
    @Test
    func minimumLevelMapping() {
      let mappings: [(Log.LevelMask, Logging.Logger.Level)] = [
        (.trace, .trace),
        (.debug, .debug),
        (.info, .info),
        (.notice, .notice),
        (.warning, .warning),
        (.error, .error),
        (.critical, .critical),
      ]
      for (mask, expectedLevel) in mappings {
        #expect(mask.minimumLevel == expectedLevel)
      }
    }
  }
#endif
