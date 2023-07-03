import Foundation
import AutoGraphParser

extension String {
    var first: Substring {
        return self.prefix(1)
    }
    
    var last: Substring {
        return self.suffix(1)
    }
    
    var second: Substring {
        return self.dropFirst().prefix(1)
    }
    
    var uppercaseFirst: String {
        return self.first.uppercased() + String(self.dropFirst())
    }
    
    var lowercaseFirst: String {
        return self.first.lowercased() + String(self.dropFirst())
    }
    
    var lowerCamelCase: String {
        guard !self.isLowerCaseFirst else {
            return self
        }
        
        guard !self.isLowerCaseSecond else {
            return self.lowercaseFirst
        }
        
        return self.lowercased()
    }
    
    var isLowerCaseFirst: Bool {
        return self.first.lowercased() == String(self.first)
    }
    
    var isLowerCaseSecond: Bool {
        return self.second.lowercased() == String(self.second)
    }
}

extension Array where Element == __Field {
    func __fieldsDictionary() -> [FieldName: __Field] {
        return self.reduce(into: [:]) { result, field in
            // NOTE: If we end up needing the base type (such as internal to a list) this
            // is a good place to cache it.
            result[field.name] = field
        }
    }
}

extension String? {
    /// For a doc string such as `"wow\nthis is documentation"` this will produce:
    /// `"\(indentation)/// wow\n\(indentation)/// this is documentation"`.
    ///
    /// Returns empty (`""`) for `nil` or empty `documentationMarkup`.
    func toDocCommentOrEmpty(indentation: String) -> String {
        guard let self = self, self != "" else {
            return ""
        }
        return self.toDocComment(indentation: indentation)
    }
}

extension String {
    /// For a doc string such as `"wow\nthis is documentation"` this will produce:
    /// `"\(indentation)/// wow\n\(indentation)/// this is documentation"`.
    func toDocComment(indentation: String) -> String {
        let newlineReplaced = self.replacingOccurrences(of: "\n", with: "\n\(indentation)/// ")
        return "\(indentation)/// \(newlineReplaced)"
    }
}
