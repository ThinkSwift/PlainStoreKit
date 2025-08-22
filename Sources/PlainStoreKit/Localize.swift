import Foundation

/// Replaces $(loc:key|Fallback) with a localized string.
enum Localize {
    static func apply(_ text: String, bundle: Bundle) -> String {
        let pattern = #"\$\(\s*loc\s*:\s*([A-Za-z0-9_.-]+)(?:\s*\|\s*([^)]+))?\s*\)"#
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        let ns = text as NSString
        var out = text
        for m in re.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let key = ns.substring(with: m.range(at: 1))
            let def = m.range(at: 2).location != NSNotFound ? ns.substring(with: m.range(at: 2)) : ""
            let val = bundle.localizedString(forKey: key, value: def, table: nil)
            out.replaceSubrange(Range(m.range, in: out)!, with: val)
        }
        return out
    }
}
