import Foundation
import AutoGraphParser

// TODO:
// https://spec.graphql.org/October2021/#sec-Fragments-Must-Be-Used
// https://spec.graphql.org/October2021/#sec-Fragment-spreads-must-not-form-cycles

struct SelectionSetIR {
    let typeInformation: SelectionSetTypeInformation
    let traversedFields: [FieldIR]
    let scalarFields: [FieldIR]
    let fragmentSpreads: [FragmentSpread]
    let objectFields: [ObjectFieldIR]
    let inlineFragments: [InlineFragmentIR]
    
    // TODO: Should formally follow `https://spec.graphql.org/October2021/#sec-Field-Selection-Merging`
    // and add an forwarded function name that is `documentFieldSelectionMerge`. Note however we generate fragments
    // separately so will slightly diverge from the spec for client requests - call that out.
    // TODO: add `consuming` when Swift 5.9 launches.
    /// Merge with another selection set and return the merged selection set.
    ///
    /// NOTE: Does not recursively merge, may end up with conflicting sets. For now, the user must
    /// remove the redundant field or fragment spread from the GraphQL query to resolve such ambiguities.
    func merged(with otherSelectionSet: SelectionSetIR) throws -> SelectionSetIR {
        let selfType = self.typeInformation.graphQLTypeName.value
        let otherType = otherSelectionSet.typeInformation.graphQLTypeName.value
        guard selfType == otherType else {
            throw AutoGraphCodeGenError.codeGeneration(message: "Attempting to merge two selection sets of different derived types: \(self)\nother: \(otherSelectionSet)")
        }
        guard self.traversedFields == otherSelectionSet.traversedFields else {
            throw AutoGraphCodeGenError.codeGeneration(message: "Attempting to merge two selection sets from different traversed field paths: \(self)\nother: \(otherSelectionSet)")
        }
        
        // TODO: We may still end up with ambiguity if there are duped scalars, objects, or
        // fragment spreads between these merged sets since we don't don't check for nested duplication.
        // This is probably good enough temporarily though because the compiler for the target language will point
        // out the discrepency and it should be obvious _enough_ to the user that they added
        // fields that are redundant.
        
        // MARK: - __typename-injection: We filter `__typename` out of one set, since it is always included.
        
        let scalarFields = self.scalarFields + otherSelectionSet.scalarFields.filter { $0.swiftVariableIdentifierName != "__typename" }
        let fragmentSpreads = self.fragmentSpreads + otherSelectionSet.fragmentSpreads
        let objectFields = self.objectFields + otherSelectionSet.objectFields
        let inlineFragments = self.inlineFragments + otherSelectionSet.inlineFragments
        
        return SelectionSetIR(
            typeInformation: self.typeInformation,
            traversedFields: self.traversedFields,
            scalarFields: scalarFields,
            fragmentSpreads: fragmentSpreads,
            objectFields: objectFields,
            inlineFragments: inlineFragments)
    }
}

struct FieldIR: Hashable, VariableDeclarationGeneratable, Deprecatable {
    let alias: Alias?
    let name: Name
    let type: OfType
    let swiftType: SwiftType
    let arguments: [Argument<IsVariable>]?
    // TODO: Better support for directives and acknowledge `isRepeatable`.
    let directives: [Directive<IsVariable>]?
    let description: String?
    let isDeprecated: Bool
    let deprecationReason: String?
    
    /// E.g. with "myAlias: someField" then "myAlias".
    /// E.g. with "someField" then "someField"
    var swiftVariableIdentifierName: String {
        self.alias?.value ?? self.name.value
    }
    
    var sortKey: some Comparable { self.swiftVariableIdentifierName }
    
    init(field: Field, __field: __Field, allTypes: AllTypes) throws {
        // TODO: Warn on `isDeprecated`.
        // TODO: Type check that `field.arguments` conforms to `__field.args` and throw when bad.
        self.alias = field.alias
        self.name = field.name
        self.type = __field.type
        self.swiftType = try self.type.reWrapToSwiftType(allTypes)
        self.arguments = field.arguments
        self.directives = field.directives
        self.description = __field.description
        self.isDeprecated = __field.isDeprecated
        self.deprecationReason = __field.deprecationReason
    }
    
    func swiftVariableTypeIdentifier(schemaName: String) -> ReWrappedSwiftType {
        self.swiftType.prefixedReWrapped ?? self.swiftType.reWrapped
    }
    
    func genDocumentation() -> String? {
        self.description
    }
}

struct ObjectFieldIR: NestedStructDeclarationGeneratable {
    let field: FieldIR
    let selectionSet: SelectionSetIR
    var fieldNameRequiresDisambiguation: Bool = false
    
    var swiftVariableIdentifierName: String { self.field.swiftVariableIdentifierName }
    var sortKey: some Comparable { self.field.sortKey }
    
    init(field: FieldIR, selectionSet: SelectionSetIR) {
        self.field = field
        self.selectionSet = selectionSet
    }
    
    func swiftStructDeclarationTypeIdentifier() throws -> ReWrappedSwiftType {
        let baseReWrappedType = self.field.swiftType.reWrapped
        if self.fieldNameRequiresDisambiguation {
            // Since we require different aliases for the same type of field just prefix the `Alias`
            // to the type name to disambiguate.
            return baseReWrappedType.withPrefixedBase(self.swiftVariableIdentifierName.uppercaseFirst)
        }
        else {
            return baseReWrappedType
        }
    }
    
    func swiftVariableTypeIdentifier(schemaName: String) throws -> ReWrappedSwiftType {
        try self.swiftStructDeclarationTypeIdentifier()
    }
}

struct InlineFragmentIR: NestedStructDeclarationGeneratable {
    let inlineFragment: InlineFragment
    let selectionSet: SelectionSetIR
    
    var sortKey: some Comparable {
        self.selectionSet.typeInformation.graphQLTypeName.value
    }
    
    // TODO: Something similar will be needed elsewhere, may wish to lift this
    // into a protocol.
    /// The actual type name in Swift in the `StructDecl`.
    /// Not meant to be used in `VariableDecl` positions, see `swiftVariableTypeIdentifier`
    /// in such cases.
    var swiftStructTypeIdentifierString: String {
        let stringifiedDirectives = self.inlineFragment.directives?.stringified ?? ""
        return "As" + self.selectionSet.typeInformation.graphQLTypeName.value + stringifiedDirectives
    }
    
    /// e.g. "asUser".
    var swiftVariableIdentifierName: String {
        self.swiftStructTypeIdentifierString.lowercaseFirst
    }
    
    /// e.g. "AsUser".
    /// Always returns `nullable` identifier because cast to `InlineFragment`s may
    /// fail for `Union` and `Interface` types.
    func swiftVariableTypeIdentifier(schemaName: String) -> ReWrappedSwiftType {
        self.swiftStructDeclarationTypeIdentifier()
    }
    
    func swiftStructDeclarationTypeIdentifier() -> ReWrappedSwiftType {
        .nullable(.val(self.swiftStructTypeIdentifierString))
    }
    
    // TODO: add `consuming` when Swift 5.9 launches.
    fileprivate func merged(with otherInlineFragment: InlineFragmentIR) throws -> InlineFragmentIR {
        return InlineFragmentIR(
            inlineFragment: self.inlineFragment,
            selectionSet: try self.selectionSet.merged(with: otherInlineFragment.selectionSet))
    }
}

extension SelectionSet {
    func lowerToIR(
        on selectionSetType: some SelectionSetTypeInformation,
        along traversedFields: [FieldIR],
        allTypes: AllTypes
    ) throws -> (ir: SelectionSetIR, liftedEnumTypes: [GraphQLTypeName: EnumType]) {
        var scalarFields = [FieldIR]()
        var fragmentSpreads = [FragmentSpread]()
        var objectFields = [ObjectFieldIR]()
        var inlineFragments = [InlineFragmentIR]()
        var liftedEnumTypes = [GraphQLTypeName: EnumType]()
        for selection in self.selections {
            switch selection {
            case .field(let field):
                switch try field.lowerToIR(onParent: selectionSetType, along: traversedFields, allTypes: allTypes) {
                case (let ir, let fieldLiftedEnumTypes):
                    switch ir {
                    case .scalar(field: let field):
                        scalarFields.append(field)
                    case .object(field: let field, selectionSet: let selectionSet):
                        objectFields.append(ObjectFieldIR(field: field, selectionSet: selectionSet))
                    }
                    liftedEnumTypes.merge(fieldLiftedEnumTypes, uniquingKeysWith: { first, _ in first })
                }
            case .fragmentSpread(let fragmentSpread):
                try fragmentSpread.validate(onParent: selectionSetType, along: traversedFields, allTypes: allTypes)
                fragmentSpreads.append(fragmentSpread)
            case .inlineFragment(let inlineFragment):
                switch try inlineFragment.lowerToIR(onParent: selectionSetType, along: traversedFields, allTypes: allTypes) {
                case (let ir, let inlineFragmentLiftedEnumTypes):
                    inlineFragments.append(ir)
                    liftedEnumTypes.merge(inlineFragmentLiftedEnumTypes, uniquingKeysWith: { first, _ in first })
                }
            }
        }
        
        // MARK: - __typename-injection:
        if !scalarFields.contains(where: { $0.name.value == "__typename" }) {
            scalarFields.append(try FieldIR(field: Field.__typename, __field: __Field.__typename, allTypes: allTypes))
        }
        
        objectFields.disambiguatedAgainstDuplicateTypes()
        return (ir: SelectionSetIR(
                        typeInformation: selectionSetType,
                        traversedFields: traversedFields,
                        scalarFields: scalarFields,
                        fragmentSpreads: fragmentSpreads,
                        objectFields: objectFields,
                        inlineFragments: try inlineFragments.mergeSameTypedInlineFragments()),
                liftedEnumTypes: liftedEnumTypes)
    }
}

extension [ObjectFieldIR] {
    // TODO: Consider `consuming` and internally mutate and then returning mutated
    // array for Swift 5.9 rather than lifting `mutating` to caller. See example `https://github.com/apple/swift-evolution/blob/main/proposals/0366-move-function.md#proposed-solution-consume-operator`
    // for internal consuming var and `https://github.com/apple/swift/blob/main/docs/OwnershipManifesto.md#for-loops`
    // for consuming iterations.
    // TODO: Once https://spec.graphql.org/October2021/#sec-Field-Selection-Merging is implemented and in
    // use, the only fields needing deduplication will be ones with different sets of arguments or directives.
    // We should fail here if the field names are the same too and force the user to provide an alias, code
    // is more clear that way anyway.
    
    /// Iterates through the array of object fields, searches for multiple field with the same type name and marks
    /// for field naming for disambiguation.
    ///
    /// E.g. `query { object { uuid val } objectWithoutUUID: object { val } }` is a legal query where `object` and `objectWithoutUUID`
    /// are of the same type in the Schema. However, since they are two separately aliased selection sets we want to code gen 2
    /// separate swift `structs` for each one. If they both have type `Type` the codegened structs will now be of types `ObjectType`
    /// and `ObjectWithoutUUIDType` respectively.
    mutating func disambiguatedAgainstDuplicateTypes() {
        var typeExistsAtIndex = [String: Int]()
        var indicesNeedingUpdate = Set<Int>()
        for (index, objectField) in self.enumerated() {
            let typeName = objectField.selectionSet.typeInformation.graphQLTypeName.value
            if let dupeAtIndex = typeExistsAtIndex[typeName] {
                // We have an object type that is used twice. Mark both as needing disambiguation.
                indicesNeedingUpdate.insert(index)
                indicesNeedingUpdate.insert(dupeAtIndex)
            }
            else {
                typeExistsAtIndex[typeName] = index
            }
        }
        // Set all needing deduplication to true.
        for index in indicesNeedingUpdate {
            self[index].fieldNameRequiresDisambiguation = true
        }
    }
}

extension [InlineFragmentIR] {
    // TODO: Add `consuming` for Swift 5.9.
    /// Iterates through the array of inline fragments.
    /// Searches for multiple inline fragments with the same type and directives and merges them.
    ///
    /// E.g. `query { object { ... on SubType { uuid } ... on SubType { aField } } }`
    /// roughly becomes `query { object { ... on SubType { uuid aField } } }` so only 1 struct
    /// is codegen'd for an inline fragment of the same type.
    func mergeSameTypedInlineFragments() throws -> [InlineFragmentIR] {
        var dict = [String: InlineFragmentIR]()
        for inlineFragment in self {
            let typeName = inlineFragment.selectionSet.typeInformation.graphQLTypeName.value
            let directives = inlineFragment.inlineFragment.directives?.stringified ?? ""
            let key = typeName + directives
            if dict[key] != nil {
                // We have a inline fragment type that is used twice. Merge.
                let dupe = dict.removeValue(forKey: key)!
                dict[key] = try dupe.merged(with: inlineFragment)
            }
            else {
                dict[key] = inlineFragment
            }
        }
        return dict.map { $0.value }
    }
}

/// These are the various dependencies that have different semantics depending on the type of a field.
/// scalar -> code gen scalar property.
/// object -> code gen struct property *and* the internal struct def
enum FieldDependency {
    case scalar(field: FieldIR)
    case object(field: FieldIR, selectionSet: SelectionSetIR)
}

// TODO: More directly conform to validations https://spec.graphql.org/October2021/#sec-Validation.Fields
extension Field {
    public static let __typename = Field(name: "__typename")
    
    func lowerToIR(
        onParent parentSelectionSetType: some SelectionSetTypeInformation,
        along traversedFields: [FieldIR],
        allTypes: AllTypes
    ) throws -> (ir: FieldDependency, liftedEnumTypes: [GraphQLTypeName: EnumType])
    {
        let fieldName = FieldName(self.name.value)
        guard
            let __field = parentSelectionSetType.queryable__Fields[fieldName]
                ?? (try? __Field(introspectionField: self))
        else {
            throw AutoGraphCodeGenError.validation(message: "Field \(fieldName) is not a field on \(parentSelectionSetType.graphQLTypeName.value)")
        }
        
        let fieldIR = try FieldIR(field: self, __field: __field, allTypes: allTypes)
        let finalFields = traversedFields + [fieldIR]
        
        if let enumType = try __field.type.enumFieldType(allTypes) {
            return (ir: .scalar(field: fieldIR), liftedEnumTypes: [GraphQLTypeName(value: enumType.name) : enumType])
        }
        
        switch self.selectionSet {
        case .none: return (ir: .scalar(field: fieldIR), liftedEnumTypes: [:])
        case .some(let subSelectionSet):
            let typeInfo = try SelectionSetTypeInformationBuilder.typeInformation(for: __field, allTypes: allTypes)
            let selectionSetIR = try subSelectionSet.lowerToIR(on: typeInfo, along: finalFields, allTypes: allTypes)
            return (ir: .object(field: fieldIR, selectionSet: selectionSetIR.ir), liftedEnumTypes: selectionSetIR.liftedEnumTypes)
        }
    }
}

extension __Field {
    public static let __typename = __Field(
        name: "__typename",
        args: [],
        type: OfType.nonNull(
            OfType.__TypeReference(kind: __TypeKind.nonNull),
            ofType: OfType.scalar(OfType.__TypeReference(
                kind: __TypeKind.scalar,
                name: ScalarType.NameType.string.rawValue
            ))),
        isDeprecated: false
    )
    
    public init(introspectionField: Field) throws {
        let name = introspectionField.name.value
        guard name == __Field.__typename.name else {
            throw AutoGraphCodeGenError.codeGeneration(message: "Field \(name) is not an introspection field")
        }
        self = __Field.__typename
    }
}

extension FragmentSpread {
    /// https://spec.graphql.org/October2021/#sec-Validation.Fragments
    func validate(
        onParent parentSelectionSetType: some SelectionSetTypeInformation,
        along traversedFields: [FieldIR],
        allTypes: AllTypes
    ) throws {
        /// https://spec.graphql.org/October2021/#sec-Fragment-spread-target-defined
        guard let definition = allTypes.fragments[self.name] else {
            throw AutoGraphCodeGenError.validation(message: "Fragment Definition does not exist for fragment spread named \(self.name.value) - see `https://spec.graphql.org/October2021/#sec-Fragment-spread-target-defined`")
        }
        
        /// https://spec.graphql.org/October2021/#sec-Fragment-spread-is-possible
        let baseError = "Fragment spread \(self.name.value) referencing Fragment Definition \(definition.name.value) validation failed - "
        do {
            try parentSelectionSetType.validateFragmentSpreadIsPossible(definition.typeCondition, allTypes: allTypes)
        }
        catch AutoGraphCodeGenError.validation(message: let message) {
            throw AutoGraphCodeGenError.validation(message: baseError + message)
        }
        catch let err {
            throw AutoGraphCodeGenError.validation(message: "\(baseError) \(err)")
        }
    }
}

extension InlineFragment {
    /// https://spec.graphql.org/October2021/#sec-Validation.Fragments
    func lowerToIR(
        onParent parentSelectionSetType: some SelectionSetTypeInformation,
        along traversedFields: [FieldIR],
        allTypes: AllTypes
    ) throws -> (
        ir: InlineFragmentIR,
        liftedEnumTypes: [GraphQLTypeName: EnumType])
    {
        /// https://spec.graphql.org/October2021/#sec-Fragment-spread-is-possible
        if let typeCondition = self.typeCondition {
            try parentSelectionSetType.validateFragmentSpreadIsPossible(typeCondition, allTypes: allTypes)
        }
        
        let typeInformation = try {
            if let typeCondition = self.typeCondition {
                let baseError = "Inline fragment validation failed with type condition \(typeCondition) - "
                /// https://spec.graphql.org/October2021/#sec-Fragment-spread-is-possible
                do {
                    try parentSelectionSetType.validateFragmentSpreadIsPossible(typeCondition, allTypes: allTypes)
                }
                catch let err {
                    throw AutoGraphCodeGenError.validation(message: "\(baseError) \(err)")
                }
                guard let typeConditionTypeInformation = typeCondition.typeInformation(allTypes: allTypes) else {
                    throw AutoGraphCodeGenError.codeGeneration(message: "\(baseError) no type information for `typeCondition`  \(typeCondition)")
                }
                return typeConditionTypeInformation
            }
            else {
                return parentSelectionSetType
            }
        }()
        
        let selectionSetIR = try self.selectionSet.lowerToIR(on: typeInformation, along: traversedFields, allTypes: allTypes)
        return (ir: InlineFragmentIR(inlineFragment: self, selectionSet: selectionSetIR.ir),
                liftedEnumTypes: selectionSetIR.liftedEnumTypes)
    }
}

extension OfType {
    public func enumFieldType(_ allTypes: AllTypes) throws -> EnumType? {
        switch self {
        case .enum(let typeRef):
            let typeName = typeRef.name!
            let gqlTypeName = GraphQLTypeName(value: typeName)
            
            guard let enumType = allTypes.enumTypes[gqlTypeName] else {
                throw AutoGraphCodeGenError.codeGeneration(message: "Attempted to use type of name \(typeName) to retrieve enum, but enum from this type does not exist")
            }
            return enumType
        case .list(_, ofType: let ofType):
            return try ofType.enumFieldType(allTypes)
        case .nonNull(_, ofType: let ofType):
            return try ofType.enumFieldType(allTypes)
        default:
            return nil
        }
    }
}

extension TypeCondition {
    // Could possibly memoize.
    /// https://spec.graphql.org/October2021/#GetPossibleTypes()
    func implementingTypes(allTypes: AllTypes) -> Set<GraphQLTypeName> {
        let typeName = GraphQLTypeName(name: self.name.name)
        if let object = allTypes.objectTypes[typeName] {
            return object.implementingTypes
        }
        else if let interface = allTypes.interfaceTypes[typeName] {
            return interface.implementingTypes
        }
        else if let union = allTypes.unionTypes[typeName] {
            return union.implementingTypes
        }
        else {
            return Set()
        }
    }
    
    func typeInformation(allTypes: AllTypes) -> (any SelectionSetTypeInformation)? {
        let typeName = GraphQLTypeName(name: self.name.name)
        return allTypes.objectTypes[typeName]
            ?? allTypes.interfaceTypes[typeName]
            ?? allTypes.unionTypes[typeName]
    }
}
