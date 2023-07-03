import Foundation
import AutoGraphParser

// TODO: May wish to lift these into newtypes.
public typealias FieldName = String
public typealias FragmentName = Name
public typealias OperationName = Name

public struct GraphQLTypeName: Hashable, CustomStringConvertible {
    public let value: String
    public var description: String { return self.value }
    
    public init(value: String) {
        self.value = value
    }
    
    public init(name: Name) {
        self.value = name.value
    }
}

public struct SwiftType: Hashable {
    let base: String
    let reWrapped: ReWrappedSwiftType
    let prefixedReWrapped: ReWrappedSwiftType?
    
    fileprivate func reWrapList() -> SwiftType {
        let prefixed: ReWrappedSwiftType? = {
            guard let prefixed = self.prefixedReWrapped else {
                return nil
            }
            return .nullable(.list(prefixed))
        }()
        return SwiftType(base: self.base,
                         reWrapped: .nullable(.list(self.reWrapped)),
                         prefixedReWrapped: prefixed)
    }
    
    fileprivate func reWrapNullable() -> SwiftType {
        // Since we know we should be non-null, omit nullable.
        guard case .nullable(let internalType) = self.reWrapped else {
            fatalError("Algorithm for rewrapping nullable types failed. GQL should not support null types of null types.")
        }
        let prefixed: ReWrappedSwiftType? = {
            guard let prefixed = self.prefixedReWrapped else {
                return nil
            }
            // Since we know we should be non-null, omit nullable.
            guard case .nullable(let internalType) = prefixed else {
                fatalError("Algorithm for rewrapping nullable types failed. GQL should not support null types of null types.")
            }
            return internalType
        }()
        return SwiftType(base: self.base,
                         reWrapped: internalType,
                         prefixedReWrapped: prefixed)
    }
}

/// Represents a type that has been iterated and all instances of _not_ explicit non-null have been wrapped as
/// nullable and all explicit non-nulls have been changed to base values.
/// This better matches how swift syntactically differentiates nullability.
public indirect enum ReWrappedSwiftType: Hashable {
    case val(String)
    case nullable(ReWrappedSwiftType)
    case list(ReWrappedSwiftType)
}

extension ReWrappedSwiftType {
    public func genSwiftBaseTypeName() -> String {
        switch self {
        case .val(let type):
            return type
        case .nullable(let type):
            return type.genSwiftBaseTypeName()
        case .list(let type):
            return type.genSwiftBaseTypeName()
        }
    }
    
    public func genSwiftType() -> String {
        switch self {
        case .val(let type):
            return type
        case .nullable(let type):
            return type.genSwiftType() + "?"
        case .list(let type):
            return "[" + type.genSwiftType() + "]"
        }
    }
    
    public func genSwiftDefaultInitializer() -> String {
        switch self {
        case .val(let type):    return "\(type)()"
        case .nullable:         return "nil"
        case .list:             return "[]"
        }
    }
    
    public func withPrefixedBase(_ prefix: String) -> ReWrappedSwiftType {
        switch self {
        case .val(let type):        return .val(prefix + type)
        case .nullable(let type):   return .nullable(type.withPrefixedBase(prefix))
        case .list(let type):       return .list(type.withPrefixedBase(prefix))
        }
    }
}

// TODO: should we rewrap when iterating Fields etc.?
extension `Type` {
    func baseTypeName() -> GraphQLTypeName {
        switch self {
        case .namedType(let namedType): return GraphQLTypeName(name: namedType.name)
        case .listType(let type):       return type.baseTypeName()
        case .nonNullType(let type):    return type.baseTypeName()
        }
    }
    
    func reWrapToSwiftType(_ allTypes: AllTypes) -> SwiftType {
        switch self {
        case .namedType(let namedType):
            // Either it's a scalar...
            if let builtinScalar = ScalarType.NameType.BuiltIn(rawValue: namedType.name.value) {
                let swiftScalar = SwiftScalarType(nameType: ScalarType.NameType(builtIn: builtinScalar))
                let base = swiftScalar.swiftVariableTypeIdentifier
                let reWrapped = ReWrappedSwiftType.nullable(.val(base))
                return SwiftType(base: base, reWrapped: reWrapped, prefixedReWrapped: nil)
            }
            // or a custom scalar...
            else if
                // This actually never returns `nil` because defaults to custom types
                // so check it explicitly.
                let possibleScalar = ScalarType.NameType(rawValue: namedType.name.value),
                allTypes.customScalarTypes[possibleScalar] != nil
            {
                let swiftScalar = SwiftScalarType(nameType: possibleScalar)
                let base = swiftScalar.swiftVariableTypeIdentifier
                let reWrapped = ReWrappedSwiftType.nullable(.val(base))
                return SwiftType(base: base, reWrapped: reWrapped, prefixedReWrapped: reWrapped.withPrefixedBase("\(allTypes.outputSchemaName)."))
            }
            // or an object.
            else {
                let base = namedType.name.value
                return SwiftType(base: base, reWrapped: .nullable(.val(base)), prefixedReWrapped: nil)
            }
        case .listType(let type):
            let inner = type.reWrapToSwiftType(allTypes)
            return inner.reWrapList()
        case .nonNullType(let type):
            let inner = type.reWrapToSwiftType(allTypes)
            return inner.reWrapNullable()
        }
    }
}

extension OfType {
    func baseTypeName() -> GraphQLTypeName {
        // `name` is only `nil` for non-null and list types which
        // should be validated ahead of time.
        switch self {
        case .scalar(let ref):      return GraphQLTypeName(value: ref.name!)
        case .object(let ref):      return GraphQLTypeName(value: ref.name!)
        case .interface(let ref):   return GraphQLTypeName(value: ref.name!)
        case .union(let ref):       return GraphQLTypeName(value: ref.name!)
        case .enum(let ref):        return GraphQLTypeName(value: ref.name!)
        case .inputObject(let ref): return GraphQLTypeName(value: ref.name!)
        case .list(_, ofType: let ofType):      return ofType.baseTypeName()
        case .nonNull(_, ofType: let ofType):   return ofType.baseTypeName()
        }
    }
    
    func reWrapToSwiftType(_ allTypes: AllTypes) throws -> SwiftType {
        switch self {
        case .scalar(let typeRef):
            precondition(typeRef.kind == .scalar, "never fails")
            let name = typeRef.name!
            if let builtinScalar = ScalarType.NameType.BuiltIn(rawValue: name) {
                let swiftScalar = SwiftScalarType(nameType: ScalarType.NameType(builtIn: builtinScalar))
                let base = swiftScalar.swiftVariableTypeIdentifier
                let reWrapped = ReWrappedSwiftType.nullable(.val(base))
                return SwiftType(base: base, reWrapped: reWrapped, prefixedReWrapped: nil)
            }
            else if
                // This actually never returns `nil` because defaults to custom types
                // so check it explicitly.
                let possibleScalar = ScalarType.NameType(rawValue: name),
                allTypes.customScalarTypes[possibleScalar] != nil
            {
                let swiftScalar = SwiftScalarType(nameType: possibleScalar)
                let base = swiftScalar.swiftVariableTypeIdentifier
                let reWrapped = ReWrappedSwiftType.nullable(.val(base))
                return SwiftType(base: base, reWrapped: reWrapped, prefixedReWrapped: reWrapped.withPrefixedBase("\(allTypes.outputSchemaName)."))
            }
            
            throw AutoGraphCodeGenError.codeGeneration(message: "Attempting to construct scalar swift type with non-scalar gql type")
        case
            .object(let typeRef),
            .interface(let typeRef),
            .union(let typeRef),
            .enum(let typeRef),
            .inputObject(let typeRef):
                let base = typeRef.name!
                return SwiftType(base: base, reWrapped: .nullable(.val(base)), prefixedReWrapped: nil)
        case .list(_, ofType: let ofType):
            return try ofType.reWrapToSwiftType(allTypes).reWrapList()
        case .nonNull(_, ofType: let ofType):
            return try ofType.reWrapToSwiftType(allTypes).reWrapNullable()
        }
    }
}

public struct SwiftScalarType: Hashable {
    public let nameType: ScalarType.NameType
    public var swiftVariableTypeIdentifier: String {
        switch self.nameType {
        case .int:      return "Int"
        case .float:    return "Double"
        case .string:   return "String"
        case .bool:     return "Bool"
        // TODO: Should maybe have a more robust `ID` type.
        case .id:       return "String"
        case .custom(let custom): return custom
        }
    }
    
    public init(nameType: ScalarType.NameType) {
        self.nameType = nameType
    }
        
    public init(scalarType: OfType.__TypeReference) throws {
        guard scalarType.kind == .scalar, let type = ScalarType.NameType(rawValue: scalarType.name!) else {
            throw AutoGraphCodeGenError.codeGeneration(message: "Attempting to construct scalar swift type with non-scalar gql type")
        }
        self.init(nameType: type)
    }
    
    public init?(namedType: NamedType) {
        guard let gqlScalar = ScalarType.NameType(rawValue: namedType.name.value) else {
            return nil
        }
        self.init(nameType: gqlScalar)
    }
}

extension Collection where Element == Directive<IsConst> {
    public var stringified: String {
        return self.map { $0.stringified.uppercaseFirst }.joined(separator: "")
    }
}

extension Collection where Element == Directive<IsVariable> {
    public var stringified: String {
        return self.map { $0.stringified.uppercaseFirst }.joined(separator: "")
    }
}

extension Directive {
    public var stringified: String {
        return self.name.value + (self.arguments?
            .map {
                $0.stringified.uppercaseFirst
            }
            .joined(separator: "")
            .lowercaseFirst ?? "")
    }
}

extension Argument {
    public var stringified: String {
        return self.name.value + self.value.stringified.uppercaseFirst
    }
}

extension Value {
    public var stringified: String {
        switch self {
        case .variable(let variable, _):    return variable.name.value
        case .int(let val):                 return String(val)
        case .float(let val):               return String(val)
        case .string(let val):              return val
        case .bool(let val):                return String(val)
        case .null:                         return "null"
        case .enum(let val):                return val.value
        case .list(let list):   return list.map { $0.stringified.uppercaseFirst }.joined(separator: "").lowercaseFirst
        case .object(let obj):  return obj.fields.map { $0.stringified.uppercaseFirst }.joined(separator: "").lowercaseFirst
        }
    }
}

extension ObjectField {
    public var stringified: String {
        return self.name.value + self.value.stringified.uppercaseFirst
    }
}

extension ScalarType.NameType {
    // TODO: Add this into AutoGraphParser lib.
    public init(builtIn: ScalarType.NameType.BuiltIn) {
        switch builtIn {
        case .int:      self = .int
        case .float:    self = .float
        case .string:   self = .string
        case .bool:     self = .bool
        case .id:       self = .id
        }
    }
}
