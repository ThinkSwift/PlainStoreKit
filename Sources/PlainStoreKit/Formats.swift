import Foundation

public enum Formats {
    // Optional custom parsers remain available.
    private static var map: [String: (String) -> Data?] = [:]

    public static func register(_ name: String, _ parser: @escaping (String) -> Data?) { map[name] = parser }
    public static func parse(format: String, raw: String) -> Data? { map[format]?(raw) }

    public static func infer(map: [String:String]) -> Data {
        var out: [String:Any] = [:]
        for (k, v) in map {
            out[k] = cast(v)
        }
        return (try? JSONSerialization.data(withJSONObject: out)) ?? Data()
    }

    // Heuristics: bool → int → double → point2 → ISO8601/yyyy-MM-dd → string
    private static func cast(_ s: String) -> Any {
        let lower = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["true","false","yes","no","on","off","1","0"].contains(lower) {
            return ["true","yes","on","1"].contains(lower)
        }
        if let i = Int(s), String(i) == s || s.trimmingCharacters(in: .whitespaces) == String(i) { return i }
        if let d = Double(s), s.contains(".") || s.contains("e") || s.contains("E") { return d }

        // point2: "x, y" or "x y"
        let p = s.replacingOccurrences(of: ",", with: " ").split(separator: " ").map { String($0) }
        if p.count == 2, let x = Double(p[0]), let y = Double(p[1]) {
            return ["x": x, "y": y]
        }

        // date: ISO8601 or yyyy-MM-dd → standard ISO string
        if let iso = ISO8601DateFormatter().date(from: s) {
            return ISO8601DateFormatter().string(from: iso)
        } else {
            let df = DateFormatter()
            df.locale = .init(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd"
            if let d = df.date(from: s) {
                return ISO8601DateFormatter().string(from: d)
            }
        }
        return s
    }

    // Fallback: plain KV to JSON (all strings)
    public static func parseKV(raw: String) -> Data {
        let kv = KeyValueLines.parse(raw)
        return (try? JSONSerialization.data(withJSONObject: kv)) ?? Data()
    }
}
