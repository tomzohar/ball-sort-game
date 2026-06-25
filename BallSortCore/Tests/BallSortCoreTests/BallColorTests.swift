import Testing
@testable import BallSortCore

@Suite("BallColor")
struct BallColorTests {
    @Test("exposes six distinct colors")
    func sixDistinctColors() {
        #expect(BallColor.allCases.count == 6)
        #expect(Set(BallColor.allCases).count == 6)
    }
}
