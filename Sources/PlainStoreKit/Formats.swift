import Foundation

/// Format registry and built-in KV parsers.
public enum Formats {
    private static var map: [String: (String) -> Data?] = [:]

    public static func register(_ name: String, _ parser: @escaping (String) -> Data?) {
        map[name] = parser
    }

    public static func parse(format: String, raw: String) -> Data? {
        map[format]?(raw)
    }

    /// Plain key:value → JSON (all strings).
    public static func parseKV(raw: String) -> Data {
        let kv = KeyValueLines.parse(raw)
        return (try? JSONSerialization.data(withJSONObject: kv)) ?? Data()
    }

    /// Typed key:value → JSON (types: "string|int|double|bool|point2").
    public static func parseTyped(raw: String, types: [String:String]) -> Data {
        let kv = KeyValueLines.parse(raw)
        var out: [String:Any] = [:]
        for (k, v) in kv {
            let t = types[k] ?? "string"
            if let any = cast(v, t) { out[k] = any }
        }
        return (try? JSONSerialization.data(withJSONObject: out)) ?? Data()
    }

    private static func cast(_ v: String, _ type: String) -> Any? {
        switch type {
        case "string": return v
        case "int":    return Int(v)
        case "double": return Double(v)
        case "bool":   return ["1","true","yes","on"].contains(v.lowercased())
        case "point2":
            let s = v.replacingOccurrences(of: ",", with: " ")
            let a = s.split(separator: " ")
            let x = Double(a.first ?? "0") ?? 0
            let y = Double(a.dropFirst().first ?? "0") ?? 0
            return ["x": x, "y": y]
        default:       return v
        }
    }
}
