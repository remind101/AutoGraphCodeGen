import Foundation
import AutoGraphQL
import JSONValueRX

public enum SpaceXGQLSchema {
    /// select columns of table "users"
    public enum users_select_column: RawRepresentable, Codable, Hashable, EnumVariableInputParameterEncodable, EnumValueProtocol {
        public typealias RawValue = String

        case column
        case name
        case id
        case rocket
        case timestamp
        case twitter
        case __unknown(RawValue)

        public init() {
            self = .__unknown("")
        }

        public init?(rawValue: String) {
            switch rawValue {
            case "column":
                self = .column
            case "name":
                self = .name
            case "id":
                self = .id
            case "rocket":
                self = .rocket
            case "timestamp":
                self = .timestamp
            case "twitter":
                self = .twitter
            default:
                self = .__unknown(rawValue)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            self = users_select_column(rawValue: value) ?? .__unknown(value)
        }

        public var rawValue: String {
            switch self {
            case .column:
                return "column"
            case .name:
                return "name"
            case .id:
                return "id"
            case .rocket:
                return "rocket"
            case .timestamp:
                return "timestamp"
            case .twitter:
                return "twitter"
            case .__unknown(let val):
                return val
            }
        }

        public func graphQLInputValue() throws -> String {
            return self.rawValue
        }
    }

    /// expression to compare columns of type String. All fields are combined with logical 'AND'.
    public struct String_comparison_exp: Encodable, VariableInputParameterEncodable {
        public let _eq: OptionalInputValue<String>
        public let _gt: OptionalInputValue<String>
        public let _gte: OptionalInputValue<String>
        public let _ilike: OptionalInputValue<String>
        public let _in: OptionalInputValue<[String]>
        public let _is_null: OptionalInputValue<Bool>
        public let _like: OptionalInputValue<String>
        public let _lt: OptionalInputValue<String>
        public let _lte: OptionalInputValue<String>
        public let _neq: OptionalInputValue<String>
        public let _nilike: OptionalInputValue<String>
        public let _nin: OptionalInputValue<[String]>
        public let _nlike: OptionalInputValue<String>
        public let _nsimilar: OptionalInputValue<String>
        public let _similar: OptionalInputValue<String>

        public init(_eq: OptionalInputValue<String>, _gt: OptionalInputValue<String>, _gte: OptionalInputValue<String>, _ilike: OptionalInputValue<String>, _in: OptionalInputValue<[String]>, _is_null: OptionalInputValue<Bool>, _like: OptionalInputValue<String>, _lt: OptionalInputValue<String>, _lte: OptionalInputValue<String>, _neq: OptionalInputValue<String>, _nilike: OptionalInputValue<String>, _nin: OptionalInputValue<[String]>, _nlike: OptionalInputValue<String>, _nsimilar: OptionalInputValue<String>, _similar: OptionalInputValue<String>) {
            self._eq = _eq
            self._gt = _gt
            self._gte = _gte
            self._ilike = _ilike
            self._in = _in
            self._is_null = _is_null
            self._like = _like
            self._lt = _lt
            self._lte = _lte
            self._neq = _neq
            self._nilike = _nilike
            self._nin = _nin
            self._nlike = _nlike
            self._nsimilar = _nsimilar
            self._similar = _similar
        }

        public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
            var inputsDict = [AnyHashable : any VariableInputParameterEncodable]()
            self._eq.encodeAsVariableInputParameter(into: &inputsDict, with: "_eq")
            self._gt.encodeAsVariableInputParameter(into: &inputsDict, with: "_gt")
            self._gte.encodeAsVariableInputParameter(into: &inputsDict, with: "_gte")
            self._ilike.encodeAsVariableInputParameter(into: &inputsDict, with: "_ilike")
            self._in.encodeAsVariableInputParameter(into: &inputsDict, with: "_in")
            self._is_null.encodeAsVariableInputParameter(into: &inputsDict, with: "_is_null")
            self._like.encodeAsVariableInputParameter(into: &inputsDict, with: "_like")
            self._lt.encodeAsVariableInputParameter(into: &inputsDict, with: "_lt")
            self._lte.encodeAsVariableInputParameter(into: &inputsDict, with: "_lte")
            self._neq.encodeAsVariableInputParameter(into: &inputsDict, with: "_neq")
            self._nilike.encodeAsVariableInputParameter(into: &inputsDict, with: "_nilike")
            self._nin.encodeAsVariableInputParameter(into: &inputsDict, with: "_nin")
            self._nlike.encodeAsVariableInputParameter(into: &inputsDict, with: "_nlike")
            self._nsimilar.encodeAsVariableInputParameter(into: &inputsDict, with: "_nsimilar")
            self._similar.encodeAsVariableInputParameter(into: &inputsDict, with: "_similar")
            return inputsDict
        }
    }

    /// expression to compare columns of type timestamptz. All fields are combined with logical 'AND'.
    public struct timestamptz_comparison_exp: Encodable, VariableInputParameterEncodable {
        public let _eq: OptionalInputValue<SpaceXGQLSchema.timestamptz>
        public let _gt: OptionalInputValue<SpaceXGQLSchema.timestamptz>
        public let _gte: OptionalInputValue<SpaceXGQLSchema.timestamptz>
        public let _in: OptionalInputValue<[SpaceXGQLSchema.timestamptz]>
        public let _is_null: OptionalInputValue<Bool>
        public let _lt: OptionalInputValue<SpaceXGQLSchema.timestamptz>
        public let _lte: OptionalInputValue<SpaceXGQLSchema.timestamptz>
        public let _neq: OptionalInputValue<SpaceXGQLSchema.timestamptz>
        public let _nin: OptionalInputValue<[SpaceXGQLSchema.timestamptz]>

        public init(_eq: OptionalInputValue<SpaceXGQLSchema.timestamptz>, _gt: OptionalInputValue<SpaceXGQLSchema.timestamptz>, _gte: OptionalInputValue<SpaceXGQLSchema.timestamptz>, _in: OptionalInputValue<[SpaceXGQLSchema.timestamptz]>, _is_null: OptionalInputValue<Bool>, _lt: OptionalInputValue<SpaceXGQLSchema.timestamptz>, _lte: OptionalInputValue<SpaceXGQLSchema.timestamptz>, _neq: OptionalInputValue<SpaceXGQLSchema.timestamptz>, _nin: OptionalInputValue<[SpaceXGQLSchema.timestamptz]>) {
            self._eq = _eq
            self._gt = _gt
            self._gte = _gte
            self._in = _in
            self._is_null = _is_null
            self._lt = _lt
            self._lte = _lte
            self._neq = _neq
            self._nin = _nin
        }

        public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
            var inputsDict = [AnyHashable : any VariableInputParameterEncodable]()
            self._eq.encodeAsVariableInputParameter(into: &inputsDict, with: "_eq")
            self._gt.encodeAsVariableInputParameter(into: &inputsDict, with: "_gt")
            self._gte.encodeAsVariableInputParameter(into: &inputsDict, with: "_gte")
            self._in.encodeAsVariableInputParameter(into: &inputsDict, with: "_in")
            self._is_null.encodeAsVariableInputParameter(into: &inputsDict, with: "_is_null")
            self._lt.encodeAsVariableInputParameter(into: &inputsDict, with: "_lt")
            self._lte.encodeAsVariableInputParameter(into: &inputsDict, with: "_lte")
            self._neq.encodeAsVariableInputParameter(into: &inputsDict, with: "_neq")
            self._nin.encodeAsVariableInputParameter(into: &inputsDict, with: "_nin")
            return inputsDict
        }
    }

    /// Boolean expression to filter rows from the table "users". All fields are combined with a logical 'AND'.
    public struct users_bool_exp: Encodable, VariableInputParameterEncodable {
        public let _and: OptionalInputValue<[SpaceXGQLSchema.users_bool_exp?]>
        public let _not: OptionalInputValue<SpaceXGQLSchema.users_bool_exp>
        public let _or: OptionalInputValue<[SpaceXGQLSchema.users_bool_exp?]>
        public let id: OptionalInputValue<SpaceXGQLSchema.uuid_comparison_exp>
        public let name: OptionalInputValue<SpaceXGQLSchema.String_comparison_exp>
        public let rocket: OptionalInputValue<SpaceXGQLSchema.String_comparison_exp>
        public let timestamp: OptionalInputValue<SpaceXGQLSchema.timestamptz_comparison_exp>
        public let twitter: OptionalInputValue<SpaceXGQLSchema.String_comparison_exp>

        public init(_and: OptionalInputValue<[SpaceXGQLSchema.users_bool_exp?]>, _not: OptionalInputValue<SpaceXGQLSchema.users_bool_exp>, _or: OptionalInputValue<[SpaceXGQLSchema.users_bool_exp?]>, id: OptionalInputValue<SpaceXGQLSchema.uuid_comparison_exp>, name: OptionalInputValue<SpaceXGQLSchema.String_comparison_exp>, rocket: OptionalInputValue<SpaceXGQLSchema.String_comparison_exp>, timestamp: OptionalInputValue<SpaceXGQLSchema.timestamptz_comparison_exp>, twitter: OptionalInputValue<SpaceXGQLSchema.String_comparison_exp>) {
            self._and = _and
            self._not = _not
            self._or = _or
            self.id = id
            self.name = name
            self.rocket = rocket
            self.timestamp = timestamp
            self.twitter = twitter
        }

        public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
            var inputsDict = [AnyHashable : any VariableInputParameterEncodable]()
            self._and.encodeAsVariableInputParameter(into: &inputsDict, with: "_and")
            self._not.encodeAsVariableInputParameter(into: &inputsDict, with: "_not")
            self._or.encodeAsVariableInputParameter(into: &inputsDict, with: "_or")
            self.id.encodeAsVariableInputParameter(into: &inputsDict, with: "id")
            self.name.encodeAsVariableInputParameter(into: &inputsDict, with: "name")
            self.rocket.encodeAsVariableInputParameter(into: &inputsDict, with: "rocket")
            self.timestamp.encodeAsVariableInputParameter(into: &inputsDict, with: "timestamp")
            self.twitter.encodeAsVariableInputParameter(into: &inputsDict, with: "twitter")
            return inputsDict
        }
    }

    /// input type for updating data in table "users"
    public struct users_set_input: Encodable, VariableInputParameterEncodable {
        public let id: OptionalInputValue<SpaceXGQLSchema.uuid>
        public let name: OptionalInputValue<String>
        public let rocket: OptionalInputValue<String>
        public let timestamp: OptionalInputValue<SpaceXGQLSchema.timestamptz>
        public let twitter: OptionalInputValue<String>

        public init(id: OptionalInputValue<SpaceXGQLSchema.uuid>, name: OptionalInputValue<String>, rocket: OptionalInputValue<String>, timestamp: OptionalInputValue<SpaceXGQLSchema.timestamptz>, twitter: OptionalInputValue<String>) {
            self.id = id
            self.name = name
            self.rocket = rocket
            self.timestamp = timestamp
            self.twitter = twitter
        }

        public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
            var inputsDict = [AnyHashable : any VariableInputParameterEncodable]()
            self.id.encodeAsVariableInputParameter(into: &inputsDict, with: "id")
            self.name.encodeAsVariableInputParameter(into: &inputsDict, with: "name")
            self.rocket.encodeAsVariableInputParameter(into: &inputsDict, with: "rocket")
            self.timestamp.encodeAsVariableInputParameter(into: &inputsDict, with: "timestamp")
            self.twitter.encodeAsVariableInputParameter(into: &inputsDict, with: "twitter")
            return inputsDict
        }
    }

    /// expression to compare columns of type uuid. All fields are combined with logical 'AND'.
    public struct uuid_comparison_exp: Encodable, VariableInputParameterEncodable {
        public let _eq: OptionalInputValue<SpaceXGQLSchema.uuid>
        public let _gt: OptionalInputValue<SpaceXGQLSchema.uuid>
        public let _gte: OptionalInputValue<SpaceXGQLSchema.uuid>
        public let _in: OptionalInputValue<[SpaceXGQLSchema.uuid]>
        public let _is_null: OptionalInputValue<Bool>
        public let _lt: OptionalInputValue<SpaceXGQLSchema.uuid>
        public let _lte: OptionalInputValue<SpaceXGQLSchema.uuid>
        public let _neq: OptionalInputValue<SpaceXGQLSchema.uuid>
        public let _nin: OptionalInputValue<[SpaceXGQLSchema.uuid]>

        public init(_eq: OptionalInputValue<SpaceXGQLSchema.uuid>, _gt: OptionalInputValue<SpaceXGQLSchema.uuid>, _gte: OptionalInputValue<SpaceXGQLSchema.uuid>, _in: OptionalInputValue<[SpaceXGQLSchema.uuid]>, _is_null: OptionalInputValue<Bool>, _lt: OptionalInputValue<SpaceXGQLSchema.uuid>, _lte: OptionalInputValue<SpaceXGQLSchema.uuid>, _neq: OptionalInputValue<SpaceXGQLSchema.uuid>, _nin: OptionalInputValue<[SpaceXGQLSchema.uuid]>) {
            self._eq = _eq
            self._gt = _gt
            self._gte = _gte
            self._in = _in
            self._is_null = _is_null
            self._lt = _lt
            self._lte = _lte
            self._neq = _neq
            self._nin = _nin
        }

        public var encodedAsVariableInputParameter: any VariableInputParameterEncodable {
            var inputsDict = [AnyHashable : any VariableInputParameterEncodable]()
            self._eq.encodeAsVariableInputParameter(into: &inputsDict, with: "_eq")
            self._gt.encodeAsVariableInputParameter(into: &inputsDict, with: "_gt")
            self._gte.encodeAsVariableInputParameter(into: &inputsDict, with: "_gte")
            self._in.encodeAsVariableInputParameter(into: &inputsDict, with: "_in")
            self._is_null.encodeAsVariableInputParameter(into: &inputsDict, with: "_is_null")
            self._lt.encodeAsVariableInputParameter(into: &inputsDict, with: "_lt")
            self._lte.encodeAsVariableInputParameter(into: &inputsDict, with: "_lte")
            self._neq.encodeAsVariableInputParameter(into: &inputsDict, with: "_neq")
            self._nin.encodeAsVariableInputParameter(into: &inputsDict, with: "_nin")
            return inputsDict
        }
    }
}

public struct ExampleSpaceXQuery: AutoGraphQLRequest {
    public typealias SerializedObject = Data

    public init() { }

    public var variables: [AnyHashable : Any]? { return nil }

    public var data: Data?
    public struct Data: Codable {
        public private(set) var company: Info? = nil
        public private(set) var roadster: Roadster? = nil

        public init(company: Info? = nil, roadster: Roadster? = nil) {
            self.company = company
            self.roadster = roadster
        }
    }

    public var operation: AutoGraphQL.Operation {
        return AutoGraphQL.Operation(type: .query, name: "ExampleSpaceX", variableDefinitions: nil, directives: nil, selectionSet: [
            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
            Selection.field(name: "company", alias: nil, arguments: nil, directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "ceo", alias: nil, arguments: nil, directives: nil, type: .scalar)
            ])),
            Selection.field(name: "roadster", alias: nil, arguments: nil, directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "apoapsis_au", alias: nil, arguments: nil, directives: nil, type: .scalar)
            ]))
        ])
    }

    public static var fragments: [FragmentDefinition] {

        let fragments = [FragmentDefinition]()
    
        return fragments
    }
    
    public var fragments: [FragmentDefinition] {
        return ExampleSpaceXQuery.fragments
    }

    public struct Info: Codable {
        public init(__typename: String = String(), ceo: String? = nil) {
            self.__typename = __typename
            self.ceo = ceo
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.ceo = try values.decode(String?.self, forKey: .ceo)
        }

        public private(set) var __typename: String = String()
        public private(set) var ceo: String? = nil
    }

    public struct Roadster: Codable {
        public init(__typename: String = String(), apoapsis_au: Double? = nil) {
            self.__typename = __typename
            self.apoapsis_au = apoapsis_au
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.apoapsis_au = try values.decode(Double?.self, forKey: .apoapsis_au)
        }

        public private(set) var __typename: String = String()
        public private(set) var apoapsis_au: Double? = nil
    }
}

public struct ExampleSpaceX2Query: AutoGraphQLRequest {
    public typealias SerializedObject = Data

    public let _$limit: OptionalInputValue<Int>

    public init(limit: OptionalInputValue<Int>) {
        self._$limit = limit
    }

    public var variables: [AnyHashable : Any]? {
        var variablesDict = [AnyHashable : any VariableInputParameterEncodable]()
        _$limit.encodeAsVariableInputParameter(into: &variablesDict, with: "limit")
        return variablesDict
    }

    public var data: Data?
    public struct Data: Codable {
        public private(set) var capsules: [Capsule?]? = nil
        public private(set) var company: Info? = nil

        public init(capsules: [Capsule?]? = nil, company: Info? = nil) {
            self.capsules = capsules
            self.company = company
        }
    }

    public var operation: AutoGraphQL.Operation {
        return AutoGraphQL.Operation(type: .query, name: "ExampleSpaceX2", variableDefinitions: [try! AnyVariableDefinition(name: "limit", typeName: .scalar(.int), defaultValue: nil)], directives: nil, selectionSet: [
            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
            Selection.field(name: "company", alias: nil, arguments: nil, directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "ceo", alias: nil, arguments: nil, directives: nil, type: .scalar)
            ])),
            Selection.field(name: "capsules", alias: nil, arguments: ["find" : ["id" : 4, "mission" : "cool", "type" : "rocket"] as [String: Any], "limit" : Variable(name: "limit")], directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "id", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "missions", alias: nil, arguments: nil, directives: nil, type: .object(selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "name", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "flight", alias: nil, arguments: nil, directives: nil, type: .scalar)
                ]))
            ]))
        ])
    }

    public static var fragments: [FragmentDefinition] {

        let fragments = [FragmentDefinition]()
    
        return fragments
    }
    
    public var fragments: [FragmentDefinition] {
        return ExampleSpaceX2Query.fragments
    }

    public struct Capsule: Codable {
        public init(__typename: String = String(), id: String? = nil, missions: [Capsule.CapsuleMission?]? = nil) {
            self.__typename = __typename
            self.id = id
            self.missions = missions
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.id = try values.decode(String?.self, forKey: .id)
            self.missions = try values.decode([Capsule.CapsuleMission?]?.self, forKey: .missions)
        }

        public private(set) var __typename: String = String()
        public private(set) var id: String? = nil

        public private(set) var missions: [CapsuleMission?]? = nil

        public struct CapsuleMission: Codable {
            public init(__typename: String = String(), flight: Int? = nil, name: String? = nil) {
                self.__typename = __typename
                self.flight = flight
                self.name = name
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.flight = try values.decode(Int?.self, forKey: .flight)
                self.name = try values.decode(String?.self, forKey: .name)
            }

            public private(set) var __typename: String = String()
            public private(set) var flight: Int? = nil
            public private(set) var name: String? = nil
        }
    }

    public struct Info: Codable {
        public init(__typename: String = String(), ceo: String? = nil) {
            self.__typename = __typename
            self.ceo = ceo
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.ceo = try values.decode(String?.self, forKey: .ceo)
        }

        public private(set) var __typename: String = String()
        public private(set) var ceo: String? = nil
    }
}

public struct MutationMutation: AutoGraphQLRequest {
    public typealias SerializedObject = Data

    public let _$where: SpaceXGQLSchema.users_bool_exp
    public let _$set: OptionalInputValue<SpaceXGQLSchema.users_set_input>

    public init(`where`: SpaceXGQLSchema.users_bool_exp, set: OptionalInputValue<SpaceXGQLSchema.users_set_input>) {
        self._$where = `where`
        self._$set = set
    }

    public var variables: [AnyHashable : Any]? {
        var variablesDict = [AnyHashable : any VariableInputParameterEncodable]()
        variablesDict["where"] = _$where.encodedAsVariableInputParameter
        _$set.encodeAsVariableInputParameter(into: &variablesDict, with: "set")
        return variablesDict
    }

    public var data: Data?
    public struct Data: Codable {
        public private(set) var update_users: users_mutation_response? = nil

        public init(update_users: users_mutation_response? = nil) {
            self.update_users = update_users
        }
    }

    public var operation: AutoGraphQL.Operation {
        return AutoGraphQL.Operation(type: .mutation, name: "Mutation", variableDefinitions: [try! AnyVariableDefinition(name: "where", typeName: .nonNull(.object(typeName: "users_bool_exp")), defaultValue: nil), try! AnyVariableDefinition(name: "set", typeName: .object(typeName: "users_set_input"), defaultValue: nil)], directives: nil, selectionSet: [
            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
            Selection.field(name: "update_users", alias: nil, arguments: ["where" : Variable(name: "where"), "_set" : Variable(name: "set")], directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "affected_rows", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "returning", alias: nil, arguments: nil, directives: nil, type: .object(selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "rocket", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "timestamp", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "twitter", alias: nil, arguments: nil, directives: nil, type: .scalar)
                ]))
            ]))
        ])
    }

    public static var fragments: [FragmentDefinition] {

        let fragments = [FragmentDefinition]()
    
        return fragments
    }
    
    public var fragments: [FragmentDefinition] {
        return MutationMutation.fragments
    }

    public struct users_mutation_response: Codable {
        public init(__typename: String = String(), affected_rows: Int = Int(), returning: [users_mutation_response.users] = []) {
            self.__typename = __typename
            self.affected_rows = affected_rows
            self.returning = returning
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.affected_rows = try values.decode(Int.self, forKey: .affected_rows)
            self.returning = try values.decode([users_mutation_response.users].self, forKey: .returning)
        }

        public private(set) var __typename: String = String()
        public private(set) var affected_rows: Int = Int()

        public private(set) var returning: [users] = []

        public struct users: Codable {
            public init(__typename: String = String(), rocket: String? = nil, timestamp: SpaceXGQLSchema.timestamptz = SpaceXGQLSchema.timestamptz(), twitter: String? = nil) {
                self.__typename = __typename
                self.rocket = rocket
                self.timestamp = timestamp
                self.twitter = twitter
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.rocket = try values.decode(String?.self, forKey: .rocket)
                self.timestamp = try values.decode(SpaceXGQLSchema.timestamptz.self, forKey: .timestamp)
                self.twitter = try values.decode(String?.self, forKey: .twitter)
            }

            public private(set) var __typename: String = String()
            public private(set) var rocket: String? = nil
            public private(set) var timestamp: SpaceXGQLSchema.timestamptz = SpaceXGQLSchema.timestamptz()
            public private(set) var twitter: String? = nil
        }
    }
}

public struct SubscriptionSubscription: AutoGraphQLRequest {
    public typealias SerializedObject = Data

    public let _$limit: OptionalInputValue<Int>
    public let _$offset: OptionalInputValue<Int>
    public let _$distinctOn: OptionalInputValue<[SpaceXGQLSchema.users_select_column]>

    public init(limit: OptionalInputValue<Int>, offset: OptionalInputValue<Int>, distinctOn: OptionalInputValue<[SpaceXGQLSchema.users_select_column]>) {
        self._$limit = limit
        self._$offset = offset
        self._$distinctOn = distinctOn
    }

    public var variables: [AnyHashable : Any]? {
        var variablesDict = [AnyHashable : any VariableInputParameterEncodable]()
        _$limit.encodeAsVariableInputParameter(into: &variablesDict, with: "limit")
        _$offset.encodeAsVariableInputParameter(into: &variablesDict, with: "offset")
        _$distinctOn.encodeAsVariableInputParameter(into: &variablesDict, with: "distinctOn")
        return variablesDict
    }

    public var data: Data?
    public struct Data: Codable {
        public private(set) var users: [users] = []

        public init(users: [users] = []) {
            self.users = users
        }
    }

    public var operation: AutoGraphQL.Operation {
        return AutoGraphQL.Operation(type: .subscription, name: "Subscription", variableDefinitions: [try! AnyVariableDefinition(name: "limit", typeName: .scalar(.int), defaultValue: nil), try! AnyVariableDefinition(name: "offset", typeName: .scalar(.int), defaultValue: nil), try! AnyVariableDefinition(name: "distinctOn", typeName: .list(.nonNull(.object(typeName: "users_select_column"))), defaultValue: nil)], directives: nil, selectionSet: [
            Selection.field(name: "users", alias: nil, arguments: ["limit" : Variable(name: "limit"), "offset" : Variable(name: "offset"), "distinct_on" : Variable(name: "distinctOn")], directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "name", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "rocket", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "timestamp", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "id", alias: nil, arguments: nil, directives: nil, type: .scalar)
            ]))
        ])
    }

    public static var fragments: [FragmentDefinition] {

        let fragments = [FragmentDefinition]()
    
        return fragments
    }
    
    public var fragments: [FragmentDefinition] {
        return SubscriptionSubscription.fragments
    }

    public struct users: Codable {
        public init(__typename: String = String(), id: SpaceXGQLSchema.uuid = SpaceXGQLSchema.uuid(), name: String? = nil, rocket: String? = nil, timestamp: SpaceXGQLSchema.timestamptz = SpaceXGQLSchema.timestamptz()) {
            self.__typename = __typename
            self.id = id
            self.name = name
            self.rocket = rocket
            self.timestamp = timestamp
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.id = try values.decode(SpaceXGQLSchema.uuid.self, forKey: .id)
            self.name = try values.decode(String?.self, forKey: .name)
            self.rocket = try values.decode(String?.self, forKey: .rocket)
            self.timestamp = try values.decode(SpaceXGQLSchema.timestamptz.self, forKey: .timestamp)
        }

        public private(set) var __typename: String = String()
        public private(set) var id: SpaceXGQLSchema.uuid = SpaceXGQLSchema.uuid()
        public private(set) var name: String? = nil
        public private(set) var rocket: String? = nil
        public private(set) var timestamp: SpaceXGQLSchema.timestamptz = SpaceXGQLSchema.timestamptz()
    }
}
