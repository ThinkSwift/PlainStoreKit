import Foundation

/// Minimal "key: value" parser (no headers, no commands).
public enum KeyValueLines {
    public static func parse(_ raw: String) -> [String:String] {
        var out: [String:String] = [:]
        raw.split(whereSeparator: \.isNewline).forEach { line in
            let s = line.trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty, !s.hasPrefix("#"), let i = s.firstIndex(of: ":") else { return }
            let k = String(s[..<i]).trimmingCharacters(in: .whitespaces)
            let v = String(s[s.index(after: i)...]).trimmingCharacters(in: .whitespaces)
            out[k] = v
        }
        return out
    }
}
