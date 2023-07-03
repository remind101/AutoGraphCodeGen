import Foundation

private let kInputsDictionaryName = "inputsDict"

extension InputObjectTypeIR: DocumentationGeneratable {
    /// For
    /// ```
    /// input MyInput {
    ///    uuid: String!
    ///    count: Int! = 0
    ///    subInput: SubInput
    /// }
    ///
    /// input SubInput {
    ///     uuid: String!
    ///     names: [String] = "blank"
    /// }
    /// ```
    /// generates
    /// ```
    /// public struct SubInput: Encodable, VariableInputParameterEncodable {
    ///     public let uuid: String
    ///     public let name: String?
    ///
    ///     public init(uuid: String, name: OptionalInputValue<String> = .value("blank")) {
    ///         self.uuid = uuid
    ///     }
    ///
    ///     public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
    ///         var inputsDict = [AnyHashable : any VariableInputParameterEncodable]()
    ///         inputsDict["uuid"] = self.uuid.encodedAsVariableInputParameter
    ///         return inputsDict
    ///     }
    /// }
    ///
    /// public struct MyInput: Encodable, VariableInputParameterEncodable {
    ///     public let uuid: String
    ///     public let count: Int
    ///     public let subInput: OptionalInputValue<SubInput>
    ///
    ///     public init(uuid: String, count: Int = 0, subInput: OptionalInputValue<SubInput> = .ignored) {
    ///         self.uuid = uuid
    ///         self.count = count
    ///         self.subInput = subInput
    ///     }
    ///
    ///     public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
    ///         var inputsDict = [AnyHashable : any VariableInputParameterEncodable]()
    ///         inputsDict["uuid"] = self.uuid.encodedAsVariableInputParameter
    ///         inputsDict["count"] = self.count.encodedAsVariableInputParameter
    ///         self.subInput.encodeAsVariableInputParameter(into: &inputsDict, with: "subInput")
    ///         return inputsDict
    ///     }
    /// }
    func generateCode() -> String {
        let indentation = "    "
        let nextIndentation = indentation + "    "
        let args = self.inputFields.map { $0.genInitializerDeclarationParameterList() }.joined(separator: ", ")
        let propertyAssignments = self.inputFields.map { $0.genInitializerCodeBlockAssignmentExpression() }.joined(separator: "\n\(nextIndentation)")
        let dictionaryAssignments = self.inputFields.map { $0.genDictionaryAssignmentExpression() }.joined(separator: "\n\(nextIndentation)")
        let propertyDeclarations = self.inputFields.map { $0.propertyDeclaration() }.joined(separator: "\n\(indentation)")
        let documentation = self.genDocumentationWithNewline(indentation: indentation)
        
        return documentation + """
        public struct \(self.graphQLTypeName.value): Encodable, VariableInputParameterEncodable {
            \(propertyDeclarations)
        
            public init(\(args)) {
                \(propertyAssignments)
            }
        
            public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
                var \(kInputsDictionaryName) = [AnyHashable : any VariableInputParameterEncodable]()
                \(dictionaryAssignments)
                return \(kInputsDictionaryName)
            }
        }
        """
    }
    
    var documentationMarkup: String? {
        self.inputObjectType.description ?? self.graphQLTypeName.value
    }
}

extension InputValueIR {
    // TODO: Include defaultValue's
    /// `FunctionParameterList`.
    /// E.g.
    /// `uuid: String` or `value: OptionalInputValue<Input>`
    func genInitializerDeclarationParameterList() -> String {
        let type = self.type.prefixedReWrapped ?? self.type.reWrapped
        return "\(self.inputValue.name): \(type.genInputVariableTypeIdentifier())"
    }
    
    /// Generates the property setting code in the initializer which contains arguments.
    ///
    /// E.g.
    /// ```
    /// self.uuid = uuid
    /// self.input = input
    /// ```
    func genInitializerCodeBlockAssignmentExpression() -> String {
        return "self.\(self.inputValue.name) = \(self.inputValue.name)"
    }
    
    // TODO: If scalar don't need to encode.
    /// If it's not-null then just encode. If nullable then the value may be ignored so we have to check for that.
    ///
    /// E.g.
    /// ```
    /// variablesDict["uuid"] = self.uuid
    /// ```
    func genDictionaryAssignmentExpression() -> String {
        let key = "\"\(self.inputValue.name)\""
        switch self.type.prefixedReWrapped ?? self.type.reWrapped {
        case .val, .list: return "\(kInputsDictionaryName)[\(key)] = self.\(self.inputValue.name).encodedAsVariableInputParameter"
        case .nullable: return "self.\(self.inputValue.name).encodeAsVariableInputParameter(into: &\(kInputsDictionaryName), with: \(key))"
        }
    }
    
    /// E.g.
    ///
    /// ```
    /// public let uuid: String
    /// public let input: OptionalInputValue<Input>
    /// ```
    func propertyDeclaration() -> String {
        let type = self.type.prefixedReWrapped ?? self.type.reWrapped
        return "public let \(self.inputValue.name): \(type.genInputVariableTypeIdentifier())"
    }
}
