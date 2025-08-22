import Foundation

/// Automatic type inference for key:value maps.
public enum Formats {
    public static func infer(map: [String:String]) -> Data {
        var out: [String:Any] = [:]
        for (k, v) in map { out[k] = cast(v) }
        return (try? JSONSerialization.data(withJSONObject: out)) ?? Data()
    }

    // Heuristics: bool → int → double → point2 → ISO8601 / yyyy-MM-dd → string
    private static func cast(_ s: String) -> Any {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = t.lowercased()
        if ["true","false","yes","no","on","off","1","0"].contains(lower) {
            return ["true","yes","on","1"].contains(lower)
        }
        if let i = Int(t), String(i) == t { return i }
        if let d = Double(t), t.contains(".") || t.contains("e") || t.contains("E") { return d }

        let parts = t.replacingOccurrences(of: ",", with: " ")
            .split(separator: " ").map(String.init)
        if parts.count == 2, let x = Double(parts[0]), let y = Double(parts[1]) {
            return ["x": x, "y": y]
        }

        let iso = ISO8601DateFormatter()
        if let dd = iso.date(from: t) { return iso.string(from: dd) }
        let df = DateFormatter()
        df.locale = .init(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        if let d2 = df.date(from: t) { return iso.string(from: d2) }

        return t
    }
}
