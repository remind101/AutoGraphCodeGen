import Foundation
import AutoGraphParser

extension EnumType: DocumentationGeneratable {
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
    func generateEnumDeclaration(indentation: String) -> String {
        let nextIndentation = "    " + indentation
        let documentation = self.genDocumentationWithNewline(indentation: indentation) // May return empty.
        let cases = self.genCaseMemberDeclarationList(indentation: nextIndentation)
        let rawInit = self.genRawValueInitializerDeclaration(indentation: nextIndentation)
        let rawValue = self.genRawValueVariableDeclaration(indentation: nextIndentation)
        let decodeInit = self.genDecodeValueInitializerDeclaration(indentation: nextIndentation)
        
        return documentation + """
        \(indentation)public enum \(self.name): RawRepresentable, Codable, Hashable, EnumVariableInputParameterEncodable, EnumValueProtocol {
        \(indentation)    public typealias RawValue = String
        
        \(cases)
        \(nextIndentation)case __unknown(RawValue)
        
        \(nextIndentation)public init() {
        \(nextIndentation)    self = .__unknown("")
        \(nextIndentation)}
        
        \(rawInit)
        
        \(decodeInit)
        
        \(rawValue)
        
        \(nextIndentation)public func graphQLInputValue() throws -> String {
        \(nextIndentation)    return self.rawValue
        \(nextIndentation)}
        \(indentation)}
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
        \(indentation)    let container = try decoder.singleValueContainer()
        \(indentation)    let value = try container.decode(String.self)
        
        \(indentation)    self = \(self.name)(rawValue: value) ?? .__unknown(value)
        \(indentation)}
        """
    }
}

extension __EnumValue: Deprecatable {
    var swiftCaseName: String {
        return self.name.lowerCamelCase.escapedFromReservedKeywords
    }
}
