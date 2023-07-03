import Foundation
import AutoGraphParser

typealias OperationDefinitionDependencies = (
    liftedEnumTypes: [GraphQLTypeName: EnumType],
    liftedInputObjectTypes: [GraphQLTypeName: InputObjectTypeIR]
)

// TODO: Confirm we're doing all validations
// `https://spec.graphql.org/October2021/#sec-Validation.Operations`

struct OperationDefinitionIR {
    let operation: OperationDefinition
    let name: Name
    let variableDefinitions: [VariableDefinitionIR]?
    // TODO: directives
    let directives: [Directive<IsVariable>]?
    let selectionSet: SelectionSetIR
    
    var typeNameSuffix: String {
        switch self.operation.operation {
        case .query:        return "Query"
        case .mutation:     return "Mutation"
        case .subscription: return "Subscription"
        }
    }
}

extension OperationDefinition {
    func lowerToIR(allTypes: AllTypes) throws -> (ir: OperationDefinitionIR, liftedDependencies: OperationDefinitionDependencies) {
        guard let name = self.name else {
            throw AutoGraphCodeGenError.validation(message: "Anonymous queries are unsupported. Every `OperationDefinition` must have a `Name`, please at a name to the query: \(self)")
        }
        guard
            let operationObjectTypeName: String = {
                switch self.operation {
                case .query:        return allTypes.queryType
                case .mutation:     return allTypes.mutationType
                case .subscription: return allTypes.subscriptionType
                }
            }(),
            let objectTypeInformation = allTypes.objectTypes[GraphQLTypeName(value: operationObjectTypeName)]
        else {
            throw AutoGraphCodeGenError.validation(message: "OperationDefinition \(name.value) is of type \(self.operation.rawValue) but Schema does not contain that type")
        }
        
        let selectionSet = try self.selectionSet.lowerToIR(on: objectTypeInformation, along: [], allTypes: allTypes)
        let variableData = try self.variableDefinitions?.variableDefinitions.lowerToIR(allTypes: allTypes)
        let variableDefinitions = variableData?.variableDefinitions
        let variableDependencies = variableData?.variableDefinitionDependencies
        
        var operationDependencies = (
            liftedEnumTypes: [GraphQLTypeName: EnumType](),
            liftedInputObjectTypes: [GraphQLTypeName: InputObjectTypeIR]()
        )
        
        // Pattern matching for completionists.
        let selectionSetIR = {
            switch selectionSet {
            case (let ir, let liftedEnumTypes):
                operationDependencies.liftedEnumTypes.merge(liftedEnumTypes, uniquingKeysWith: { first, _ in first })
                return ir
            }
        }()
        
        if let variableDependencies = variableDependencies {
            switch variableDependencies {
            case (let liftedEnumTypes, let liftedInputObjectTypes):
                operationDependencies.liftedEnumTypes.merge(liftedEnumTypes, uniquingKeysWith: { first, _ in first })
                operationDependencies.liftedInputObjectTypes.merge(liftedInputObjectTypes, uniquingKeysWith: { first, _ in first })
            }
        }
        
        let operationDefinitionIR = OperationDefinitionIR(
            operation: self,
            name: name,
            variableDefinitions: variableDefinitions,
            directives: self.directives,
            selectionSet: selectionSetIR)
        
        return (operationDefinitionIR, operationDependencies)
    }
}
