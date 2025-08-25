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

    @discardableResult
    public func save(folder: String, filename: String, text: String, bundle: Bundle = .main) throws -> FileRecord {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        let localized = Localize.apply(text, bundle: bundle)
        let kv = KeyValueLines.parse(localized)
        let json = Formats.infer(map: kv)

        let rec = try fetch(path: path) ?? Record(folder: folder, filename: filename, format: "auto", raw: localized, date: .now, order: 0)
        rec.raw = localized
        rec.format = "auto"
        if let ord = kv["order"].flatMap(Int.init) { rec.order = ord }
        rec.updatedAt = .now
        rec.json = json

        context.insert(rec)
        try context.save()
        return FileRecord(from: rec)
    }

    @discardableResult
    public func save(path: String, text: String, bundle: Bundle = .main) throws -> FileRecord {
        let (folder, filename) = Self.split(path)
        return try save(folder: folder, filename: filename, text: text, bundle: bundle)
    }

    public func load(folder: String, filename: String) throws -> FileRecord {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        return try load(path: path)
    }

    public func load(path: String) throws -> FileRecord {
        guard let rec = try fetch(path: path) else { throw PlainStoreError.notFound(path) }
        return FileRecord(from: rec)
    }

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
