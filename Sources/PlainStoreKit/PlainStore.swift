import SwiftData
import Foundation

public enum PlainStoreError: Error { case notFound(String) }

@MainActor
public final class PlainStore {
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }

    public init(inMemory: Bool = false) {
        if inMemory {
            let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
            self.container = try! ModelContainer(for: Record.self, configurations: cfg)
        } else {
            self.container = try! ModelContainer(for: Record.self)
        }
    }

    // Save one file (replace). No localization, text as-is.
    @discardableResult
    public func save(folder: String, filename: String, text: String) throws -> FileRecord {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        let kv = KeyValueLines.parse(text)
        let json = Formats.infer(map: kv)

        let rec = try fetch(path: path) ?? Record(
            folder: folder, filename: filename, format: "auto", raw: text, date: .now, order: 0
        )
        rec.raw = text
        rec.format = "auto"
        if let ord = kv["order"].flatMap(Int.init) { rec.order = ord }
        rec.updatedAt = .now
        rec.json = json

        context.insert(rec)
        try context.save()
        return FileRecord(from: rec)
    }

    @discardableResult
    public func save(path: String, text: String) throws -> FileRecord {
        let (folder, filename) = Self.split(path)
        return try save(folder: folder, filename: filename, text: text)
    }

    public func load(folder: String, filename: String) throws -> FileRecord {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        return try load(path: path)
    }

    public func load(path: String) throws -> FileRecord {
        guard let rec = try fetch(path: path) else { throw PlainStoreError.notFound(path) }
        return FileRecord(from: rec)
    }

    // Convenience: load or create with default text if missing.
    @discardableResult
    public func loadOrSaveDefault(folder: String,
                                  filename: String,
                                  defaultText: @autoclosure () -> String) throws -> FileRecord {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        if let rec = try fetch(path: path) { return FileRecord(from: rec) }
        return try save(folder: folder, filename: filename, text: defaultText())
    }

    @discardableResult
    public func loadOrSaveDefault(path: String,
                                  defaultText: @autoclosure () -> String) throws -> FileRecord {
        let (folder, filename) = Self.split(path)
        return try loadOrSaveDefault(folder: folder, filename: filename, defaultText: defaultText())
    }

    // MARK: - Internals
    private func fetch(path: String) throws -> Record? {
        var d = FetchDescriptor<Record>(predicate: #Predicate { $0.path == path })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    private static func split(_ path: String) -> (String, String) {
        guard let i = path.lastIndex(of: "/") else { return ("", path) }
        return (String(path[..<i]), String(path[path.index(after: i)...]))
    }
}
