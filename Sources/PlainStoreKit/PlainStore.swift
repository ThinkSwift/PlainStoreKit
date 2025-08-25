import SwiftData
import Foundation

public enum PlainStoreError: Error { case notFound(String) }

@MainActor
public final class PlainStore {
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }

    public convenience init() { self.init(inMemory: false) }

    public init(inMemory: Bool) {
        do {
            if inMemory {
                let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(for: Record.self, configurations: cfg)
            } else {
                container = try ModelContainer(for: Record.self)
            }
        } catch {
            let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Record.self, configurations: cfg)
            assertionFailure("ModelContainer failed; fallback to in-memory: \(error)")
        }
    }

    // Save or update by display name derived from text
    @discardableResult
    public func save(folder: String, text: String) throws -> FileRecord {
        let name = baseName(from: text)
        return try save(folder: folder, name: name, text: text)
    }

    // Save or update by explicit display name
    @discardableResult
    public func save(folder: String, name: String, text: String) throws -> FileRecord {
        let kv = KeyValueLines.parse(text)
        let json = Formats.infer(map: kv)

        if let rec = try fetchByName(folder: folder, name: name) {
            rec.filename = name
            rec.raw = text
            rec.format = "auto"
            rec.updatedAt = Date.now
            rec.json = json
            context.insert(rec)
            try context.save()
            return FileRecord(from: rec)
        } else {
            let rec = Record(folder: folder, filename: name, format: "auto", raw: text)
            rec.json = json
            rec.updatedAt = Date.now
            context.insert(rec)
            try context.save()
            return FileRecord(from: rec)
        }
    }

    // Load by explicit display name
    public func load(folder: String, name: String) throws -> FileRecord {
        guard let rec = try fetchByName(folder: folder, name: name) else {
            throw PlainStoreError.notFound("\(folder)/\(name)")
        }
        return FileRecord(from: rec)
    }

    // Load by name derived from text
    public func loadByDerivedName(folder: String, text: String) throws -> FileRecord {
        try load(folder: folder, name: baseName(from: text))
    }

    // Load or create default if missing (explicit name)
    @discardableResult
    public func loadOrSaveDefault(folder: String,
                                  name: String,
                                  defaultText: @autoclosure () -> String) throws -> FileRecord {
        if let rec = try fetchByName(folder: folder, name: name) { return FileRecord(from: rec) }
        return try save(folder: folder, name: name, text: defaultText())
    }

    // MARK: - Queries

    private func fetchByName(folder: String, name: String) throws -> Record? {
        // Compatible with optional filename schemas: filter in memory
        var d = FetchDescriptor<Record>(predicate: #Predicate { $0.folder == folder })
        d.fetchLimit = 200
        let rows = try context.fetch(d)
        return rows.first { $0.filename == name }
    }

    // MARK: - Naming

    private func baseName(from text: String) -> String {
        let kv = KeyValueLines.parse(text)
        for key in ["title", "image", "asset", "text", "caption"] {
            if let raw = kv[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
                let s = (key == "image" || key == "asset") ? humanizeImageName(raw) : raw
                let name = sanitizeTitle(s)
                if !name.isEmpty { return name }
            }
        }
        let fallback = firstNonEmptyWords(from: text)
        let name = sanitizeTitle(fallback)
        return name.isEmpty ? timestampName() : name
    }

    private func humanizeImageName(_ s: String) -> String {
        let last = s.split(separator: "/").last.map(String.init) ?? s
        let noExt = (last as NSString).deletingPathExtension
        return noExt.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
    }

    private func sanitizeTitle(_ s: String) -> String {
        let t = s
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: ":", with: " ")
        let collapsed = t.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return String(collapsed.prefix(40)).trimmingCharacters(in: .whitespaces)
    }

    private func firstNonEmptyWords(from text: String) -> String {
        for line in text.split(whereSeparator: \.isNewline) {
            let s = line.trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty else { continue }
            if let i = s.firstIndex(of: ":"), i != s.endIndex {
                let v = s[s.index(after: i)...].trimmingCharacters(in: .whitespaces)
                if !v.isEmpty { return v }
            } else { return s }
        }
        return ""
    }

    private func timestampName() -> String {
        let f = DateFormatter()
        f.locale = .init(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return f.string(from: Date.now)
    }
}
