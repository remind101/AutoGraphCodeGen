import Foundation
import AutoGraphParser

/*
 Usage - Starting from VariableDefinition we call `lowerToIR` to get it's IR and dependencies.
 We match those dependencies against possible scalar, enum, and input object types from the
 schema. If the type dependency matches an Enum or InputObject we know we must code gen that
 type as well. In the Enum case we simply lift the type dependency to later code gen. In the
 InputObject case we may have additional dependencies to lift out of that type, so we similarly
 call `resolved` on it to lift dependencies recursively.
 */

struct VariableDefinitionIR {
    let variableDefinition: VariableDefinition
    let type: SwiftType
    /// Strips away List and Nullable types.
    let baseType: GraphQLTypeName
    
    init(variableDefinition: VariableDefinition, allTypes: AllTypes) {
        self.variableDefinition = variableDefinition
        self.type = variableDefinition.type.reWrapToSwiftType(allTypes)
        self.baseType = variableDefinition.type.baseTypeName()
    }
    
    var escapedVariableName: String {
        return self.variableDefinition.variable.name.value.escapedFromReservedKeywords
    }
    
    var dollarSignVariableName: String {
        return "_$" + self.variableDefinition.variable.name.value
    }
}

typealias VariableDefinitionDependencies = (
    liftedEnumTypes: [GraphQLTypeName: EnumType],
    liftedInputObjectTypes: [GraphQLTypeName: InputObjectTypeIR]
)

extension Collection where Element == VariableDefinition {
    func lowerToIR(allTypes: AllTypes) throws -> (
        variableDefinitions: [VariableDefinitionIR],
        variableDefinitionDependencies: VariableDefinitionDependencies
    ) {
        let variableDefinitionIR = self.map { VariableDefinitionIR(variableDefinition: $0, allTypes: allTypes) }
        
        var dependencies = (
            liftedEnumTypes: [GraphQLTypeName: EnumType](),
            liftedInputObjectTypes: [GraphQLTypeName: InputObjectTypeIR]()
        )
        
        // Lift out dependencies of the base type.
        for (baseType, variable) in variableDefinitionIR.map({ ($0.baseType, $0.variableDefinition.variable) }) {
            // The type of a VariableDefinition is either Enum, InputObjectType, or a Scalar.
            if let usedEnumType = allTypes.enumTypes[baseType] {
                dependencies.liftedEnumTypes[GraphQLTypeName(value: usedEnumType.name)] = usedEnumType
            }
            else if let inputObjectType = allTypes.inputObjectTypes[baseType] {
                try inputObjectType.lowerToIR(for: variable, insertingInto: &dependencies, allTypes: allTypes)
            }
            else if ScalarType.NameType(rawValue: baseType.value) == nil {
                throw AutoGraphCodeGenError.codeGeneration(message: "Type \(baseType) of VariableDefinition \(variable) could not be resolved - could not find it in the schema.")
            }
        }
        
        return (variableDefinitionIR, dependencies)
    }
}

extension InputObjectType {
    /// We iterate all input fields, get the fields type. If the type is an enum lift it
    /// so it's code generated. If it's an input object, lift it to, but also recurse into
    /// it to extract more dependencies recursively. If we hit an input object we've already
    /// seen end recursion.
    ///
    /// Returns:
    /// The IR of this input object, this must be independently added to the set of dependencies.
    func lowerToIR(for variableDefinitionName: Variable, insertingInto irDependencies: inout VariableDefinitionDependencies, allTypes: AllTypes) throws
    {
        let inputFields = try self.inputFields.map { try InputValueIR(inputValue: $0, allTypes: allTypes) }
        let inputObjectIR = InputObjectTypeIR(inputObjectType: self, inputFields: inputFields)
        irDependencies.liftedInputObjectTypes[inputObjectIR.graphQLTypeName] = inputObjectIR
        
        let inputTypeDependencies: [InputTypeDependency] = try self.inputFields.compactMap { inputField in
            guard let dependency = try inputField.type.extractInputTypeDependency() else {
                // If it's a scalar then we don't care.
                return nil
            }
            return dependency
        }
        
        for dependency in inputTypeDependencies {
            switch dependency {
            case .usedEnumType(let enumName):
                guard let enumType = allTypes.enumTypes[enumName] else {
                    throw AutoGraphCodeGenError.validation(message: "Type \(enumName) of an input value associated with VariableDefinition \(variableDefinitionName) could not be resolved as an enum type.")
                }
                irDependencies.liftedEnumTypes[enumName] = enumType
            case .usedInputObjectType(let inputObjectName):
                guard let inputObjectType = allTypes.inputObjectTypes[inputObjectName] else {
                    throw AutoGraphCodeGenError.codeGeneration(message: "Type \(inputObjectName) of an input value associated with VariableDefinition \(variableDefinitionName) could not be resolved as an input object type - could not find it in the schema.")
                }
                guard irDependencies.liftedInputObjectTypes[inputObjectName] == nil else {
                    // Prevents infinite recursion from recursive input object types.
                    continue
                }
                try inputObjectType.lowerToIR(for: variableDefinitionName, insertingInto: &irDependencies, allTypes: allTypes)
            }
        }
    }
}

struct InputObjectTypeIR {
    let graphQLTypeName: GraphQLTypeName
    let inputObjectType: InputObjectType
    let inputFields: [InputValueIR]
    
    init(inputObjectType: InputObjectType, inputFields: [InputValueIR]) {
        self.graphQLTypeName = GraphQLTypeName(value: inputObjectType.name)
        self.inputObjectType = inputObjectType
        self.inputFields = inputFields
    }
}

struct InputValueIR: Equatable {
    let inputValue: __InputValue
    let type: SwiftType
    
    init(inputValue: __InputValue, allTypes: AllTypes) throws {
        self.inputValue = inputValue
        self.type = try inputValue.type.reWrapToSwiftType(allTypes)
    }
}

enum InputTypeDependency: Equatable {
    case usedEnumType(GraphQLTypeName)
    case usedInputObjectType(GraphQLTypeName)
}

extension OfType {
    func extractInputTypeDependency() throws -> InputTypeDependency? {
        switch self {
        case .scalar:                           return nil
        case .enum(let typeRef):                return .usedEnumType(GraphQLTypeName(value: typeRef.name!))
        case .inputObject(let typeRef):         return .usedInputObjectType(GraphQLTypeName(value: typeRef.name!))
        case .list(_, ofType: let ofType):      return try ofType.extractInputTypeDependency()
        case .nonNull(_, ofType: let ofType):   return try ofType.extractInputTypeDependency()
        case .object, .interface, .union:
            throw AutoGraphCodeGenError.codeGeneration(message: "InputType should not have a type of \(self)")
        }
    }
}
