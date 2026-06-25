/// A ball color. The colors in play for a given level are a prefix of these cases,
/// sized to the level's difficulty (number of distinct colors == number of full tubes).
///
/// First real domain primitive — exists to prove the TDD harness (E1.2) and seed E2.1.
public enum BallColor: Int, CaseIterable, Sendable, Hashable {
    case yellow
    case orange
    case pink
    case green
    case blue
    case purple
}
