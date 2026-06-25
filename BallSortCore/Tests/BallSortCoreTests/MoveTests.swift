import Testing
@testable import BallSortCore

@Suite("Move")
struct MoveTests {
    @Test("stores from and to indices")
    func storesIndices() {
        let move = Move(from: 1, to: 3)
        #expect(move.from == 1)
        #expect(move.to == 3)
    }

    @Test("equality and hashing by indices")
    func equality() {
        #expect(Move(from: 0, to: 2) == Move(from: 0, to: 2))
        #expect(Move(from: 0, to: 2) != Move(from: 2, to: 0))
        #expect(Set([Move(from: 0, to: 1), Move(from: 0, to: 1)]).count == 1)
    }
}
