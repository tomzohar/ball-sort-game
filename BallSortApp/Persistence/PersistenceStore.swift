import Foundation

/// A key-based persistence seam for `Codable` value types.
///
/// Per ADR-0002 the app persists game state and stats as Codable values
/// serialized to JSON on disk (Application Support), behind this protocol so
/// the concrete store is injected and can be swapped for an in-memory fake in
/// tests and previews. The protocol stays deliberately generic over `Codable`
/// so it does not depend on any particular E7 payload type.
///
/// Conformers are expected to be safe to share across the app, hence `Sendable`.
protocol PersistenceStore: Sendable {
    /// Encode and persist `value` under `key`, overwriting any prior value.
    func save<T: Encodable>(_ value: T, forKey key: String) throws

    /// Load and decode the value stored under `key`, or `nil` if none exists.
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?

    /// Delete the value stored under `key`. A no-op if nothing is stored.
    func remove(forKey key: String) throws
}
