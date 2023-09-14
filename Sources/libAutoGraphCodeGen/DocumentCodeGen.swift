import Foundation

protocol DocumentationGeneratable {
    var documentationMarkup: String? { get }
}

extension DocumentationGeneratable {
    /// For a doc string such as `"wow\nthis is documentation"` this will produce:
    /// `"\(indentation)/// wow\n\(indentation)/// this is documentation\n"`.
    /// Note the terminating newline.
    ///
    /// Returns empty string `""` for `nil` `documentationMarkup`; no terminating newline.
    func genDocumentationWithNewline(indentation: String) -> String {
        let documentation = self.documentationMarkup.toDocCommentOrEmpty(indentation: indentation)
        return documentation == "" ? "" : documentation + "\n"
    }
}

// TODO: This is a bit too specific. Should maybe instead operate over arrays of possible
// doc strings.
protocol Deprecatable: DocumentationGeneratable {
    var isDeprecated: Bool { get }
    var deprecationReason: String? { get }
    var description: String? { get }
}
extension Deprecatable {
    var documentationMarkup: String? {
        if !self.isDeprecated {
            return self.description
        }
        switch (self.deprecationReason, self.description) {
        case (nil, nil): return nil
        case (.some(let deprecationReason), nil): return "DEPRECATED: \(deprecationReason)"
        case (nil, let description): return description
        case (.some(let deprecationReason), .some(let description)):
            return "DEPRECATED: \(deprecationReason)\n\(description)"
        }
    }
}

extension AllTypes {
    public func generateFileNameAndImports(configuration: Configuration.SchemaConfiguration) -> (fileName: String, fileText: String) {
        let fileName = configuration.outputSchemaName + ".swift"
        let imports =
            """
            import Foundation
            import AutoGraphQL
            import JSONValueRX
            
            """
        let fileText = imports + (
            configuration.additionalImports.count > 0
            ? configuration.additionalImports.map { "import \($0)" }.joined(separator: "\n") + "\n"
            : ""
        )
        
        return (fileName, fileText)
    }
    
    public func generateFragmentsStructs(indentation: String) throws -> String? {
        guard self.fragmentIRs.count > 0 else {
            return nil
        }
        let orderedFragmentDefinitions = self.fragmentIRs.sorted { left, right in  left.key.value < right.key.value }
        let fragmentDefinitionsCode = try orderedFragmentDefinitions.map {
            try $0.value.generateCode(outputSchemaName: self.outputSchemaName, indentation: indentation)
        }
        .joined(separator: "\n\n")
        return fragmentDefinitionsCode
    }
    
    public func generateOperationsStructs(indentation: String) throws -> String {
        let orderedOperationDefinitions = self.operationIRs
            .sorted { left, right in left.key.value < right.key.value }
            .map { _, operation in operation }
        let operationDefinitionsCode = try orderedOperationDefinitions.map {
            try $0.generateCode(outputSchemaName: self.outputSchemaName, indentation: "")
        }
        .joined(separator: "\n\n")
        return operationDefinitionsCode
    }
    
    public func generateEnumDeclarations(indentation: String) -> String? {
        guard self.usedEnumTypes.count > 0 else {
            return nil
        }
        let orderedEnums = self.usedEnumTypes
            .sorted { left, right in left.key.value < right.key.value }
            .map { _, `enum` in `enum` }
        let enumCode = orderedEnums.map { $0.generateEnumDeclaration(indentation: indentation) }.joined(separator: "\n\n")
        return enumCode
    }
    
    public func generateInputObjectStructDeclarations(indentation: String) -> String? {
        guard self.usedInputObjectTypes.count > 0 else {
            return nil
        }
        let orderedInputObjects = self.usedInputObjectTypes
            .sorted { left, right in left.key.value < right.key.value }
            .map { _, inputObject in inputObject }
        let inputObjectCode = orderedInputObjects.map { $0.generateCode(indentation: indentation) }.joined(separator: "\n\n")
        return inputObjectCode
    }
}

public struct RequestProtocolGenerator {
    public var AutoGraphQLRequest: String {
        return "AutoGraphQLRequest"
    }
    
    public var protocolsCode: String {
        return """
        public protocol \(self.AutoGraphQLRequest): Request {
            associatedtype QueryDocument = Document
            
            var operation: AutoGraphQL.Operation { get }
            var fragments: [FragmentDefinition] { get }
            var data: SerializedObject? { get set }
        }
        
        public extension \(self.AutoGraphQLRequest) {
            var queryDocument: Document {
                let operation = self.operation
                let fragments = self.fragments
                return Document(operations: [operation], fragments: fragments)
            }
            
            var operationName: String {
                return self.operation.name
            }
            
            var rootKeyPath: String { return "data" }
            
            func willSend() throws { }
            func didFinishRequest(response: HTTPURLResponse?, json: JSONValue) throws { }
            func didFinish(result: AutoGraphResult<SerializedObject>) throws { }
        }
        
        public struct EnumConversionError: LocalizedError {
            let type: Any.Type
        
            init(type: Any.Type) {
                self.type = type
            }
        
            public var errorDescription: String? {
                return "Failed to convert JSON to \\(self.type)"
            }
        }
        """
    }
}
