import Foundation
import Testing
@testable import BallSortCore

@Suite("Codable round-trip")
struct CodableRoundTripTests {
    /// Encode `value` to JSON and decode it back, returning the reconstructed value.
    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    @Test("BallColor survives a JSON round-trip")
    func ballColorRoundTrips() throws {
        let original = BallColor.purple
        #expect(try roundTrip(original) == original)
    }

    @Test("Move survives a JSON round-trip")
    func moveRoundTrips() throws {
        let original = Move(from: 2, to: 5)
        #expect(try roundTrip(original) == original)
    }

    @Test("Tube survives a JSON round-trip")
    func tubeRoundTrips() throws {
        let original = Tube(balls: [.yellow, .blue, .green], capacity: 4)
        #expect(try roundTrip(original) == original)
    }

    @Test("GameState (partial, full, empty tubes) survives a JSON round-trip")
    func gameStateRoundTrips() throws {
        let original = GameState(
            tubes: [
                Tube(balls: [.yellow, .blue], capacity: 4),                  // partial
                Tube(balls: [.green, .green, .green, .green], capacity: 4),  // full
                Tube(balls: [], capacity: 4)                                 // empty
            ],
            capacity: 4
        )
        #expect(try roundTrip(original) == original)
    }
}
