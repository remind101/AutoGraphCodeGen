import Foundation
import AutoGraphParser

// TODO: Update all this for 2021 spec.

public struct FragmentQueryGenerator {
    public let fragmentQueryExpression: String?
    public let subFragments: Set<FragmentName>
    
    private let fragmentQueryName = "fragment"
    
    public func generateFragmentsQuery(withTypeName typeName: String, outputSchemaName: String, indentation: String) -> String {
        let nextIndentation = "    " + indentation
        
        let otherFragmentCalls = self.generateFragmentCalls(indentation: nextIndentation, outputSchemaName: outputSchemaName)
        let fragmentConstructors = otherFragmentCalls != nil ? "\(otherFragmentCalls!)\n\n" : ""
        let fragmentQueryDeclaration: String = {
            guard let fragmentQuery = self.fragmentQueryExpression else {
                return ""
            }
            return "\(indentation)    let \(fragmentQueryName) = \(fragmentQuery)\n"
        }()
        let fragmentsArray =  "let fragments = \(self.generateFragmentsArray(indentation: indentation + "    "))"
        let fragmentsDecBody = "\(fragmentConstructors)\(fragmentQueryDeclaration)"
        let fragmentsDeclaration = """
        \(indentation)public static var fragments: [FragmentDefinition] {
        \(fragmentsDecBody)
        \(indentation)    \(fragmentsArray)
        \(indentation)
        \(indentation)    return fragments
        \(indentation)}
        \(indentation)
        \(indentation)public var fragments: [FragmentDefinition] {
        \(indentation)    return \(typeName).fragments
        \(indentation)}
        """
        
        return fragmentsDeclaration
    }
    
    private func generateFragmentsArray(indentation: String) -> String {
        if self.subFragments.count == 0 {
            guard self.fragmentQueryExpression != nil else {
                return "[FragmentDefinition]()"
            }
            return "[\(self.fragmentQueryName)]"
        }
        
        let fragmentQueryArray: [String] = {
            guard self.fragmentQueryExpression != nil else {
                return []
            }
            return ["\n\(indentation)    [\(self.fragmentQueryName)]"]
        }()
        
        let allFragments = fragmentQueryArray + self.subFragments.sorted { $0.value < $1.value }.map { "\(indentation)    \($0.value.lowercaseFirst)" }
        
        guard allFragments.count > 0 else {
            return "[]"
        }
        
        let newLine = fragmentQueryArray.count == 0 ? "\n" : ""
        
        let filtering = """
        \(indentation)]
        \(indentation).flatMap { $0 }
        \(indentation).reduce(into: [:]) { (result: inout [String: FragmentDefinition], frag) in
        \(indentation)    result[frag.name] = frag
        \(indentation)}
        \(indentation).map { $0.1 }
        """
        
        return "[" + newLine + allFragments.joined(separator: ",\n") + "\n" + filtering
    }
    
    private func generateFragmentCalls(indentation: String, outputSchemaName: String) -> String? {
        if self.subFragments.count == 0 {
            return nil
        }
        return self.subFragments
            .sorted {
                $0.value < $1.value
            }
            .map {
                "\(indentation)let \($0.value.lowercaseFirst) = \(outputSchemaName).\($0.value).fragments"
            }
            .joined(separator: "\n")
    }
}

extension OperationDefinition {
    public func generateQueryComponent(indentation: String) -> (query: String, requiredFragments: Set<FragmentName>) {
        let type = "." + self.operation.rawValue
        let name = self.name.generateQueryComponent()
        let variables = self.variableDefinitions.generateQueryComponent()
        let directive = self.directives.generateQueryComponent()
        let selectionSet = self.selectionSet.generateQueryComponent(indentation: indentation, omit__typename: self.operation == .subscription)
        return ("AutoGraphQL.Operation(type: \(type), name: \(name), variableDefinitions: \(variables), directives: \(directive), selectionSet: \(selectionSet.queryComponent))", selectionSet.requiredFragments)
    }
}

extension FragmentDefinition {
    public func generateQueryComponent(indentation: String) -> (query: String, requiredFragments: Set<FragmentName>) {
        let name = self.name.generateQueryComponent()
        let typeCondition = self.typeCondition.name.generateQueryComponent()
        let directives = self.directives.generateQueryComponent()
        let selectionSet = self.selectionSet.generateQueryComponent(indentation: indentation + "    ")
        return ("FragmentDefinition(name: \(name), type: \(typeCondition), directives: \(directives), selectionSet: \(selectionSet.queryComponent))!", selectionSet.requiredFragments)
    }
}

extension SelectionSet {
    public func generateQueryComponent(indentation: String, omit__typename: Bool = false) -> (queryComponent: String, requiredFragments: Set<FragmentName>) {
        let nextIndentation = indentation + "    "
        
        // MARK: - __typename-injection:
        
        let typeNameField = omit__typename ? nil : Field.generateScalarQueryComponent(name: "\"__typename\"", alias: "nil", arguments: nil, directives: nil)
        let components = self.selections.map { $0.generateQueryComponent(indentation: nextIndentation) }
        typealias Result = ([String], Set<FragmentName>)
        let reduced = components.reduce(([], [])) { (result, component) -> Result in
            (result.0 + [component.queryComponent], result.1.union(component.requiredFragments))
        }
        let allFields: [String] = {
            guard let typeNameField = typeNameField else {
                return reduced.0
            }
            return [typeNameField] + reduced.0
        }()
        return ("[\n" + indentation + "    " + allFields.joined(separator: ",\n" + indentation + "    ") + "\n" + indentation + "]", reduced.1)
    }
}

extension Selection {
    public func generateQueryComponent(indentation: String) -> (queryComponent: String, requiredFragments: Set<FragmentName>) {
        switch self {
        case .field(let field):
            return field.generateQueryComponent(indentation: indentation)
        case .fragmentSpread(let fragment):
            let component = fragment.generateQueryComponent()
            return (component.queryComponent, [component.requiredFragment])
        case .inlineFragment(let inlineFragment):
            return inlineFragment.generateQueryComponent(indentation: indentation)
        }
    }
}

extension InlineFragment {
    public func generateQueryComponent(indentation: String) -> (queryComponent: String, requiredFragments: Set<FragmentName>) {
        let namedType = self.typeCondition?.name.generateQueryComponent()
        let directives = self.directives.generateQueryComponent()
        let selectionSet = self.selectionSet.generateQueryComponent(indentation: indentation)
        return ("Selection.inlineFragment(namedType: \(namedType ?? "nil"), directives: \(directives), selectionSet: \(selectionSet.queryComponent))", selectionSet.requiredFragments)
    }
}

extension FragmentSpread {
    public func generateQueryComponent() -> (queryComponent: String, requiredFragment: FragmentName) {
        let name = self.name.generateQueryComponent()
        let directives = self.directives.generateQueryComponent()
        return ("Selection.fragmentSpread(name: \(name), directives: \(directives))", FragmentName(self.name.value))
    }
}

extension Field {
    public func generateQueryComponent(indentation: String) -> (queryComponent: String, requiredFragments: Set<FragmentName>) {
        if self.selectionSet != nil {
            return self.generateObjectQueryComponent(indentation: indentation)
        }
        else {
            return (self.generateScalarQueryComponent(), [])
        }
    }
    
    public func generateObjectQueryComponent(indentation: String) -> (queryComponent: String, requiredFragments: Set<FragmentName>) {
        let name = self.name.generateQueryComponent()
        let alias = self.alias.generateQueryComponent()
        let arguments = self.arguments.generateQueryComponent()
        let directives = self.directives.generateQueryComponent()
        let selectionSet = self.selectionSet!.generateQueryComponent(indentation: indentation)
        return ("Selection.field(name: \(name), alias: \(alias), arguments: \(arguments), directives: \(directives), type: .object(selectionSet: \(selectionSet.queryComponent)))", selectionSet.requiredFragments)
    }
    
    public func generateScalarQueryComponent() -> String {
        let name = self.name.generateQueryComponent()
        let alias = self.alias.generateQueryComponent()
        let arguments = self.arguments.generateQueryComponent()
        let directives = self.directives.generateQueryComponent()
        return Field.generateScalarQueryComponent(name: name, alias: alias, arguments: arguments, directives: directives)
    }
    
    public static func generateScalarQueryComponent(name: String, alias: String, arguments: String?, directives: String?) -> String {
        return "Selection.field(name: \(name), alias: \(alias), arguments: \(arguments ?? "nil"), directives: \(directives ?? "nil"), type: .scalar)"
    }
}

extension [Directive<IsConst>]? {
    public func generateQueryComponent() -> String {
        guard let directives = self else {
            return "nil"
        }
        return "[" + directives.map { $0.generateQueryComponent() }.joined(separator: ", ") + "]"
    }
}

extension [Directive<IsVariable>]? {
    public func generateQueryComponent() -> String {
        guard let directives = self else {
            return "nil"
        }
        return "[" + directives.map { $0.generateQueryComponent() }.joined(separator: ", ") + "]"
    }
}

extension Directive<IsConst> {
    public func generateQueryComponent() -> String {
        let name = self.name.generateQueryComponent()
        let arguments = self.arguments.generateQueryComponent()
        return "Directive(name: \(name), arguments: \(arguments))"
    }
}

extension Directive<IsVariable> {
    public func generateQueryComponent() -> String {
        let name = self.name.generateQueryComponent()
        let arguments = self.arguments.generateQueryComponent()
        return "Directive(name: \(name), arguments: \(arguments))"
    }
}

extension [Argument<IsConst>]? {
    public func generateQueryComponent() -> String {
        guard let arguments = self else {
            return "nil"
        }
        return arguments.generateQueryComponent()
    }
}

extension [Argument<IsVariable>]? {
    public func generateQueryComponent() -> String {
        guard let arguments = self else {
            return "nil"
        }
        return arguments.generateQueryComponent()
    }
}

extension Array where Element == Argument<IsConst> {
    public func generateQueryComponent() -> String {
        return "[" + self.map { "\"\($0.name.value)\" : \($0.value.generateQueryBuilderInputValue())" }.joined(separator: ", ") + "]"
    }
}

extension Array where Element == Argument<IsVariable> {
    public func generateQueryComponent() -> String {
        return "[" + self.map { "\"\($0.name.value)\" : \($0.value.generateQueryBuilderInputValue())" }.joined(separator: ", ") + "]"
    }
}

extension Name? {
    public func generateQueryComponent() -> String {
        guard let name = self else {
            return "\"\""
        }
        return "\"\(name.value)\""
    }
}

extension Name {
    public func generateQueryComponent() -> String {
        "\"\(self.value)\""
    }
}

extension NamedType {
    public func generateQueryComponent() -> String {
        self.name.generateQueryComponent()
    }
}

extension Optional where Wrapped == VariableDefinitions {
    public func generateQueryComponent() -> String {
        guard let variables = self?.variableDefinitions else {
            return "nil"
        }
        return "[" + variables.map { $0.generateQueryComponent() }.joined(separator: ", ") + "]"
    }
}

extension VariableDefinition {
    public func generateQueryComponent() -> String {
        let name = self.variable.name.generateQueryComponent()
        let typeName = self.type.generateInputTypeComponent()
        let defaultValue = self.defaultValue.generateQueryBuilderInputValue()
        return "try! AnyVariableDefinition(name: \(name), typeName: \(typeName), defaultValue: \(defaultValue))"
    }
}

extension `Type` {
    public func generateInputTypeComponent() -> String {
        // TODO: This is not DRY and doesn't include custom types.
        enum ScalarTypes: String {
            case int = "Int"
            case float = "Double"
            case string = "String"
            case boolean = "Boolean"
            case null = "Null"
            case id = "ID"
            
            var name: String {
                switch self {
                case .int: return "int"
                case .float: return "float"
                case .string: return "string"
                case .boolean: return "boolean"
                case .null: return "null"
                case .id: return "id"
                }
            }
        }
        
        switch self {
        case .namedType(let namedType):
            let typeName = namedType.name.value
            if let scalar = ScalarTypes(rawValue: typeName) {
                return ".scalar(.\(scalar.name))"
            }
            else {
                return ".object(typeName: \"\(typeName)\")"
            }
        case .listType(let type):
            return ".list(\(type.generateInputTypeComponent()))"
        case .nonNullType(let type):
            return ".nonNull(\(type.generateInputTypeComponent()))"
        }
    }
}

extension Optional where Wrapped == Value<IsConst> {
    public func generateQueryBuilderInputValue() -> String {
        guard let value = self else {
            return "nil"
        }
        return value.generateQueryBuilderInputValue()
    }
}

extension Optional where Wrapped == Value<IsVariable> {
    public func generateQueryBuilderInputValue() -> String {
        guard let value = self else {
            return "nil"
        }
        return value.generateQueryBuilderInputValue()
    }
}

extension Variable {
    func generateQueryComponent() -> String {
        return "Variable(name: \(self.name.generateQueryComponent()))"
    }
}

extension Value {
    public func generateQueryBuilderInputValue() -> String {
        switch self {
        case .variable(let variable, _):   return variable.generateQueryComponent()
        case .int(let int):             return int.description
        case .float(let float):         return float.description
        case .string(let string):       return "\"\(string)\""
        case .bool(let bool):           return bool ? "true" : "false"
        case .null:                     return "NSNull()"
        case .enum(let enumValue):      return "try! AnyEnumValue(caseName: \"\(enumValue.value)\")"
        case .list(let value):
            return "[" + value.map { $0.generateQueryBuilderInputValue() }.joined(separator: ", ") + "]"
        case .object(let objectValue):
            return "[" + objectValue.fields.map { "\"\($0.name.value)\" : \($0.value.generateQueryBuilderInputValue())" }.joined(separator: ", ") + "] as [String: Any]"
        }
    }
}
