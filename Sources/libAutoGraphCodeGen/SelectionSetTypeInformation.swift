import Foundation
import AutoGraphParser

protocol SelectionSetTypeInformation {
    var graphQLTypeName: GraphQLTypeName { get }
    var queryable__Fields: [FieldName: __Field] { get }
    /// https://spec.graphql.org/October2021/#GetPossibleTypes()
    /// GetPossibleTypes(type)
    /// If type is an object type, return a set containing type
    /// If type is an interface type, return the set of types implementing type
    /// If type is a union type, return the set of possible types of type
    var implementingTypes: Set<GraphQLTypeName> { get }
}

extension SelectionSetTypeInformation {
    /// https://spec.graphql.org/October2021/#sec-Fragment-spread-is-possible
    /// For each spread (named or inline) defined in the document.
    /// Let fragment be the target of spread
    /// Let fragmentType be the type condition of fragment
    /// Let parentType be the type of the selection set containing spread
    /// Let applicableTypes be the intersection of GetPossibleTypes(fragmentType) and GetPossibleTypes(parentType)
    /// applicableTypes must not be empty.
    public func validateFragmentSpreadIsPossible(_ typeCondition: TypeCondition, allTypes: AllTypes) throws {
        if self.applicabletypes(typeCondition, allTypes: allTypes).isEmpty {
            throw AutoGraphCodeGenError.validation(message: "Type condition \(typeCondition.name.name.value) is not an acceptable subtype of the parent selection set's type \(self.graphQLTypeName) - see https://spec.graphql.org/October2021/#sec-Fragment-spread-is-possible")
        }
    }
    
    public func applicabletypes(_ typeCondition: TypeCondition, allTypes: AllTypes) -> Set<GraphQLTypeName> {
        let parentTypes = self.implementingTypes
        let typeConditionTypes = typeCondition.implementingTypes(allTypes: allTypes)
        return parentTypes.intersection(typeConditionTypes)
    }
}

struct SelectionSetTypeInformationBuilder {
    /// Create type information for the selection set and validate that it's under an Object, Interface, or Union type.
    /// Covers: `https://spec.graphql.org/October2021/#sec-Fragments-On-Composite-Types`
    static func typeInformation(for __field: __Field, allTypes: AllTypes) throws -> any SelectionSetTypeInformation {
        func resolve(objectTypeRef: OfType.__TypeReference, allTypes: AllTypes) throws -> ObjectTypeInformation {
            let typeName = objectTypeRef.name!
            guard let objectType = allTypes.objectTypes[GraphQLTypeName(value: typeName)]
            else {
                throw AutoGraphCodeGenError.codeGeneration(message: "Attempted to use type of name \(typeName) to retrieve object, but object from this type does not exist")
            }
            return objectType
        }
        
        func resolve(interfaceTypeRef: OfType.__TypeReference, allTypes: AllTypes) throws -> InterfaceTypeInformation {
            let typeName = interfaceTypeRef.name!
            guard let interfaceType = allTypes.interfaceTypes[GraphQLTypeName(value: typeName)] else {
                throw AutoGraphCodeGenError.codeGeneration(message: "Attempted to use type of name \(typeName) to retrieve interface type, but interface from this type does not exist")
            }
            return interfaceType
        }
        
        func resolve(unionTypeRef: OfType.__TypeReference, allTypes: AllTypes) throws -> UnionTypeInformation {
            let typeName = unionTypeRef.name!
            guard let unionType = allTypes.unionTypes[GraphQLTypeName(value: typeName)] else {
                throw AutoGraphCodeGenError.codeGeneration(message: "Attempted to use type of name \(typeName) to retrieve union type, but union of this type does not exist")
            }
            return unionType
        }
        
        func resolve(fieldType: OfType) throws -> any SelectionSetTypeInformation {
            switch fieldType {
            case .object(let typeRef):          return try resolve(objectTypeRef: typeRef, allTypes: allTypes)
            case .interface(let typeRef):       return try resolve(interfaceTypeRef: typeRef, allTypes: allTypes)
            case .union(let typeRef):           return try resolve(unionTypeRef: typeRef, allTypes: allTypes)
            case .list(_, let ofType):          return try resolve(fieldType: ofType)
            case .nonNull(_, let ofType):          return try resolve(fieldType: ofType)
            case .enum(_), .scalar(_), .inputObject(_):
                throw AutoGraphCodeGenError.validation(message: "Failed to establish selection set type for \(__field.name). \(__field.name) is not of a type that contains a selection set. Must be object, interface, or union.")
            }
        }
        
        return try resolve(fieldType: __field.type)
    }
}

public struct InterfaceTypeInformation: SelectionSetTypeInformation {
    public let interfaceType: InterfaceType
    public let queryable__Fields: [FieldName: __Field]
    public let graphQLTypeName: GraphQLTypeName
    /// Names of Object types implementing this interface.
    public let possibleTypes: Set<GraphQLTypeName>
    /// Names of Interface types implementing this interface.
    public let possibleSubInterface: Set<GraphQLTypeName>
    /// Names of Interfaces this interface implements.
    public let interfaces: Set<GraphQLTypeName>
    /// Names of interfaces and objects that implement this type, including self.
    public let implementingTypes: Set<GraphQLTypeName>
    
    public init(interfaceType: InterfaceType, interfacesToSubInterfaces: [GraphQLTypeName: [InterfaceType]]) throws {
        self.interfaceType = interfaceType
        self.queryable__Fields = interfaceType.fields.__fieldsDictionary()
        self.graphQLTypeName = GraphQLTypeName(value: interfaceType.name)
        self.possibleTypes = Set(try interfaceType.possibleTypes.map {
            guard case let .object(typeRef) = $0 else {
                throw AutoGraphCodeGenError.codeGeneration(message: "Possible type \($0) on interface \(interfaceType.name) must be an Object.")
            }
            return GraphQLTypeName(value: typeRef.name!)
        })
        let possibleSubInterface = interfacesToSubInterfaces[GraphQLTypeName(value: interfaceType.name)] ?? []
        self.possibleSubInterface = Set(possibleSubInterface.map { GraphQLTypeName(value: $0.name) })
        self.interfaces = Set(try interfaceType.interfaces.map {
            guard case let .interface(typeRef) = $0 else {
                throw AutoGraphCodeGenError.codeGeneration(message: "Type \($0) from `interfaces` on \(interfaceType.name) must be an Interface.")
            }
            return GraphQLTypeName(value: typeRef.name!)
        })
        self.implementingTypes = self.possibleTypes.union(self.possibleSubInterface).union([self.graphQLTypeName])
    }
}

public struct ObjectTypeInformation: SelectionSetTypeInformation {
    public let objectType: ObjectType
    public let queryable__Fields: [FieldName: __Field]
    public let graphQLTypeName: GraphQLTypeName
    public var implementingTypes: Set<GraphQLTypeName> {
        Set([self.graphQLTypeName])
    }
    
    public init(objectType: ObjectType) {
        self.objectType = objectType
        self.queryable__Fields = objectType.fields.__fieldsDictionary()
        self.graphQLTypeName = GraphQLTypeName(value: objectType.name)
    }
}

public struct UnionTypeInformation: SelectionSetTypeInformation {
    public let unionType: UnionType
    public let queryable__Fields: [FieldName: __Field]
    public let graphQLTypeName: GraphQLTypeName
    public let possibleTypes: Set<GraphQLTypeName>
    public let possibleObjectTypes: [GraphQLTypeName: ObjectTypeInformation]
    public var implementingTypes: Set<GraphQLTypeName> {
        self.possibleTypes
    }
    
    init(unionType: UnionType, allObjectTypes: [GraphQLTypeName: ObjectTypeInformation]) throws {
        self.unionType = unionType
        self.graphQLTypeName = GraphQLTypeName(value: unionType.name)
        self.possibleObjectTypes = try unionType.possibleTypes.reduce(into: [GraphQLTypeName: ObjectTypeInformation]()) { (acc, possibleType) in
            guard case let .object(typeRef) = possibleType else {
                throw AutoGraphCodeGenError.validation(message: "Possible type \(possibleType) on union \(unionType.name) must be an Object.")
            }
            let objectTypeName = GraphQLTypeName(value: typeRef.name!)
            guard let possibleObjectType = allObjectTypes[objectTypeName] else {
                throw AutoGraphCodeGenError.validation(message: "Possible type \(possibleType) on union \(unionType.name) does not exist in the schema.")
            }
            acc[objectTypeName] = possibleObjectType
        }
        self.possibleTypes = Set(self.possibleObjectTypes.keys)
        self.queryable__Fields = self.possibleObjectTypes.values.reduce(into: [FieldName: __Field]()) { (acc, objectType) in
            acc.merge(objectType.queryable__Fields) { (current, _) in current }
        }
    }
}
