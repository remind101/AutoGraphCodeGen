import Foundation
import AutoGraphParser

extension FragmentDefinitionIR {
    public func structDeclarationStart(indentation: String) -> String {
        return "\(indentation)public struct \(self.fragment.name.value): Codable {"
    }
    
    public func initializer(indentation: String) throws -> String {
        let params = try self.selectionSet.genInitializerDeclarationParameterList(parentFieldBaseTypeName: nil)
        let propertyAssignments = self.selectionSet.genInitializerCodeBlockAssignmentExpressions(indentation: "\(indentation)    ")
        let decodableAssignments = try self.selectionSet.decodableCodeBlockAssignmentExpressions(indentation: "\(indentation)    ", parentFieldBaseTypeName: nil)
        
        return """
        \(indentation)public init(\(params)) {
        \(propertyAssignments)
        \(indentation)}
        
        \(indentation)public init(from decoder: Decoder) throws {
        \(decodableAssignments)
        \(indentation)}
        """
    }
    
    public func generateCode(outputSchemaName: String, indentation: String) throws -> String {
        let nextIndentation = indentation + "    "
        let typeDefinition = self.structDeclarationStart(indentation: indentation)
        let initializer = try self.initializer(indentation: nextIndentation)
        let scalarPropertyDefinitions = try self.selectionSet.genScalarPropertyVariableDeclarations(indentation: nextIndentation)
        let fragmentSpreadPropertyDefinitions = try self.selectionSet.genFragmentSpreadPropertyVariableDeclarations(indentation: nextIndentation)
        let (objectSubStructPropertyDefinitions, objectSubStructDefinitions) =
        try self.selectionSet.genObjectNestedStructDeclarations(indentation: nextIndentation)
        let (inlineFragmentSubStructPropertyDefinitions, inlineFragmentSubStructDefinitions) =
        try self.selectionSet.inlineFragmentSubStructDefinitions(indentation: nextIndentation)
        let codingKeys = try self.generateCodingKeys(indentation: nextIndentation)
        let queryCode = try self.generateQueryCode(fragmentDefinition: self.fragment, outputSchemaName: outputSchemaName, indentation: nextIndentation)
        
        let selectionSetCode = [
            scalarPropertyDefinitions,
            objectSubStructPropertyDefinitions,
            fragmentSpreadPropertyDefinitions,
            inlineFragmentSubStructPropertyDefinitions,
        ].compactMap { $0 == "" ? nil : $0 }.joined(separator: "\n\n")
        
        let structCode = [
            objectSubStructDefinitions,
            inlineFragmentSubStructDefinitions,
        ].compactMap { $0 == "" ? nil : $0 }.joined(separator: "\n\n")
        
        return """
        \(typeDefinition)
        \(initializer)
        
        \(codingKeys)
        
        \(selectionSetCode)
        
        \(queryCode)
        \(structCode)
        \(indentation)}
        
        """
    }
    
    public func generateQueryCode(fragmentDefinition: FragmentDefinition, outputSchemaName: String, indentation: String) throws -> String {
        let queryComponents = fragmentDefinition.generateQueryComponent(indentation: indentation)
        let fragmentGenerator = FragmentQueryGenerator(fragmentQueryExpression: queryComponents.query,
                                                  subFragments: queryComponents.requiredFragments)
        
        let fragmentsQueryCode = fragmentGenerator.generateFragmentsQuery(
            withTypeName: self.fragment.name.value,
            outputSchemaName: outputSchemaName,
            indentation: indentation)
        
        return """
        \(fragmentsQueryCode)
        
        """
    }
    
    public func generateCodingKeys(indentation: String) throws -> String {
        let nextIndentation = "\(indentation)    "
        let codingKeys = try self.selectionSet.codingKeyEnumDeclarations(indentation: nextIndentation)
        
        return """
        \(indentation)enum CodingKeys: String, CodingKey {
        \(codingKeys)
        \(indentation)}
        """
    }
}
