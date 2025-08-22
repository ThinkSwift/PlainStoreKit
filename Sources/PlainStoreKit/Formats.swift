import Foundation

/// Format registry and parser dispatch.
public enum Formats {
    private static var map: [String: (String) -> Data?] = [:]

    public static func register(_ name: String, _ parser: @escaping (String) -> Data?) {
        map[name] = parser
    }

    public static func parse(format: String, raw: String) -> Data? {
        map[format]?(raw)
    }
}

