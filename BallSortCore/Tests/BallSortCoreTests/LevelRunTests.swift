import Foundation
import Testing
@testable import BallSortCore

@Suite("LevelRun & LevelHistory")
struct LevelRunTests {
    /// A small valid board used as a stand-in puzzle snapshot.
    private func board(_ tag: BallColor = .blue) -> GameState {
        GameState(
            tubes: [
                Tube(balls: [tag, tag], capacity: 2),
                Tube(balls: [], capacity: 2)
            ],
            capacity: 2
        )
    }

    /// A deterministic, non-failing UUID keyed by a small integer (no force unwrap).
    private func uuid(_ value: Int) -> UUID {
        UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, UInt8(value)))
    }

    private func run(_ id: Int, level: Int = 1) -> LevelRun {
        LevelRun(
            id: uuid(id),
            level: level,
            moves: 10,
            timeSeconds: 42,
            dayKey: 20260627,
            board: board()
        )
    }

    // MARK: - Recording order

    @Test("recording prepends the newest run (newest first)")
    func recordingPrependsNewest() {
        let history = LevelHistory.empty
            .recording(run(1))
            .recording(run(2))
            .recording(run(3))

        #expect(history.runs.map(\.id) == [run(3).id, run(2).id, run(1).id])
    }

    @Test("empty history has no runs")
    func emptyHasNoRuns() {
        #expect(LevelHistory.empty.runs.isEmpty)
    }

    // MARK: - Cap / eviction

    @Test("recording past maxEntries evicts the oldest runs")
    func recordingEvictsOldest() {
        var history = LevelHistory.empty
        let total = LevelHistory.maxEntries + 5
        for index in 0..<total {
            history = history.recording(run(index))
        }

        #expect(history.runs.count == LevelHistory.maxEntries)
        // Newest is the last recorded; the 5 oldest were dropped.
        #expect(history.runs.first?.id == run(total - 1).id)
        #expect(history.runs.last?.id == run(5).id)
    }

    @Test("init clamps an oversized seed array to maxEntries")
    func initClampsOversizedSeed() {
        let seed = (0..<(LevelHistory.maxEntries + 10)).map { run($0) }
        let history = LevelHistory(runs: seed)
        #expect(history.runs.count == LevelHistory.maxEntries)
        // The prefix (newest-first ordering) is retained.
        #expect(history.runs.first?.id == run(0).id)
    }

    // MARK: - Codable round-trip

    @Test("LevelHistory survives a JSON round-trip with its board snapshots")
    func codableRoundTrip() throws {
        let original = LevelHistory.empty
            .recording(run(1, level: 3))
            .recording(run(2, level: 7))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LevelHistory.self, from: data)

        #expect(decoded == original)
        #expect(decoded.runs.first?.board == board())
    }
}
