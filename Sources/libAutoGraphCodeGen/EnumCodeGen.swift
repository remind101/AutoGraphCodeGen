import Foundation
import AutoGraphParser

extension EnumType: DocumentationGeneratable {
    // TODO: include this under the schema's namespace
    /// `EnumDecl` in Swift AST.
    ///
    /// For
    /// ```
    /// enum HairColor {
    ///   BLUE
    ///   PURPLE
    ///   PINK
    ///   GOLD
    /// }
    /// ```
    /// generates
    /// ```
    /// public enum HairColor: RawRepresentable, Codable, Hashable, EnumVariableInputParameterEncodable, EnumValueProtocol {
    ///     public typealias RawValue = String
    ///
    ///     case blue
    ///     case purple
    ///     case pink
    ///     case gold
    ///     case __unknown(RawValue)
    ///
    ///     public init() {
    ///         self = .__unknown("")
    ///     }
    ///
    ///     public init?(rawValue: String) {
    ///         switch rawValue {
    ///         case "BLUE":
    ///             self = .blue
    ///         case "PURPLE":
    ///             self = .purple
    ///         case "PINK":
    ///             self = .pink
    ///         case "GOLD":
    ///             self = .gold
    ///         default:
    ///             self = .__unknown(rawValue)
    ///         }
    ///     }
    ///     public var rawValue: String {
    ///         switch self {
    ///         case .blue:
    ///             return "BLUE"
    ///         case .purple:
    ///             return "PURPLE"
    ///         case .pink:
    ///             return "PINK"
    ///         case .gold:
    ///             return "GOLD"
    ///         case .__unknown(let val):
    ///             return val
    ///         }
    ///     }
    ///
    ///     public func graphQLInputValue() throws -> String {
    ///         return self.rawValue
    ///     }
    /// }
    /// ```
    func genEnumDeclaration() -> String {
        let indentation = "    "
        let documentation = self.genDocumentationWithNewline(indentation: "") // May return empty.
        let cases = self.genCaseMemberDeclarationList(indentation: indentation)
        let rawInit = self.genRawValueInitializerDeclaration(indentation: indentation)
        let rawValue = self.genRawValueVariableDeclaration(indentation: indentation)
        let decodeInit = self.genDecodeValueInitializerDeclaration(indentation: indentation)
        
        return documentation + """
        public enum \(self.name): RawRepresentable, Codable, Hashable, EnumVariableInputParameterEncodable, EnumValueProtocol {
            public typealias RawValue = String
        
        \(cases)
            case __unknown(RawValue)
        
            public init() {
                self = .__unknown("")
            }
        
        \(rawInit)
        
        \(decodeInit)
        
        \(rawValue)
        
            public func graphQLInputValue() throws -> String {
                return self.rawValue
            }
        }
        """
    }
    
    var documentationMarkup: String? {
        self.description
    }
    
    /// `MemberDeclList`.
    func genCaseMemberDeclarationList(indentation: String) -> String {
        let cases: [String] = self.enumValues.map {
            // Deprecation strings handled by protocols
            let documentation = $0.genDocumentationWithNewline(indentation: indentation)
            let `case` = "case \($0.swiftCaseName)"
            return "\(documentation)\(indentation)\(`case`)"
        }
        return cases.joined(separator: "\n")
    }
    
    /// `InitializerDecl`.
    func genRawValueInitializerDeclaration(indentation: String) -> String {
        let nextIndentation = indentation + "    "
        let switchCases: [String] = self.enumValues.map {
            """
            \(nextIndentation)case "\($0.name)":
            \(nextIndentation)    self = .\($0.swiftCaseName)
            """
        }
        return """
        \(indentation)public init?(rawValue: String) {
        \(indentation)    switch rawValue {
        \(switchCases.joined(separator: "\n"))
        \(indentation)    default:
        \(indentation)        self = .__unknown(rawValue)
        \(indentation)    }
        \(indentation)}
        """
    }
    
    /// `VariableDecl`.
    func genRawValueVariableDeclaration(indentation: String) -> String {
        let nextIndentation = indentation + "    "
        let switchCases: [String] = self.enumValues.map {
            """
            \(nextIndentation)case .\($0.swiftCaseName):
            \(nextIndentation)    return "\($0.name)"
            """
        }
        return """
        \(indentation)public var rawValue: String {
        \(indentation)    switch self {
        \(switchCases.joined(separator: "\n"))
        \(indentation)    case .__unknown(let val):
        \(indentation)        return val
        \(indentation)    }
        \(indentation)}
        """
    }
    
    /// `InitializerDecl`.
    func genDecodeValueInitializerDeclaration(indentation: String) -> String {
        return """
        \(indentation)public init(from decoder: Decoder) throws {
        \(indentation)\(indentation)let container = try decoder.singleValueContainer()
        \(indentation)\(indentation)let value = try container.decode(String.self)
        
        \(indentation)\(indentation)self = \(self.name)(rawValue: value) ?? .__unknown(value)
        \(indentation)}
        """
    }
}

extension __EnumValue: Deprecatable {
    var swiftCaseName: String {
        return self.name.lowerCamelCase.escapedFromReservedKeywords
    }
}
