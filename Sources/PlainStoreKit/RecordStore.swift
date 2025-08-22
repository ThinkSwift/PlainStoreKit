import SwiftData
import Foundation

@MainActor
public final class RecordStore {
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }

    public init(inMemory: Bool = false) {
        if inMemory {
            // In-memory configuration
            let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
            self.container = try! ModelContainer(for: Record.self, configurations: cfg)
        } else {
            // Default on-disk container
            self.container = try! ModelContainer(for: Record.self)
        }
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
        if let f = folder {
            predicate = #Predicate { $0.folder == f }
        }
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
