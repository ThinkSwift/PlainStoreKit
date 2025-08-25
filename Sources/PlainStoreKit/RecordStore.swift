import SwiftData
import Foundation

@MainActor
public final class RecordStore {
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

    /// Replace the entire record with given text (no merge, no delete token).
    @discardableResult
    public func ingest(folder: String,
                       filename: String,
                       text: String,
                       bundle: Bundle = .main) throws -> Record {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        let localized = Localize.apply(text, bundle: bundle)
        let kv = KeyValueLines.parse(localized)
        let json = Formats.infer(map: kv)

        let rec = try fetch(path: path) ?? Record(
            folder: folder, filename: filename, format: "auto", raw: localized, date: .now, order: 0
        )
        rec.raw = localized
        rec.format = "auto"
        if let ord = kv["order"].flatMap(Int.init) { rec.order = ord }
        rec.updatedAt = .now
        rec.json = json

        context.insert(rec)
        try context.save()
        return rec
    }

    public func render(path: String) throws -> String? {
        guard let r = try fetch(path: path), let d = r.json else { return nil }
        return d.prettyPrintedString
    }

    public func fetch(folder: String? = nil) throws -> [Record] {
        var p: Predicate<Record> = #Predicate { _ in true }
        if let f = folder { p = #Predicate { $0.folder == f } }
        let s: [SortDescriptor<Record>] = [
            SortDescriptor(\.date, order: .reverse),
            SortDescriptor(\.order),
            SortDescriptor(\.filename)
        ]
        return try context.fetch(FetchDescriptor(predicate: p, sortBy: s))
    }

    public func fetch(path: String) throws -> Record? {
        var d = FetchDescriptor<Record>(predicate: #Predicate { $0.path == path })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }
}
