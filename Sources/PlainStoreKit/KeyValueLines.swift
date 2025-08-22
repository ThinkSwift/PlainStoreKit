import Foundation

public enum KeyValueLines {
    public static func parse(_ raw: String) -> [String:String] {
        var out: [String:String] = [:]
        raw.split(whereSeparator: \.isNewline).forEach { line in
            let s = line.trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty, !s.hasPrefix("#"),
                  let i = s.firstIndex(of: ":") else { return }
            let k = String(s[..<i]).trimmingCharacters(in: .whitespaces)
            let v = String(s[s.index(after: i)...]).trimmingCharacters(in: .whitespaces)
            out[k] = v
        }
        return out
    }

    public static func join(_ map: [String:String]) -> String {
        map.keys.sorted().map { "\($0): \(map[$0] ?? "")" }.joined(separator: "\n")
    }
}
