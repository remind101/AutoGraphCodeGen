import Foundation
import AutoGraphQL
import JSONValueRX





public struct PokeGQLSchema {


    public struct ExampleQueryQuery: AutoGraphQLRequest {

        public typealias SerializedObject = Data

        public let _$pokemonV2AbilityByPkId: Int

        public init(pokemonV2AbilityByPkId: Int) {
            self._$pokemonV2AbilityByPkId = pokemonV2AbilityByPkId
        }

        public var variables: [AnyHashable : Any]? {
            var variablesDict = [AnyHashable : any VariableInputParameterEncodable]()
            variablesDict["pokemonV2AbilityByPkId"] = _$pokemonV2AbilityByPkId.encodedAsVariableInputParameter
            return variablesDict
        }

        public var data: Data?
        public struct Data: Codable {
        public private(set) var pokemon_v2_ability_by_pk: pokemon_v2_ability? = nil

            public init(pokemon_v2_ability_by_pk: pokemon_v2_ability? = nil) {
                self.pokemon_v2_ability_by_pk = pokemon_v2_ability_by_pk
            }
        }

        public var operation: AutoGraphQL.Operation {
            return AutoGraphQL.Operation(type: .query, name: "ExampleQuery", variableDefinitions: [try! AnyVariableDefinition(name: "pokemonV2AbilityByPkId", typeName: .nonNull(.scalar(.int)), defaultValue: nil)], directives: nil, selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "pokemon_v2_ability_by_pk", alias: "", arguments: ["id" : Variable(name: "pokemonV2AbilityByPkId")], directives: nil, type: .object(selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "generation_id", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "id", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "is_main_series", alias: "", arguments: nil, directives: [Directive(name: "skip", arguments: ["if" : false])], type: .scalar),
                    Selection.field(name: "name", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "pokemon_v2_abilitychanges", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                        Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                        Selection.field(name: "ability_id", alias: "", arguments: nil, directives: nil, type: .scalar),
                        Selection.field(name: "pokemon_v2_ability", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                            Selection.field(name: "name", alias: "", arguments: nil, directives: [Directive(name: "specifiedBy", arguments: nil)], type: .scalar),
                            Selection.field(name: "is_main_series", alias: "", arguments: nil, directives: nil, type: .scalar),
                            Selection.field(name: "pokemon_v2_abilityflavortexts_aggregate", alias: "", arguments: ["order_by" : Variable(name: "orderBy")], directives: nil, type: .object(selectionSet: [
                                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "aggregate", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                    Selection.field(name: "count", alias: "", arguments: nil, directives: nil, type: .scalar)
                                ]))
                            ]))
                        ]))
                    ]))
                ]))
            ])
        }

        public static var fragments: [FragmentDefinition] {

            let fragments = [FragmentDefinition]()
        
            return fragments
        }
        
        public var fragments: [FragmentDefinition] {
            return ExampleQueryQuery.fragments
        }

        public struct pokemon_v2_ability: Codable {
            public init(__typename: String = String(), generation_id: Int? = nil, id: Int = Int(), is_main_series: Bool = Bool(), name: String = String(), pokemon_v2_abilitychanges: [pokemon_v2_ability.pokemon_v2_abilitychange] = []) {
                self.__typename = __typename
                self.generation_id = generation_id
                self.id = id
                self.is_main_series = is_main_series
                self.name = name
                self.pokemon_v2_abilitychanges = pokemon_v2_abilitychanges
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.generation_id = try values.decode(Int?.self, forKey: .generation_id)
                self.id = try values.decode(Int.self, forKey: .id)
                self.is_main_series = try values.decode(Bool.self, forKey: .is_main_series)
                self.name = try values.decode(String.self, forKey: .name)
                self.pokemon_v2_abilitychanges = try values.decode([pokemon_v2_ability.pokemon_v2_abilitychange].self, forKey: .pokemon_v2_abilitychanges)
            }

            public private(set) var __typename: String = String()
            public private(set) var generation_id: Int? = nil
            public private(set) var id: Int = Int()
            public private(set) var is_main_series: Bool = Bool()
            public private(set) var name: String = String()

            public private(set) var pokemon_v2_abilitychanges: [pokemon_v2_abilitychange] = []

            public struct pokemon_v2_abilitychange: Codable {
                public init(__typename: String = String(), ability_id: Int? = nil, pokemon_v2_ability: pokemon_v2_abilitychange.pokemon_v2_ability? = nil) {
                    self.__typename = __typename
                    self.ability_id = ability_id
                    self.pokemon_v2_ability = pokemon_v2_ability
                }

                public init(from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let typename = try values.decode(String.self, forKey: .__typename)
                    self.__typename = typename
                    self.ability_id = try values.decode(Int?.self, forKey: .ability_id)
                    self.pokemon_v2_ability = try values.decode(pokemon_v2_abilitychange.pokemon_v2_ability?.self, forKey: .pokemon_v2_ability)
                }

                public private(set) var __typename: String = String()
                public private(set) var ability_id: Int? = nil

                public private(set) var pokemon_v2_ability: pokemon_v2_ability? = nil

                public struct pokemon_v2_ability: Codable {
                    public init(__typename: String = String(), is_main_series: Bool = Bool(), name: String = String(), pokemon_v2_abilityflavortexts_aggregate: pokemon_v2_ability.pokemon_v2_abilityflavortext_aggregate = pokemon_v2_ability.pokemon_v2_abilityflavortext_aggregate()) {
                        self.__typename = __typename
                        self.is_main_series = is_main_series
                        self.name = name
                        self.pokemon_v2_abilityflavortexts_aggregate = pokemon_v2_abilityflavortexts_aggregate
                    }

                    public init(from decoder: Decoder) throws {
                        let values = try decoder.container(keyedBy: CodingKeys.self)
                        let typename = try values.decode(String.self, forKey: .__typename)
                        self.__typename = typename
                        self.is_main_series = try values.decode(Bool.self, forKey: .is_main_series)
                        self.name = try values.decode(String.self, forKey: .name)
                        self.pokemon_v2_abilityflavortexts_aggregate = try values.decode(pokemon_v2_ability.pokemon_v2_abilityflavortext_aggregate.self, forKey: .pokemon_v2_abilityflavortexts_aggregate)
                    }

                    public private(set) var __typename: String = String()
                    public private(set) var is_main_series: Bool = Bool()
                    public private(set) var name: String = String()

                    public private(set) var pokemon_v2_abilityflavortexts_aggregate: pokemon_v2_abilityflavortext_aggregate = pokemon_v2_abilityflavortext_aggregate()

                    public struct pokemon_v2_abilityflavortext_aggregate: Codable {
                        public init(__typename: String = String(), aggregate: pokemon_v2_abilityflavortext_aggregate.pokemon_v2_abilityflavortext_aggregate_fields? = nil) {
                            self.__typename = __typename
                            self.aggregate = aggregate
                        }

                        public init(from decoder: Decoder) throws {
                            let values = try decoder.container(keyedBy: CodingKeys.self)
                            let typename = try values.decode(String.self, forKey: .__typename)
                            self.__typename = typename
                            self.aggregate = try values.decode(pokemon_v2_abilityflavortext_aggregate.pokemon_v2_abilityflavortext_aggregate_fields?.self, forKey: .aggregate)
                        }

                        public private(set) var __typename: String = String()

                        public private(set) var aggregate: pokemon_v2_abilityflavortext_aggregate_fields? = nil

                        public struct pokemon_v2_abilityflavortext_aggregate_fields: Codable {
                            public init(__typename: String = String(), count: Int = Int()) {
                                self.__typename = __typename
                                self.count = count
                            }

                            public init(from decoder: Decoder) throws {
                                let values = try decoder.container(keyedBy: CodingKeys.self)
                                let typename = try values.decode(String.self, forKey: .__typename)
                                self.__typename = typename
                                self.count = try values.decode(Int.self, forKey: .count)
                            }

                            public private(set) var __typename: String = String()
                            public private(set) var count: Int = Int()


                        }

                    }

                }

            }

        }

    }

}
