import Foundation

public struct FileRecord: Sendable {
    public let path: String
    public let folder: String
    public let filename: String
    public let order: Int
    public let createdAt: Date
    public let updatedAt: Date
    public let raw: String
    public let jsonPretty: String

    public init(path: String, folder: String, filename: String, order: Int,
                createdAt: Date, updatedAt: Date, raw: String, jsonPretty: String) {
        self.path = path
        self.folder = folder
        self.filename = filename
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.raw = raw
        self.jsonPretty = jsonPretty
    }
}

extension FileRecord {
    init(from r: Record) {
        self.init(
            path: r.path,
            folder: r.folder,
            filename: r.filename,
            order: r.order,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
            raw: r.raw,
            jsonPretty: r.json?.prettyPrintedString ?? "{}"
        )
    }
}
