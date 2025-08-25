import SwiftData
import Foundation

@Model
public final class Record {
    @Attribute(.unique) public var id: UUID
    public var folder: String
    public var filename: String?          // optional display name
    public var path: String               // "folder/<uuid>"
    public var format: String
    public var raw: String
    public var json: Data?
    public var createdAt: Date
    public var updatedAt: Date
    public var order: Int                 // reserved (unused for now)

    public init(id: UUID = UUID(),
                folder: String,
                filename: String? = nil,
                format: String = "auto",
                raw: String,
                order: Int = 0) {
        self.id = id
        self.folder = folder
        self.filename = filename
        self.format = format
        self.raw = raw
        self.json = nil
        self.createdAt = .now
        self.updatedAt = .now
        self.order = order
        self.path = folder.isEmpty ? id.uuidString : "\(folder)/\(id.uuidString)"
    }
}
