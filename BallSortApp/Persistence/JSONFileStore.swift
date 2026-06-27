import Foundation

/// Concrete `PersistenceStore` that writes one JSON file per key under a base
/// directory (default `<Application Support>/BallSort/`).
///
/// This is the on-disk persistence backing called for by ADR-0002 — Codable
/// values are encoded with `JSONEncoder` and written atomically; reads decode
/// with `JSONDecoder`. The base directory is injectable so tests can point it
/// at a throwaway temp dir instead of the real Application Support location.
struct JSONFileStore: PersistenceStore {

    /// Raised when a caller passes an empty/whitespace-only key, which would
    /// not map to a valid file name.
    enum StoreError: Error, Equatable {
        case invalidKey(String)
    }

    private let baseDirectory: URL
    private let fileManager: FileManager

    /// - Parameters:
    ///   - baseDirectory: where the `<key>.json` files live. Defaults to
    ///     `<Application Support>/BallSort`, created on first write.
    ///   - fileManager: injectable for testing; defaults to `.default`.
    init(baseDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = Self.defaultBaseDirectory(fileManager: fileManager)
        }
    }

    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let url = try fileURL(forKey: key)
        try ensureBaseDirectoryExists()
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        let url = try fileURL(forKey: key)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func remove(forKey key: String) throws {
        let url = try fileURL(forKey: key)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    // MARK: - Helpers

    /// `<Application Support>/BallSort`. Application Support is guaranteed to
    /// resolve on iOS for the user domain; on the unexpected chance it doesn't
    /// we fall back to the temporary directory so construction never traps.
    private static func defaultBaseDirectory(fileManager: FileManager) -> URL {
        let root = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        return root.appendingPathComponent("BallSort", isDirectory: true)
    }

    private func ensureBaseDirectoryExists() throws {
        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Maps a key to `<baseDirectory>/<key>.json`, rejecting empty keys.
    private func fileURL(forKey key: String) throws -> URL {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw StoreError.invalidKey(key) }
        return baseDirectory
            .appendingPathComponent(trimmed, isDirectory: false)
            .appendingPathExtension("json")
    }
}
