import Foundation

/// Dictionary-backed `PersistenceStore` for tests and SwiftUI previews.
///
/// Mirrors `JSONFileStore`'s round-trip semantics by storing the *encoded*
/// `Data` (encode on `save`, decode on `load`) rather than the live object, so
/// behavioral tests written against this fake exercise the same encode/decode
/// path as the real on-disk store (ADR-0002).
///
/// A `final class` so a single shared instance can be observed across the app;
/// mutation is guarded by a lock to stay safe under concurrent access, which is
/// why it can be `@unchecked Sendable`.
final class InMemoryPersistenceStore: PersistenceStore, @unchecked Sendable {

    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    init() {}

    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        lock.lock()
        defer { lock.unlock() }
        storage[key] = data
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        lock.lock()
        let data = storage[key]
        lock.unlock()
        guard let data else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func remove(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = nil
    }
}
