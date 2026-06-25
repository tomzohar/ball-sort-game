import XCTest
import BallSortCore
@testable import BallSortApp

/// Proves the test target builds, hosts the app, and links BallSortCore.
/// Real ViewModel + snapshot tests replace this from E4 onward.
final class SmokeTests: XCTestCase {
    func testCoreIsLinked() {
        XCTAssertEqual(BallColor.allCases.count, 6)
    }

    func testColorMappingIsDistinct() {
        let colors = BallColor.allCases.map(\.swiftUIColor)
        XCTAssertEqual(Set(colors.map(String.init(describing:))).count, BallColor.allCases.count)
    }
}
