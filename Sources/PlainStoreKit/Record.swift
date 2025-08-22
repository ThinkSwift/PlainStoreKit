import SwiftData
import Foundation

@Model
public final class Record {
    @Attribute(.unique) public var path: String
    public var folder: String
    public var filename: String
    public var format: String
    public var raw: String
    public var json: Data?
    public var date: Date
    public var order: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(folder: String,
                filename: String,
                format: String,
                raw: String,
                date: Date = .now,
                order: Int = 0) {
        self.folder = folder
        self.filename = filename
        self.format = format
        self.raw = raw
        self.date = date
        self.order = order
        self.createdAt = .now
        self.updatedAt = .now
        self.path = folder.isEmpty ? filename : "\(folder)/\(filename)"
    }
}
