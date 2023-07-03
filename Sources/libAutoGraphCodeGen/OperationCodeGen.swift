import Foundation
import AutoGraphParser
import SwiftSyntax

extension OperationDefinitionIR {
    public func generateCode(outputSchemaName: String, indentation: String) throws -> String {
        let typeDefinition = self.structDeclarationStart(indentation: indentation)
        let nextIndentation = indentation + "    "
        let nextNextIndentation = nextIndentation + "    "
        let initializerAndInputVariableProperties = try self.genInitializerAndInputVariablePropertyDeclarations(indentation: nextIndentation)
        let scalarPropertyDefinitions = try self.selectionSet.genScalarPropertyVariableDeclarations(indentation: nextNextIndentation, omit__typename: true)
        let fragmentSpreadPropertyDefinitions = try self.selectionSet.genFragmentSpreadPropertyVariableDeclarations(indentation: nextNextIndentation)
        let (objectSubStructPropertyDefinitions, objectSubStructDefinitions) =
        try self.selectionSet.genObjectNestedStructDeclarations(indentation: nextIndentation)
        let (inlineFragmentSubStructPropertyDefinitions, inlineFragmentSubStructDefinitions) =
        try self.selectionSet.inlineFragmentSubStructDefinitions(indentation: nextIndentation)
        let queryCode = try self.generateQueryCode(outputSchemaName: outputSchemaName, indentation: nextIndentation)
        
        let selectionSetCode = [
            scalarPropertyDefinitions,
            // TODO: needs additional indentation. inject into `genObjectNestedStructDeclarations`.
            objectSubStructPropertyDefinitions,
            fragmentSpreadPropertyDefinitions,
            // TODO: needs additional indentation 😡.
            inlineFragmentSubStructPropertyDefinitions,
        ].compactMap { $0 == "" ? nil : $0 }.joined(separator: "\n\n")
        
        let structCode = [
            objectSubStructDefinitions,
            inlineFragmentSubStructDefinitions,
        ].compactMap { $0 == "" ? nil : $0 }.joined(separator: "\n\n")
        
        let dataInitializer = try self.dataStructInitializerDeclaration(indentation: nextNextIndentation)
        
        return """
        \(typeDefinition)
        
        \(nextIndentation)public typealias SerializedObject = Data
        
        \(initializerAndInputVariableProperties)
        
        \(nextIndentation)public var data: Data?
        \(nextIndentation)public struct Data: Codable {
        \(selectionSetCode)
        
        \(dataInitializer)
        \(nextIndentation)}
        
        \(queryCode)
        \(structCode)
        \(indentation)}
        
        """
    }
    
    public var typeName: String {
        self.name.value.uppercaseFirst + self.typeNameSuffix
    }
    
    public func structDeclarationStart(indentation: String) -> String {
        "\(indentation)public struct \(self.typeName): AutoGraphQLRequest {"
    }
    
    public func genInitializerAndInputVariablePropertyDeclarations(indentation: String) throws -> String {
        guard let variableDefinitions = self.variableDefinitions, variableDefinitions.count > 0 else {
            return """
            \(indentation)public init() { }
            
            \(indentation)public var variables: [AnyHashable : Any]? { return nil }
            """
        }
        return variableDefinitions.genOperationInitializerAndInputVariablePropertyDeclarations(indentation: indentation)
    }
    
    /// `InitializerDecl`.
    public func dataStructInitializerDeclaration(indentation: String) throws -> String {
        let params = try self.selectionSet.genInitializerDeclarationParameterList(parentFieldBaseTypeName: nil, omit__typename: true)
        let propertyAssignments = self.selectionSet.genInitializerCodeBlockAssignmentExpressions(indentation: "\(indentation)    ", omit__typename: true)
        
        return """
        \(indentation)public init(\(params)) {
        \(propertyAssignments)
        \(indentation)}
        """
    }
    
    public func generateQueryCode(outputSchemaName: String, indentation: String) throws -> String {
        let queryComponent = self.operation.generateQueryComponent(indentation: indentation + "    ")
        let fragmentsAndKeys = try self.generateFragmentsAndKeys(
            requiredFragments: queryComponent.requiredFragments,
            outputSchemaName: outputSchemaName,
            indentation: indentation)
        let query = """
        \(indentation)public var operation: AutoGraphQL.Operation {
        \(indentation)    return \(queryComponent.query)
        \(indentation)}
        
        
        """
        
        return query + fragmentsAndKeys
    }
    
    func generateFragmentsAndKeys(requiredFragments: Set<FragmentName>, outputSchemaName: String, indentation: String) throws -> String {
        let fragmentGenerator = FragmentQueryGenerator(fragmentQueryExpression: nil,
                                                  subFragments: requiredFragments)
        
        let fragmentsDeclaration = fragmentGenerator.generateFragmentsQuery(
            withTypeName: self.typeName,
            outputSchemaName: outputSchemaName,
            indentation: indentation)
        
        return """
        \(fragmentsDeclaration)
        
        """
    }
}
