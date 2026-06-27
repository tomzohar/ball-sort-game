import XCTest
import BallSortCore
@testable import BallSortApp

/// Unit tests for the App-layer accessibility mappings (E9.4).
///
/// Balls are distinguished by hue alone, which is invisible to VoiceOver and
/// unfriendly to color-blind players. These pure mappings back the spoken color
/// name and the color-blind-safe SF Symbol badge, so every `BallColor` must map
/// to a distinct, non-empty value.
final class BallColorAccessibilityTests: XCTestCase {
    func testEveryColorHasNonEmptyName() {
        for color in BallColor.allCases {
            XCTAssertFalse(color.accessibilityColorName.isEmpty, "\(color) has an empty color name")
        }
    }

    func testColorNamesAreAllDistinct() {
        let names = BallColor.allCases.map(\.accessibilityColorName)
        XCTAssertEqual(Set(names).count, BallColor.allCases.count, "color names must be unique")
    }

    func testEveryColorHasNonEmptySymbol() {
        for color in BallColor.allCases {
            XCTAssertFalse(color.accessibilitySymbolName.isEmpty, "\(color) has an empty symbol name")
        }
    }

    func testSymbolsAreAllDistinct() {
        let symbols = BallColor.allCases.map(\.accessibilitySymbolName)
        XCTAssertEqual(Set(symbols).count, BallColor.allCases.count, "symbols must be unique")
    }

    func testColorNameMatchesCaseName() {
        // The spoken name should match the enum case so it stays obviously correct.
        XCTAssertEqual(BallColor.yellow.accessibilityColorName, "yellow")
        XCTAssertEqual(BallColor.orange.accessibilityColorName, "orange")
        XCTAssertEqual(BallColor.pink.accessibilityColorName, "pink")
        XCTAssertEqual(BallColor.green.accessibilityColorName, "green")
        XCTAssertEqual(BallColor.blue.accessibilityColorName, "blue")
        XCTAssertEqual(BallColor.purple.accessibilityColorName, "purple")
    }

    func testBallAccessibilityLabelNamesColor() {
        XCTAssertEqual(BallColor.yellow.ballAccessibilityLabel, "yellow ball")
        XCTAssertEqual(BallColor.blue.ballAccessibilityLabel, "blue ball")
    }
}
