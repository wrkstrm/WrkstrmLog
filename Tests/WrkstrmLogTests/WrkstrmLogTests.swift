import XCTest

@testable import WrkstrmLog

final class WrkstrmLogTests: XCTestCase {
  static var allTests = [("testExample", testExample)]

  func testExample() {
    Log.error("This is interesting.")
    Log.verbose("This is a log.")
    XCTAssert(true)
  }
}
