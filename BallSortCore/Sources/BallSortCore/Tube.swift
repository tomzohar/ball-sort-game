/// A single tube holding a vertical stack of colored balls.
///
/// Balls are stored bottom→top: `balls[0]` is the bottom of the tube and
/// `balls.last` is the top — the only ball that can be lifted out.
public struct Tube: Equatable, Hashable, Sendable, Codable {
    /// The balls in the tube, ordered bottom (`[0]`) to top (`.last`).
    public var balls: [BallColor]
    /// The maximum number of balls the tube can hold.
    public var capacity: Int

    public init(balls: [BallColor], capacity: Int) {
        self.balls = balls
        self.capacity = capacity
    }

    /// The top ball — the one that would be lifted next — or `nil` when empty.
    public var top: BallColor? { balls.last }

    /// `true` when the tube holds no balls.
    public var isEmpty: Bool { balls.isEmpty }

    /// `true` when the tube is filled to capacity.
    public var isFull: Bool { balls.count == capacity }

    /// The number of balls currently in the tube.
    public var count: Int { balls.count }

    /// `true` when the tube is full and every ball is the same color —
    /// i.e. a finished, single-color stack.
    public var isComplete: Bool { isFull && Set(balls).count == 1 }
}
