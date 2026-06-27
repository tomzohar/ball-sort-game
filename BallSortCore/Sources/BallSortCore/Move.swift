/// A single ball move: lift the top ball of tube `from` and drop it onto tube `to`.
///
/// Both fields are indices into a `GameState`'s `tubes` array. A `Move` is just
/// an intent — `GameState` decides whether it is legal and what it produces.
public struct Move: Equatable, Hashable, Sendable, Codable {
    /// Index of the source tube (the top ball is lifted from here).
    public var from: Int
    /// Index of the destination tube (the ball is dropped here).
    public var to: Int

    public init(from: Int, to: Int) {
        self.from = from
        self.to = to
    }
}
