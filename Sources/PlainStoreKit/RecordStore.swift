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

    /// Ingest a single text blob. Header controls path/format/types/date/order.
    @discardableResult
    public func ingest(text: String, bundle: Bundle = .main, defaultFormat: String = "kv.v1") throws -> Record {
        let (meta, bodyRaw) = Header.split(text)
        let localizedBody = Localize.apply(bodyRaw, bundle: bundle)
        let format = meta["format"] ?? defaultFormat
        let path = meta["path"] ?? "inbox/\(UUID().uuidString).txt"
        let (folder, filename) = Self.split(path)
        let date = meta["date"].flatMap(Self.parseDate) ?? .now
        let order = meta["order"].flatMap { Int($0) } ?? 0

        // Choose parser: header `types` → typed KV; else registry → parser; else plain KV.
        let types = Header.parseTypes(meta["types"])
        let jsonData: Data = {
            if let types { return Formats.parseTyped(raw: localizedBody, types: types) }
            if let d = Formats.parse(format: format, raw: localizedBody) { return d }
            return Formats.parseKV(raw: localizedBody)
        }()

        return try upsert(folder: folder, filename: filename, format: format, raw: localizedBody, date: date, order: order, json: jsonData)
    }

    /// Pretty JSON for a stored record.
    public func render(path: String) throws -> String? {
        guard let r = try fetch(path: path), let d = r.json else { return nil }
        return d.prettyPrintedString
    }

    // MARK: - Internals

    @discardableResult
    public func upsert(folder: String,
                       filename: String,
                       format: String,
                       raw: String,
                       date: Date = .now,
                       order: Int = 0,
                       json: Data? = nil) throws -> Record {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        let rec = try fetch(path: path) ?? Record(folder: folder, filename: filename, format: format, raw: raw, date: date, order: order)
        rec.raw = raw
        rec.format = format
        rec.date = date
        rec.order = order
        rec.updatedAt = .now
        rec.json = json ?? Formats.parse(format: format, raw: raw) ?? Formats.parseKV(raw: raw)
        context.insert(rec)
        try context.save()
        return rec
    }

    public func fetch(folder: String? = nil) throws -> [Record] {
        var predicate: Predicate<Record> = #Predicate { _ in true }
        if let f = folder { predicate = #Predicate { $0.folder == f } }
        let sort: [SortDescriptor<Record>] = [
            SortDescriptor<Record>(\.date, order: .reverse),
            SortDescriptor<Record>(\.order),
            SortDescriptor<Record>(\.filename)
        ]
        let descriptor = FetchDescriptor<Record>(predicate: predicate, sortBy: sort)
        return try context.fetch(descriptor)
    }

    public func fetch(path: String) throws -> Record? {
        var descriptor = FetchDescriptor<Record>(predicate: #Predicate { $0.path == path })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

private enum Header {
    /// Supports lines like: `!path: folder/name.txt`, `!format: sticker.v1`, `!types: position=point2, scale=double`
    static func split(_ text: String) -> ([String:String], String) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var meta: [String:String] = [:]
        var i = 0
        while i < lines.count {
            let s = lines[i].trimmingCharacters(in: .whitespaces)
            if s == "---" { i += 1; break }
            guard s.hasPrefix("!") else { break }
            if let c = s.firstIndex(of: ":") {
                let k = String(s[s.index(after: s.startIndex)..<c]).trimmingCharacters(in: .whitespaces)
                let v = String(s[s.index(after: c)...]).trimmingCharacters(in: .whitespaces)
                meta[k] = v
            }
            i += 1
        }
        let body = lines[i...].joined(separator: "\n")
        return (meta, body)
    }

    static func parseTypes(_ s: String?) -> [String:String]? {
        guard let s = s, !s.isEmpty else { return nil }
        var out: [String:String] = [:]
        s.split(separator: ",").forEach { pair in
            let p = pair.split(separator: "=")
            guard p.count == 2 else { return }
            let k = String(p[0]).trimmingCharacters(in: .whitespaces)
            let v = String(p[1]).trimmingCharacters(in: .whitespaces)
            out[k] = v
        }
        return out.isEmpty ? nil : out
    }
}

private extension RecordStore {
    static func split(_ path: String) -> (String, String) {
        guard let i = path.lastIndex(of: "/") else { return ("", path) }
        return (String(path[..<i]), String(path[path.index(after: i)...]))
    }
    static func parseDate(_ s: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }
        let df = DateFormatter()
        df.locale = .init(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: s)
    }
}

private extension Data {
    var prettyPrintedString: String {
        (try? JSONSerialization.jsonObject(with: self))
            .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: [.prettyPrinted, .sortedKeys]) }
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}
