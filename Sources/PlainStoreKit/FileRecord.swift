import Foundation

public struct FileRecord: Sendable {
    public let id: UUID
    public let path: String
    public let folder: String
    public let filename: String?     // display name
    public let createdAt: Date
    public let updatedAt: Date
    public let raw: String
    public let jsonPretty: String

    public init(id: UUID,
                path: String,
                folder: String,
                filename: String?,
                createdAt: Date,
                updatedAt: Date,
                raw: String,
                jsonPretty: String) {
        self.id = id
        self.path = path
        self.folder = folder
        self.filename = filename
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.raw = raw
        self.jsonPretty = jsonPretty
    }
}

extension FileRecord {
    init(from r: Record) {
        self.init(
            id: r.id,
            path: r.path,
            folder: r.folder,
            filename: r.filename,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
            raw: r.raw,
            jsonPretty: r.json?.prettyPrintedString ?? "{}"
        )
    }
}
