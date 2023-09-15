import Foundation
import AutoGraphParser
import SwiftSyntax
// TODO: When SwiftParser v509 drops we can use string literals directly into
// AST nodes like so - `https://github.com/apple/swift-syntax/blob/main/Sources/SwiftSyntax/Documentation.docc/Working%20with%20SwiftSyntax.md#building-syntax-trees`
//import SwiftParser

// BIG-FAT-TODO: skip(if: true) (find "SkipIfTrue" in output) needs to actually do such
// i.e. Directives may need specialized customization points for their runtime. We can support
// the expected ones like skip and include automagically though by just mapping to Optional.

/// Capable of producing the components of a `VariableDecl` in the Swift AST.
protocol VariableDeclarationGeneratable {
    /// `IdentifierPattern` in AST.
    /// E.g. with `let x = 1` then "x" is the `IdentifierPattern`.
    var swiftVariableIdentifierName: String { get }
    
    /// `SimpleTypeIdentifier` in AST.
    /// Returns `ReWrappedSwiftType` to force some underlying choice about
    /// how to translate the GQL type to an acceptable Swift type.
    /// E.g. with `let x: Int` then "Int" is the `SimpleTypeIdentifier`.
    func swiftVariableTypeIdentifier(schemaName: String) throws -> ReWrappedSwiftType
}

/// Capable of producing the components of  a `StructDecl` in the Swift AST and
/// the associated `VariableDecl` whose type is that struct.
/// This is specifically for "nested" structs that are generated from object fields and
/// inline fragments nested within a query, as opposed to the root level struct from the
/// `OperationDefinition` or `FragmentDefinition`.
protocol NestedStructDeclarationGeneratable: VariableDeclarationGeneratable {
    associatedtype SortKey: Comparable
    var selectionSet: SelectionSetIR { get }
    var sortKey: SortKey { get }
    
    func swiftStructDeclarationTypeIdentifier() throws -> ReWrappedSwiftType
}

extension NestedStructDeclarationGeneratable {
    func nestedStructDeclaration(indentation: String, schemaName: String) throws -> (propertyVariableDeclaration: String, structDeclarations: String) {
        let propertyVariableDeclaration = try self.genVariableDeclaration(indentation: indentation, schemaName: schemaName)
        let structDeclaration = try self.selectionSet.genStructDeclaration(parentField: self, indentation: indentation, schemaName: schemaName)
        return (propertyVariableDeclaration, structDeclaration)
    }
}

extension FragmentSpread: VariableDeclarationGeneratable {
    var swiftStructTypeIdentifierString: String {
        self.name.value
    }
    
    var swiftVariableIdentifierName: String {
        self.name.value.lowercaseFirst
    }
    
    func swiftVariableTypeIdentifier(schemaName: String) -> ReWrappedSwiftType {
        self.swiftStructDeclarationTypeIdentifier().withPrefixedBase("\(schemaName).")
    }
    
    func swiftStructDeclarationTypeIdentifier() -> ReWrappedSwiftType {
        .val(self.name.value)
    }
}

extension SelectionSetIR {
    public func genInitializerDeclarationParameterList(schemaName: String, parentFieldBaseTypeName: String?, omit__typename: Bool = false) throws -> String {
        // MARK: - __typename-injection:
        let orderedScalarFields = self.scalarFields.ordered(omitting__typename: omit__typename)
        let scalarParameters = orderedScalarFields.map {
            let name = $0.swiftVariableIdentifierName
            if name == "__typename", let typename = parentFieldBaseTypeName {
                return "\(name): String = \"\(typename)\""
            }
            else {
                return genFunctionParameter(name: name, type: $0.swiftVariableTypeIdentifier(schemaName: schemaName))
            }
        }
                
        let orderedObjectFields = self.objectFields.ordered()
        let nestedObjectStructParameters = try orderedObjectFields.map { objectField in
            let type = try {
                let baseName = try objectField.swiftVariableTypeIdentifier(schemaName: schemaName)
                if let parentFieldBaseTypeName = parentFieldBaseTypeName, parentFieldBaseTypeName != baseName.genSwiftBaseTypeName() {
                    return try objectField.swiftVariableTypeIdentifier(schemaName: schemaName).withPrefixedBase("\(parentFieldBaseTypeName).")
                }
                return baseName
            }()
            return genFunctionParameter(name: objectField.swiftVariableIdentifierName, type: type)
        }
        
        let orderedFragmentSpreads = self.fragmentSpreads.ordered()
        let fragmentParameters = orderedFragmentSpreads.map {
            genFunctionParameter(name: $0.swiftVariableIdentifierName, type: $0.swiftVariableTypeIdentifier(schemaName: schemaName))
        }
        
        let orderedInlineFragments = self.inlineFragments.ordered()
        let inlineFragmentParameters = orderedInlineFragments.map {
            genFunctionParameter(name: $0.swiftVariableIdentifierName, type: $0.swiftVariableTypeIdentifier(schemaName: schemaName))
        }
        
        let everything = scalarParameters + nestedObjectStructParameters + fragmentParameters + inlineFragmentParameters
        return everything.joined(separator: ", ")
    }
    
    public func genInitializerCodeBlockAssignmentExpressions(indentation: String, omit__typename: Bool = false) -> String {
        let orderedScalarFields = self.scalarFields.ordered(omitting__typename: omit__typename)
        let scalarAssignments = orderedScalarFields.map {
            "\(indentation)self.\($0.swiftVariableIdentifierName) = \($0.swiftVariableIdentifierName)"
        }
        
        let orderedObjectFields = self.objectFields.ordered()
        let objectStructAssignments = orderedObjectFields.map {
            "\(indentation)self.\($0.field.swiftVariableIdentifierName) = \($0.field.swiftVariableIdentifierName)"
        }
        
        let orderedFragmentSpreads = self.fragmentSpreads.ordered()
        let fragmentAssignments = orderedFragmentSpreads.map {
            "\(indentation)self.\($0.swiftVariableIdentifierName) = \($0.swiftVariableIdentifierName)"
        }
        
        let orderedInlineFragments = self.inlineFragments.ordered()
        let inlineFragmentAssignments = orderedInlineFragments.map {
            "\(indentation)self.\($0.swiftVariableIdentifierName) = \($0.swiftVariableIdentifierName)"
        }
        
        let everything = scalarAssignments + objectStructAssignments + fragmentAssignments + inlineFragmentAssignments
        return everything.joined(separator: "\n")
    }
    
    public func decodableCodeBlockAssignmentExpressions(indentation: String, schemaName: String, parentFieldBaseTypeName: String?) throws -> String {
        let orderedScalarFields = self.scalarFields.ordered(omitting__typename: false)
        var scalarAssignments: [String] = orderedScalarFields.map { field in
            
            // MARK: - __typename-injection:
            
            // Typename will be generated as a local variable, so we just need an assignment here.
            if field.swiftVariableIdentifierName == "__typename" {
                return "\(indentation)self.__typename = typename"
            }
            
            let typeName: String = field.swiftVariableTypeIdentifier(schemaName: schemaName).genSwiftType();
            return "\(indentation)self.\(field.swiftVariableIdentifierName) = try values.decode(\(typeName).self, forKey: .\(field.swiftVariableIdentifierName))"
        }
        scalarAssignments.insert("\(indentation)let typename = try values.decode(String.self, forKey: .__typename)", at: 0)
        
        let orderedObjectFields = self.objectFields.ordered()
        let objectStructAssignments = try orderedObjectFields.map { objectField in
            let type = try {
                let baseName = try objectField.swiftVariableTypeIdentifier(schemaName: schemaName)
                if let parentFieldBaseTypeName = parentFieldBaseTypeName, parentFieldBaseTypeName != baseName.genSwiftBaseTypeName() {
                    return try objectField.swiftVariableTypeIdentifier(schemaName: schemaName).withPrefixedBase("\(parentFieldBaseTypeName).")
                }
                return baseName
            }()
            return "\(indentation)self.\(objectField.swiftVariableIdentifierName) = try values.decode(\(type.genSwiftType()).self, forKey: .\(objectField.swiftVariableIdentifierName))"
        }
        
        let orderedFragmentSpreads = self.fragmentSpreads.ordered()
        let fragmentAssignments = orderedFragmentSpreads.map {
            "\(indentation)self.\($0.swiftVariableIdentifierName) = try \(schemaName).\($0.swiftStructTypeIdentifierString)(from: decoder)"
        }
        
        let orderedInlineFragments = self.inlineFragments.ordered()
        let inlineFragmentAssignments = orderedInlineFragments.map {
            "\(indentation)self.\($0.swiftVariableIdentifierName) = typename == \"\($0.selectionSet.typeInformation.graphQLTypeName)\" ? try \($0.swiftStructTypeIdentifierString)(from: decoder) : nil"
        }
        
        var everything = scalarAssignments + objectStructAssignments + fragmentAssignments + inlineFragmentAssignments
        if (scalarAssignments.count + objectStructAssignments.count) > 0 {
            everything.insert("\(indentation)let values = try decoder.container(keyedBy: CodingKeys.self)", at: 0)
        }
        return everything.joined(separator: "\n")
    }
    
    /// `EnumDecl`.
    public func codingKeyEnumDeclarations(indentation: String) throws -> String {
        let orderedScalarFields = self.scalarFields.ordered(omitting__typename: false)
        let scalars = orderedScalarFields.map {
            "\(indentation)case \($0.swiftVariableIdentifierName)"
        }
        
        let orderedObjectFields = self.objectFields.ordered()
        let objectStructAssignments = orderedObjectFields.map {
            "\(indentation)case \($0.swiftVariableIdentifierName)"
        }
        let everything = scalars + objectStructAssignments
        return everything.joined(separator: "\n")
    }
    
    public func genScalarPropertyVariableDeclarations(indentation: String, schemaName: String, parentFieldBaseTypeName: String, omit__typename: Bool = false) throws -> String {
        // MARK: - __typename-injection:
        let orderedScalarFields = self.scalarFields.ordered(omitting__typename: omit__typename)
        let fields = try orderedScalarFields.map {
            if $0.swiftVariableIdentifierName == "__typename" {
                return "\(indentation)public private(set) var \($0.swiftVariableIdentifierName): String = \"\(parentFieldBaseTypeName)\""
            }
            return try $0.genVariableDeclaration(indentation: indentation, schemaName: schemaName)
        }
        return fields.joined(separator: "\n")
    }
    
    /// `VariableDecl`.
    public func genFragmentSpreadPropertyVariableDeclarations(indentation: String, schemaName: String) throws -> String {
        let orderedFragmentSpreads = self.fragmentSpreads.ordered()
        return try orderedFragmentSpreads.map {
            try $0.genVariableDeclaration(indentation: indentation, schemaName: schemaName)
        }.joined(separator: "\n")
    }
    
    /// `StructDecl`.
    public func genObjectNestedStructDeclarations(indentation: String, schemaName: String) throws -> (propertyVariableDeclarations: String, structDeclarations: String) {
        let (propertyVariableDeclarations, structDeclarations) = try nestedStructDeclarations(nestedObjects: self.objectFields, indentation: indentation, schemaName: schemaName)
        return (propertyVariableDeclarations.joined(separator: "\n"), structDeclarations.joined(separator: "\n\n"))
    }
    
    public func inlineFragmentSubStructDefinitions(indentation: String, schemaName: String) throws -> (propertyVariableDeclarations: String, structDeclarations: String) {
        let (propertyVariableDeclarations, structDeclarations) = try nestedStructDeclarations(nestedObjects: self.inlineFragments, indentation: indentation, schemaName: schemaName)
        return (propertyVariableDeclarations.joined(separator: "\n"), structDeclarations.joined(separator: "\n\n"))
    }
}

// MARK: - Helper Functions.

extension VariableDeclarationGeneratable {
    /// `VariableDecl`.
    func genVariableDeclaration(indentation: String, schemaName: String) throws -> String {
        // TODO: gen documentation.
        let name = self.swiftVariableIdentifierName
        let type = try self.swiftVariableTypeIdentifier(schemaName: schemaName)
        let propertyType = type.genSwiftType()
        let defaultValue = type.genSwiftDefaultInitializer()
        return "\(indentation)public private(set) var \(name): \(propertyType) = \(defaultValue)"
    }
}

/// `FunctionParameter`.
func genFunctionParameter(name: String, type: ReWrappedSwiftType) -> String {
    let propertyType = type.genSwiftType()
    let defaultValue = type.genSwiftDefaultInitializer()
    return "\(name): \(propertyType) = \(defaultValue)"
}

func nestedStructDeclarations(nestedObjects: [some NestedStructDeclarationGeneratable], indentation: String, schemaName: String) throws -> (propertyVariableDeclarations: [String], structDeclarations: [String]) {
    let orderedObjectFields = nestedObjects.ordered()
    
    return try orderedObjectFields
        .map {
            try $0.nestedStructDeclaration(indentation: indentation, schemaName: schemaName)
        }
        .reduce(into: (propertyVariableDeclarations: [String](), structDeclarations: [String]())) { result, defs in
            let (propertyDef, subStructDef) = defs
            result.0.append(propertyDef)
            result.1.append(subStructDef)
        }
}

// MARK: - Nested Object Struct Codegen.

extension SelectionSetIR {
    /// `StructDecl`.
    public func genStructDeclaration(parentField: any NestedStructDeclarationGeneratable, indentation: String, schemaName: String) throws -> String {
        let baseTypeName = try parentField.swiftStructDeclarationTypeIdentifier().genSwiftBaseTypeName()
        let typeDefinition = "\(indentation)public struct \(baseTypeName): Codable {"
        let nextIndentation = indentation + "    "
        let initializer = try self.genInitializerDeclaration(indentation: nextIndentation, schemaName: schemaName, parentFieldBaseTypeName: baseTypeName)
        let innerCode = try self.genPropertyAndNestedStructDeclarations(indentation: nextIndentation, schemaName: schemaName, parentFieldBaseTypeName: baseTypeName)
        return """
        \(typeDefinition)
        \(initializer)
        
        \(innerCode)
        \(indentation)}
        """
    }
    
    /// `InitializerDecl`.
    public func genInitializerDeclaration(indentation: String, schemaName: String, parentFieldBaseTypeName: String) throws -> String {
        let params = try self.genInitializerDeclarationParameterList(schemaName: schemaName, parentFieldBaseTypeName: parentFieldBaseTypeName)
        let propertyAssignments = self.genInitializerCodeBlockAssignmentExpressions(indentation: "\(indentation)    ")
        let decodableAssignments = try self.decodableCodeBlockAssignmentExpressions(indentation: "\(indentation)    ", schemaName: schemaName, parentFieldBaseTypeName: parentFieldBaseTypeName)
        
        return """
        \(indentation)public init(\(params)) {
        \(propertyAssignments)
        \(indentation)}
        
        \(indentation)public init(from decoder: Decoder) throws {
        \(decodableAssignments)
        \(indentation)}
        """
    }
    
    public func genPropertyAndNestedStructDeclarations(indentation: String, schemaName: String, parentFieldBaseTypeName: String) throws -> String {
        let scalarPropertyVariableDeclarations = try self.genScalarPropertyVariableDeclarations(indentation: indentation, schemaName: schemaName, parentFieldBaseTypeName: parentFieldBaseTypeName)
        let fragmentSpreadPropertyDefinitions = try self.genFragmentSpreadPropertyVariableDeclarations(indentation: indentation, schemaName: schemaName)
        let (objectSubStructPropertyDefinitions, objectSubStructDefinitions) =
        try self.genObjectNestedStructDeclarations(indentation: indentation, schemaName: schemaName)
        let (inlineFragmentSubStructPropertyDefinitions, inlineFragmentSubStructDefinitions) =
        try self.inlineFragmentSubStructDefinitions(indentation: indentation, schemaName: schemaName)
        
        let propertyDeclarations = [
            scalarPropertyVariableDeclarations,
            objectSubStructPropertyDefinitions,
            fragmentSpreadPropertyDefinitions,
            inlineFragmentSubStructPropertyDefinitions,
        ].compactMap { $0 == "" ? nil : $0 }.joined(separator: "\n\n")
        
        let subStructDeclarations = [
            objectSubStructDefinitions,
            inlineFragmentSubStructDefinitions,
        ].compactMap { $0 == "" ? nil : $0 }.joined(separator: "\n\n")
        
        guard subStructDeclarations != "" else {
            return """
            \(propertyDeclarations)
            """
        }
        
        return """
        \(propertyDeclarations)
        
        \(subStructDeclarations)
        """
    }
}

extension Array where Element: NestedStructDeclarationGeneratable {
    func ordered() -> Array<Element> {
        self.sorted { (left, right) -> Bool in
            left.sortKey < right.sortKey
        }
    }
}

typealias ScalarFields = [FieldIR]
extension ScalarFields {
    func ordered(omitting__typename: Bool) -> [FieldIR] {
        self.sorted { (left, right) -> Bool in
                left.swiftVariableIdentifierName < right.swiftVariableIdentifierName
            }
            .filter { !omitting__typename || $0.swiftVariableIdentifierName != "__typename" }
    }
}

extension [FragmentSpread] {
    func ordered() -> [FragmentSpread] {
        self.sorted { $0.name.value < $1.name.value }
    }
}
