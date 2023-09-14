import Foundation
import AutoGraphParser

//* include traversed fields for inline fragment of same type selection set merging, must have the same traversed fields to merge. see `mergedAgainstSameTypes`

/// Contains lookup tables to all types in the schema. This must be constructed before query code gen
/// resolution because queries and their components must looking and validate their types.
public class AllTypes {
    public static let GraphQLSchemaNameDefault = "GraphQLSchema"

    public let outputSchemaName: String
    public let queryType: String
    public let mutationType: String?
    public let subscriptionType: String?
    
    public let customScalarTypes: [ScalarType.NameType: ScalarType]
    public let objectTypes: [GraphQLTypeName: ObjectTypeInformation]
    public let interfaceTypes: [GraphQLTypeName: InterfaceTypeInformation]
    public let unionTypes: [GraphQLTypeName: UnionTypeInformation]
    public let enumTypes: [GraphQLTypeName: EnumType]
    public let inputObjectTypes: [GraphQLTypeName: InputObjectType]
    
    public private(set) var fragments = [FragmentName: FragmentDefinition]()
    public private(set) var operations = [OperationName: OperationDefinition]()
    
    private(set) var operationIRs = [OperationName: OperationDefinitionIR]()
    private(set) var fragmentIRs = [FragmentName: FragmentDefinitionIR]()
    private(set) var usedEnumTypes = [GraphQLTypeName: EnumType]()
    private(set) var usedInputObjectTypes = [GraphQLTypeName: InputObjectTypeIR]()
        
    public init(
        outputSchemaName: String,
        queryType: String,
        mutationType: String?,
        subscriptionType: String?,
        customScalarTypes: [ScalarType.NameType: ScalarType] = [:],
        objectTypes: [GraphQLTypeName: ObjectTypeInformation] = [:],
        interfaceTypes: [GraphQLTypeName: InterfaceTypeInformation] = [:],
        unionTypes: [GraphQLTypeName: UnionTypeInformation] = [:],
        enumTypes: [GraphQLTypeName: EnumType] = [:],
        inputObjectTypes: [GraphQLTypeName: InputObjectType] = [:]
    ) {
        self.outputSchemaName = outputSchemaName
        self.queryType = queryType
        self.mutationType = mutationType
        self.subscriptionType = subscriptionType
        self.customScalarTypes = customScalarTypes
        self.objectTypes = objectTypes
        self.interfaceTypes = interfaceTypes
        self.unionTypes = unionTypes
        self.enumTypes = enumTypes
        self.inputObjectTypes = inputObjectTypes
    }
    
    public init(schema: __Schema, outputSchemaName: String) throws {
        self.outputSchemaName = outputSchemaName
        
        let queryType = schema.queryType.name
        let mutationType = schema.mutationType?.name
        let subscriptionType = schema.subscriptionType?.name
        var initialData = (
            customScalarTypes: [ScalarType.NameType: ScalarType](),
            objectTypes: [GraphQLTypeName: ObjectTypeInformation](),
            interfaceTypes: [InterfaceType](),
            unionTypes: [UnionType](),
            enumTypes: [GraphQLTypeName: EnumType](),
            inputObjectTypes: [GraphQLTypeName: InputObjectType]()
        )
        initialData = try schema.types.reduce(into: initialData) { allTypesTemp, type in
            switch type.kind {
            case .scalar:
                // Cannot create new builtin SCALAR types.
                let scalar = try ScalarType(type: type)
                if case .custom = scalar.name {
                    allTypesTemp.customScalarTypes[scalar.name] = scalar
                }
            case .object:
                let objectType = try ObjectType(type: type)
                allTypesTemp.objectTypes[GraphQLTypeName(value: objectType.name)] = ObjectTypeInformation(objectType: objectType)
            case .interface:
                let interface = try InterfaceType(type: type)
                if interface.possibleTypes.count == 0 {
                    print("WARNING: Interface detected with 0 possible types: \(interface.name) description: \(interface.description ?? "")")
                }
                allTypesTemp.interfaceTypes.append(interface)
            case .union:
                let union = try UnionType(type: type)
                if union.possibleTypes.count == 0 {
                    print("WARNING: Union detected with 0 possible types: \(union)")
                }
                allTypesTemp.unionTypes.append(union)
            case .enum:
                let `enum` = try EnumType(type: type)
                allTypesTemp.enumTypes[GraphQLTypeName(value: `enum`.name)] = `enum`
            case .inputObject:
                let inputType = try InputObjectType(type: type)
                allTypesTemp.inputObjectTypes[GraphQLTypeName(value: inputType.name)] = inputType
            case .list:
                fatalError("Shouldn't have a top level LIST.")
            case .nonNull:
                fatalError("Shouldn't have a top level NON_NULL.")
            }
        }
        
        let interfacesToSubInterfaces = try initialData.interfaceTypes.reduce(into: [GraphQLTypeName: [InterfaceType]]()) { (interfacesToSubInterfaces, subInterfaceType) in
            for superInterface in subInterfaceType.interfaces {
                guard case let .interface(typeRef) = superInterface else {
                    throw AutoGraphCodeGenError.codeGeneration(message: "Type \(superInterface) from must be an Interface.")
                }
                interfacesToSubInterfaces[GraphQLTypeName(value: typeRef.name!), default: []].append(subInterfaceType)
            }
        }
        
        self.queryType = queryType
        self.mutationType = mutationType
        self.subscriptionType = subscriptionType
        self.customScalarTypes = initialData.customScalarTypes
        self.objectTypes = initialData.objectTypes
        self.interfaceTypes = try initialData.interfaceTypes.reduce(into: [GraphQLTypeName: InterfaceTypeInformation]()) { (interfaceTypes, interfaceType) in
            let typeInfo = try InterfaceTypeInformation(interfaceType: interfaceType, interfacesToSubInterfaces: interfacesToSubInterfaces)
            interfaceTypes[typeInfo.graphQLTypeName] = typeInfo
        }
        self.unionTypes = try initialData.unionTypes.reduce(into: [GraphQLTypeName: UnionTypeInformation]()) { (unionTypes, unionType) in
            let typeInfo = try UnionTypeInformation(unionType: unionType, allObjectTypes: initialData.objectTypes)
            unionTypes[typeInfo.graphQLTypeName] = typeInfo
        }
        self.enumTypes = initialData.enumTypes
        self.inputObjectTypes = initialData.inputObjectTypes
    }
    
    // TODO: break this off into `AllDefinitions`.
    public func loadExecutableDefinitions(configuration: Configuration.SchemaConfiguration, fileManager: FileManager) throws {
        // Not sure why it's requiring this availability considering we're
        // forcing a higher version of MacOS.
        guard #available(macOS 13.0, *) else {
            throw AutoGraphCodeGenError.configuration(message: "Must be on MacOS 13 or higher.")
        }
        
        let documentsURL = URL(filePath: configuration.gqlDocumentsPath)
        guard let enumerator = fileManager.enumerator(
            at: documentsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles])
        else {
            throw AutoGraphCodeGenError.configuration(message: "Failed to enumerate over documents at path: \(configuration.gqlDocumentsPath)")
        }
        
        var fragments = [FragmentName : FragmentDefinition]()
        var operations = [OperationName : OperationDefinition]()
        
        // Don't rebuild the parser in a loop.
        let documentParser = ExecutableDocument.parser
        
        for case let documentUrl as URL in enumerator {
            guard documentUrl.pathExtension == "graphql" else {
                continue
            }
            
            let documentText = try String(contentsOf: documentUrl)
            let executableDocument: ExecutableDocument
            do {
                executableDocument = try documentParser.parse(documentText)
            }
            catch let err {
                let documentText = {
                    guard documentText.count < 100 else {
                        return String(documentText.prefix(5000) + " <redacted...>")
                    }
                    return documentText
                }()
                throw AutoGraphCodeGenError.parsing(message: "Failed to parse document: \(documentText)", underlying: err)
            }
            
            try executableDocument.executableDefinitions.forEach { definition in
                switch definition {
                case .operationDefinition(let operation):
                    guard let operationName = operation.name else {
                        throw AutoGraphCodeGenError.validation(message: "All OperationDefinitions (\"query NAME(ARGS) {\") must have a NAME: \(operation). Anonymous operations are not supported.")
                    }
                    
                    guard operations[operationName] == nil else {
                        throw AutoGraphCodeGenError.validation(message: "Cannot have multiple operations with the same name - \(operationName)")
                    }
                    operations[operationName] = operation
                case .fragmentDefinition(let fragmentDefinition):
                    let name = fragmentDefinition.name
                    /// https://spec.graphql.org/October2021/#sec-Fragment-Name-Uniqueness
                    guard fragments[name] == nil else {
                        throw AutoGraphCodeGenError.validation(message: "Cannot have multiple fragments with the same name - \(name)")
                    }
                    
                    fragments[name] = fragmentDefinition
                }
            }
        }
        
        self.operations = operations
        self.fragments = fragments
        
        // Need to pull out all of the enum types and input object types used in the definitions so we
        // know to code generate only the ones that are necessary.
        let loweredOperations = try self.operations.map { try $0.value.lowerToIR(allTypes: self) }
        loweredOperations.map(\.ir).forEach {
            self.operationIRs[$0.name] = $0
        }
        loweredOperations.map(\.liftedDependencies).forEach {
            switch $0 {
            case (let liftedEnumTypes, let liftedInputObjectTypes):
                self.usedEnumTypes.merge(liftedEnumTypes, uniquingKeysWith: { first, _ in first })
                self.usedInputObjectTypes.merge(liftedInputObjectTypes, uniquingKeysWith: { first, _ in first })
            }
        }
        
        // TODO: https://spec.graphql.org/October2021/#sec-Fragment-Declarations
        let loweredFragments = try fragments.map { _, fragment in
            try fragment.lowerToIR(allTypes: self)
        }
        loweredFragments.map(\.ir).forEach {
            self.fragmentIRs[$0.fragment.name] = $0
        }
        loweredFragments.map(\.liftedEnumTypes).forEach {
            self.usedEnumTypes.merge($0, uniquingKeysWith: { first, _ in first })
        }
    }
}
