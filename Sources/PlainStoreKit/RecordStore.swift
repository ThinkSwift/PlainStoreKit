import SwiftData
import Foundation

public enum IngestMode { case replace, merge }

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

    @discardableResult
    public func ingest(folder: String,
                       filename: String,
                       text: String,
                       mode: IngestMode = .replace,
                       bundle: Bundle = .main) throws -> Record {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        let localized = Localize.apply(text, bundle: bundle)

        var rawToStore = localized
        if mode == .merge, let existing = try fetch(path: path) {
            let base = KeyValueLines.parse(existing.raw)
            let diff = KeyValueLines.parse(localized)
            var merged = base
            for (k, v) in diff {
                if v == "(del)" { merged.removeValue(forKey: k) }
                else { merged[k] = v }
            }
            rawToStore = KeyValueLines.join(merged)
        }

        let kv = KeyValueLines.parse(rawToStore)
        let json = Formats.infer(map: kv)
        let ord = kv["order"].flatMap { Int($0) }

        return try upsert(folder: folder,
                          filename: filename,
                          raw: rawToStore,
                          json: json,
                          orderOverride: ord)
    }

    public func render(path: String) throws -> String? {
        guard let r = try fetch(path: path), let d = r.json else { return nil }
        return d.prettyPrintedString
    }

    // MARK: - Internals

    @discardableResult
    private func upsert(folder: String,
                        filename: String,
                        raw: String,
                        json: Data,
                        orderOverride: Int?) throws -> Record {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        let rec = try fetch(path: path) ?? Record(folder: folder, filename: filename, format: "auto", raw: raw, date: .now, order: 0)
        rec.raw = raw
        rec.format = "auto"
        rec.date = rec.date            // keep logical date unless you want to change policy
        if let o = orderOverride { rec.order = o }
        rec.updatedAt = .now
        rec.json = json
        context.insert(rec)
        try context.save()
        return rec
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

private extension Data {
    var prettyPrintedString: String {
        (try? JSONSerialization.jsonObject(with: self))
            .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: [.prettyPrinted, .sortedKeys]) }
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}
