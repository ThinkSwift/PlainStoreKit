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

    // Save by UUID (create or update). Filename is optional display name.
    @discardableResult
    public func save(id: UUID? = nil,
                     folder: String,
                     text: String,
                     filename: String? = nil) throws -> FileRecord {
        let kv = KeyValueLines.parse(text)
        let json = Formats.infer(map: kv)

        let rec: Record
        if let id, let found = try fetch(id: id) {
            rec = found
            if rec.folder != folder {
                rec.folder = folder
                rec.path = folder.isEmpty ? rec.id.uuidString : "\(folder)/\(rec.id.uuidString)"
            }
        } else if let id {
            rec = Record(id: id, folder: folder, filename: filename ?? deriveBaseName(from: text), raw: text)
        } else {
            rec = Record(folder: folder, filename: filename ?? deriveBaseName(from: text), raw: text)
        }

        if let name = filename ?? preferredDisplayName(from: text) { rec.filename = name }
        rec.raw = text
        rec.format = "auto"
        rec.updatedAt = .now
        rec.json = json

        context.insert(rec)
        try context.save()
        return FileRecord(from: rec)
    }

    // Convenience overloads
    @discardableResult
    public func save(folder: String, text: String) throws -> FileRecord {
        try save(id: nil, folder: folder, text: text, filename: nil)
    }

    public func load(id: UUID) throws -> FileRecord {
        guard let rec = try fetch(id: id) else { throw PlainStoreError.notFound(id.uuidString) }
        return FileRecord(from: rec)
    }

    public func load(path: String) throws -> FileRecord {
        guard let rec = try fetch(path: path) else { throw PlainStoreError.notFound(path) }
        return FileRecord(from: rec)
    }

    // Load or create default (by id)
    @discardableResult
    public func loadOrSaveDefault(id: UUID,
                                  folder: String,
                                  defaultText: @autoclosure () -> String) throws -> FileRecord {
        if let rec = try fetch(id: id) { return FileRecord(from: rec) }
        return try save(id: id, folder: folder, text: defaultText(), filename: nil)
    }

    // MARK: - Fetch
    private func fetch(id: UUID) throws -> Record? {
        var d = FetchDescriptor<Record>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    private func fetch(path: String) throws -> Record? {
        var d = FetchDescriptor<Record>(predicate: #Predicate { $0.path == path })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    // MARK: - Display name helpers
    private let namingKeys = ["title", "image", "asset", "text", "caption"]

    private func preferredDisplayName(from text: String) -> String? {
        let name = deriveBaseName(from: text)
        return name.isEmpty ? nil : name
    }

    private func deriveBaseName(from text: String) -> String {
        let kv = KeyValueLines.parse(text)
        for key in namingKeys {
            if let raw = kv[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
                let s = (key == "image" || key == "asset") ? humanizeImageName(raw) : raw
                let name = sanitizeTitle(s)
                if !name.isEmpty { return name }
            }
        }
        let fallback = firstNonEmptyWords(from: text)
        let name = sanitizeTitle(fallback)
        return name
    }

    private func humanizeImageName(_ s: String) -> String {
        let last = s.split(separator: "/").last.map(String.init) ?? s
        let noExt = (last as NSString).deletingPathExtension
        return noExt.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
    }

    private func sanitizeTitle(_ s: String) -> String {
        let t = s.replacingOccurrences(of: "\n", with: " ")
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
}
