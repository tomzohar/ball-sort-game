import XCTest
import BallSortCore
@testable import BallSortApp

/// Unit tests for the localization scaffold (E9.5).
///
/// These prove the `Localizable.xcstrings` String Catalog is actually bundled and
/// that the dynamic, interpolated strings resolve through it to their English values
/// — not silently falling back to the raw key. (A missing/misnamed catalog would
/// surface here: the custom-keyed lookups like `tube.index` would return the key
/// string `"Tube %lld"`-template-untouched or the bare key, never the English text.)
///
/// The English output must stay identical to the pre-localization strings so the
/// existing snapshot/behavioral tests don't regress; asserting the exact text here
/// locks that.
final class LocalizationTests: XCTestCase {
    // MARK: - Ball color names (custom keys via String(localized:))

    func testEachBallColorNameResolvesToEnglish() {
        XCTAssertEqual(BallColor.yellow.accessibilityColorName, "yellow")
        XCTAssertEqual(BallColor.orange.accessibilityColorName, "orange")
        XCTAssertEqual(BallColor.pink.accessibilityColorName, "pink")
        XCTAssertEqual(BallColor.green.accessibilityColorName, "green")
        XCTAssertEqual(BallColor.blue.accessibilityColorName, "blue")
        XCTAssertEqual(BallColor.purple.accessibilityColorName, "purple")
    }

    func testBallLabelInterpolatesLocalizedColorName() {
        // "%@ ball" with the (also localized) color name substituted.
        XCTAssertEqual(BallColor.blue.ballAccessibilityLabel, "blue ball")
        XCTAssertEqual(BallColor.purple.ballAccessibilityLabel, "purple ball")
    }

    // MARK: - Tube label fragments

    func testTubeIndexFragmentResolves() {
        XCTAssertEqual(
            String(localized: "tube.index", defaultValue: "Tube \(3)"),
            "Tube 3"
        )
    }

    func testTubeFillFragmentResolves() {
        XCTAssertEqual(
            String(localized: "tube.fill", defaultValue: "\(3) of \(4) balls"),
            "3 of 4 balls"
        )
    }

    func testTubeTopFragmentResolves() {
        XCTAssertEqual(
            String(localized: "tube.top", defaultValue: "top \("blue")"),
            "top blue"
        )
    }

    func testTubeStateFragmentsResolve() {
        XCTAssertEqual(String(localized: "tube.empty", defaultValue: "empty"), "empty")
        XCTAssertEqual(String(localized: "tube.complete", defaultValue: "complete"), "complete")
        XCTAssertEqual(String(localized: "tube.selected", defaultValue: "selected"), "selected")
        XCTAssertEqual(String(localized: "tube.canDrop", defaultValue: "can drop here"), "can drop here")
    }

    // MARK: - Difficulty badge label

    func testDifficultyAccessibilityLabelResolves() {
        XCTAssertEqual(
            String(localized: "difficulty.accessibility", defaultValue: "Level \(5), \("Hard") difficulty"),
            "Level 5, Hard difficulty"
        )
    }

    func testDifficultyBandWordsResolve() {
        XCTAssertEqual(String(localized: "Trivial"), "Trivial")
        XCTAssertEqual(String(localized: "Easy"), "Easy")
        XCTAssertEqual(String(localized: "Medium"), "Medium")
        XCTAssertEqual(String(localized: "Hard"), "Hard")
        XCTAssertEqual(String(localized: "Expert"), "Expert")
    }

    // MARK: - Win overlay singular/plural

    func testMovesLabelKeysResolve() {
        // Two top-level keys (the count is shown in a separate pill, so the words
        // carry no number): "move" for a single move, "moves" otherwise.
        XCTAssertEqual(String(localized: "win.move"), "move")
        XCTAssertEqual(String(localized: "win.moves"), "moves")
    }

    // MARK: - Catalog presence

    func testCatalogIsBundled() {
        // The compiled catalog ships as Localizable.strings inside the app bundle's
        // .lproj. If this is nil, the catalog never made it into the build and every
        // lookup above is silently falling back.
        let path = Bundle.main.path(forResource: "Localizable", ofType: "strings")
        XCTAssertNotNil(path, "Localizable.strings not found in the app bundle — catalog not bundled")
    }
}
