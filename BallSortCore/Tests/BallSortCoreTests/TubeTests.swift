import Testing
@testable import BallSortCore

@Suite("Tube")
struct TubeTests {
    @Test("empty tube: no top, isEmpty, not full, count 0, not complete")
    func emptyTube() {
        let tube = Tube(balls: [], capacity: 4)
        #expect(tube.top == nil)
        #expect(tube.isEmpty)
        #expect(!tube.isFull)
        #expect(tube.balls.isEmpty)
        #expect(!tube.isComplete)
    }

    @Test("partial tube: top is last ball, not empty, not full, not complete")
    func partialTube() {
        let tube = Tube(balls: [.yellow, .blue], capacity: 4)
        #expect(tube.top == .blue)
        #expect(!tube.isEmpty)
        #expect(!tube.isFull)
        #expect(tube.count == 2)
        #expect(!tube.isComplete)
    }

    @Test("full mixed tube: full but not complete")
    func fullMixedTube() {
        let tube = Tube(balls: [.yellow, .blue, .yellow, .blue], capacity: 4)
        #expect(tube.top == .blue)
        #expect(tube.isFull)
        #expect(tube.count == 4)
        #expect(!tube.isComplete)
    }

    @Test("full single-color tube: complete")
    func fullSingleColorTube() {
        let tube = Tube(balls: [.green, .green, .green, .green], capacity: 4)
        #expect(tube.top == .green)
        #expect(tube.isFull)
        #expect(tube.isComplete)
    }

    @Test("single-color but not full is not complete")
    func singleColorNotFull() {
        let tube = Tube(balls: [.pink, .pink], capacity: 4)
        #expect(!tube.isFull)
        #expect(!tube.isComplete)
    }
}
