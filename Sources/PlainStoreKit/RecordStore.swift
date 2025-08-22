import SwiftData
import Foundation

@MainActor
public final class RecordStore {
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }

    public init(inMemory: Bool = false) {
        let cfg = ModelConfiguration("PlainStore",
                                     for: Record.self,
                                     isStoredInMemoryOnly: inMemory)
        self.container = try! ModelContainer(for: Record.self, configurations: cfg)
    }

    @discardableResult
    public func upsert(folder: String,
                       filename: String,
                       format: String,
                       raw: String,
                       date: Date = .now,
                       order: Int = 0) throws -> Record {
        let path = folder.isEmpty ? filename : "\(folder)/\(filename)"
        let rec = try fetch(path: path) ?? Record(folder: folder,
                                                  filename: filename,
                                                  format: format,
                                                  raw: raw,
                                                  date: date,
                                                  order: order)
        rec.raw = raw
        rec.format = format
        rec.date = date
        rec.order = order
        rec.updatedAt = .now
        rec.json = Formats.parse(format: format, raw: raw)
        context.insert(rec)
        try context.save()
        return rec
    }

    public func fetch(folder: String? = nil) throws -> [Record] {
        var predicate: Predicate<Record> = #Predicate { _ in true }
        if let f = folder { predicate = #Predicate { $0.folder == f } }
        let sort = [
            SortDescriptor(\.date, order: .reverse),
            SortDescriptor(\.order),
            SortDescriptor(\.filename)
        ]
        return try context.fetch(FetchDescriptor<Record>(predicate: predicate, sortBy: sort))
    }

    public func fetch(path: String) throws -> Record? {
        try context.fetch(FetchDescriptor<Record>(
            predicate: #Predicate { $0.path == path },
            fetchLimit: 1
        )).first
    }
}
