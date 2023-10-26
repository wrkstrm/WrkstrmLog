import XCTest

@testable import WrkstrmLog

final class WrkstrmLogTests: XCTestCase {
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    Log.error("This is interesting.")
    Log.verbose("This is a log.")
    XCTAssert(true)
  }

  static var allTests = [("testExample", testExample)]
}
