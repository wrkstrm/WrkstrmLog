import Dispatch
import Testing

@testable import WrkstrmLog

// MARK: - Cache Concurrency

extension WrkstrmLogTests {
  /// Ensures the cache produces consistent results when accessed from many concurrent tasks.
  @Test
  func cacheConcurrency() {
    Log.reset()
    Log.globalExposureLevel = .trace
    #expect(Log.swiftCount == 0)
    #expect(Log.pathInfoCount == 0)

    let logger = Log(style: .swift, maxExposureLevel: .trace, options: [.prod])
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "cache-concurrency", attributes: .concurrent)

    for _ in 0..<100 {
      group.enter()
      queue.async {
        logger.info("entry")
        group.leave()
      }
    }
    group.wait()
    let waitResult = group.wait(timeout: .now() + 5)
    #expect(waitResult == .success, "DispatchGroup wait timed out")
    #expect(Log.swiftCount == 1)
    #expect(Log.pathInfoCount == 1)
  }
}
