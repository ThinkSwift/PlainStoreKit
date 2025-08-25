import Foundation

/// Package-scoped pretty JSON helper.
package extension Data {
    var prettyPrintedString: String {
        guard
            let obj  = try? JSONSerialization.jsonObject(with: self),
            let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
            let str  = String(data: data, encoding: .utf8)
        else { return "" }
        return str
    }
}
