import Flutter
import XCTest


@testable import qs_ad_mob

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testMethodCallReturnsNotImplemented() {
    let plugin = QsAdMobPlugin()

    let call = FlutterMethodCall(methodName: "unknownMethod", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! NSObject, FlutterMethodNotImplemented)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
