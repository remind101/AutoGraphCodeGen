import Foundation
import AutoGraphParser
import SwiftSyntax

private let kVariablesDictionaryName = "variablesDict"

extension Collection where Element == VariableDefinitionIR {
    func genOperationInitializerAndInputVariablePropertyDeclarations(indentation: String) -> String {
        guard self.count > 0 else {
            return """
            \(indentation)public var variables: [AnyHashable : Any]? { return nil }
            """
        }
        
        let nextIndentation = indentation + "    "
        let args = self.map { $0.genInitializerDeclarationParameterList() }.joined(separator: ", ")
        let propertyAssignments = self.map { $0.genInitializerCodeBlockAssignmentExpression() }.joined(separator: "\n\(nextIndentation)")
        let dictionaryAssignments = self.map { $0.genDictionaryAssignmentExpression() }.joined(separator: "\n\(nextIndentation)")
        let propertyDeclarations = self.map { $0.genVariableDeclaration() }.joined(separator: "\n\(indentation)")
        
        return """
        \(indentation)\(propertyDeclarations)
        
        \(indentation)public init(\(args)) {
        \(indentation)    \(propertyAssignments)
        \(indentation)}
        
        \(indentation)public var variables: [AnyHashable : Any]? {
        \(indentation)    var \(kVariablesDictionaryName) = [AnyHashable : any VariableInputParameterEncodable]()
        \(indentation)    \(dictionaryAssignments)
        \(indentation)    return \(kVariablesDictionaryName)
        \(indentation)}
        """
    }
}

extension VariableDefinitionIR {
    // TODO: Include defaultValue's
    /// `FunctionParameterList`.
    /// E.g.
    /// `uuid: String` or `value: OptionalInputValue<Input>`
    func genInitializerDeclarationParameterList() -> String {
        let type = self.type.prefixedReWrapped ?? self.type.reWrapped
        return "\(self.escapedVariableName): \(type.genInputVariableTypeIdentifier())"
    }
    
    /// Gens the property setting code in the initializer which contains arguments.
    ///
    /// E.g.
    /// ```
    /// self.uuid = uuid
    /// self.input = input
    /// ```
    func genInitializerCodeBlockAssignmentExpression() -> String {
        return "self.\(self.dollarSignVariableName) = \(self.escapedVariableName)"
    }
    
    /// Places variables into the `variables` dictionary that's passed along with the request.
    /// Variables must be `Encodable`.
    ///
    /// E.g.
    /// ```
    /// variablesDict["uuid"] = self.uuid
    ///
    /// ```
    func genDictionaryAssignmentExpression() -> String {
        // Intentionally not escaped because this is a key into a dictionary for
        // the GQL request's variables payload.
        let key = "\"\(self.variableDefinition.variable.name.value)\""
        // TODO: This is really all we want but requires moving to Encodable first.
        // return "\(kVariablesDictionaryName)[\(key)] = \(self.dollarSignVariableName)"
        
        switch self.type.prefixedReWrapped ?? self.type.reWrapped {
        case .val, .list: return "\(kVariablesDictionaryName)[\(key)] = \(self.dollarSignVariableName).encodedAsVariableInputParameter"
        case .nullable: return "\(self.dollarSignVariableName).encodeAsVariableInputParameter(into: &\(kVariablesDictionaryName), with: \(key))"
        }
    }
    
    // TODO: An input argument and a selection set field may have the same name,
    // for this reason we should split the selection set into it's own construct called Data on every Operation
    // so we don't have an ambiguous name conflict in such cases.
    //
    /// E.g.
    ///
    /// ```
    /// public let uuid: String
    /// public let input: OptionalInputValue<Input>
    /// ```
    func genVariableDeclaration() -> String {
        let type = self.type.prefixedReWrapped ?? self.type.reWrapped
        return "public let \(self.dollarSignVariableName): \(type.genInputVariableTypeIdentifier())"
    }
}

extension ReWrappedSwiftType {
    /// **.val** - it's nonNull and we can use the type directly.
    ///
    /// **.nullable** - it must use OptionalInputValue<T> { case val(T), null, ignored } if first iteration,
    /// but if wrapped in another type (namely list since GraphQL does not support `??`) use Optional<T>.
    ///
    /// **.list** - it's an array type, [Type]
    func genInputVariableTypeIdentifier() -> String {
        return self.genInputVariableTypeIdentifier(iteration: 0)
    }
    
    private func genInputVariableTypeIdentifier(iteration: Int) -> String {
        switch self {
        case .val(let val):
            return val
        case .nullable(let type):
            if iteration == 0 {
                return "\(OptionalInputValueGenerator.TypeName)<\(type.genInputVariableTypeIdentifier(iteration: iteration + 1))>"
            }
            else {
                return type.genInputVariableTypeIdentifier(iteration: iteration + 1) + "?"
            }
        case .list(let type):
            return "[" + type.genInputVariableTypeIdentifier(iteration: iteration + 1) + "]"
        }
    }
}
