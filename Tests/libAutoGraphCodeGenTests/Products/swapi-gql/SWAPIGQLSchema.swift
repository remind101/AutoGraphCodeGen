import Foundation
import AutoGraphQL
import JSONValueRX

public enum SWAPIGQLSchema {
    public struct CharacterConnFrag: Codable {
        public init(__typename: String = String(), pageInfo: PageInfo = PageInfo()) {
            self.__typename = __typename
            self.pageInfo = pageInfo
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.pageInfo = try values.decode(PageInfo.self, forKey: .pageInfo)
        }

        enum CodingKeys: String, CodingKey {
            case __typename
            case pageInfo
        }

        public private(set) var __typename: String = "FilmCharactersConnection"

        public private(set) var pageInfo: PageInfo = PageInfo()

        public static var fragments: [FragmentDefinition] {
            let fragment = FragmentDefinition(name: "CharacterConnFrag", type: "FilmCharactersConnection", directives: nil, selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "pageInfo", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "hasPreviousPage", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "hasPreviousPage", alias: "alias1", arguments: nil, directives: nil, type: .scalar)
                ]))
            ])!

            let fragments = [fragment]
        
            return fragments
        }
        
        public var fragments: [FragmentDefinition] {
            return CharacterConnFrag.fragments
        }

        public struct PageInfo: Codable {
            public init(__typename: String = "PageInfo", alias1: Bool = Bool(), hasPreviousPage: Bool = Bool()) {
                self.__typename = __typename
                self.alias1 = alias1
                self.hasPreviousPage = hasPreviousPage
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.alias1 = try values.decode(Bool.self, forKey: .alias1)
                self.hasPreviousPage = try values.decode(Bool.self, forKey: .hasPreviousPage)
            }

            public private(set) var __typename: String = "PageInfo"
            public private(set) var alias1: Bool = Bool()
            public private(set) var hasPreviousPage: Bool = Bool()
        }
    }

    public struct PersonFrag: Codable {
        public init(__typename: String = String(), birthYear: String? = nil, id: String = String()) {
            self.__typename = __typename
            self.birthYear = birthYear
            self.id = id
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.birthYear = try values.decode(String?.self, forKey: .birthYear)
            self.id = try values.decode(String.self, forKey: .id)
        }

        enum CodingKeys: String, CodingKey {
            case __typename
            case birthYear
            case id
        }

        public private(set) var __typename: String = "Person"
        public private(set) var birthYear: String? = nil
        public private(set) var id: String = String()

        public static var fragments: [FragmentDefinition] {
            let fragment = FragmentDefinition(name: "PersonFrag", type: "Person", directives: nil, selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "id", alias: "", arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "birthYear", alias: "", arguments: nil, directives: nil, type: .scalar)
            ])!

            let fragments = [fragment]
        
            return fragments
        }
        
        public var fragments: [FragmentDefinition] {
            return PersonFrag.fragments
        }
    }
}

public struct ExampleStarWarsQuery: AutoGraphQLRequest {
    public typealias SerializedObject = Data

    public let _$nodeId: String
    public let _$after: OptionalInputValue<String>
    public let _$first: OptionalInputValue<Int>
    public let _$last: OptionalInputValue<Int>

    public init(nodeId: String, after: OptionalInputValue<String>, first: OptionalInputValue<Int>, last: OptionalInputValue<Int>) {
        self._$nodeId = nodeId
        self._$after = after
        self._$first = first
        self._$last = last
    }

    public var variables: [AnyHashable : Any]? {
        var variablesDict = [AnyHashable : any VariableInputParameterEncodable]()
        variablesDict["nodeId"] = _$nodeId.encodedAsVariableInputParameter
        _$after.encodeAsVariableInputParameter(into: &variablesDict, with: "after")
        _$first.encodeAsVariableInputParameter(into: &variablesDict, with: "first")
        _$last.encodeAsVariableInputParameter(into: &variablesDict, with: "last")
        return variablesDict
    }

    public var data: Data?
    public struct Data: Codable {
        public private(set) var allFilms: FilmsConnection? = nil
        public private(set) var node: Node? = nil

        public init(allFilms: FilmsConnection? = nil, node: Node? = nil) {
            self.allFilms = allFilms
            self.node = node
        }
    }

    public var operation: AutoGraphQL.Operation {
        return AutoGraphQL.Operation(type: .query, name: "ExampleStarWars", variableDefinitions: [try! AnyVariableDefinition(name: "nodeId", typeName: .nonNull(.scalar(.id)), defaultValue: nil), try! AnyVariableDefinition(name: "after", typeName: .scalar(.string), defaultValue: nil), try! AnyVariableDefinition(name: "first", typeName: .scalar(.int), defaultValue: nil), try! AnyVariableDefinition(name: "last", typeName: .scalar(.int), defaultValue: nil)], directives: nil, selectionSet: [
            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
            Selection.field(name: "node", alias: "", arguments: ["id" : Variable(name: "nodeId")], directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "id", alias: "", arguments: nil, directives: nil, type: .scalar),
                Selection.inlineFragment(namedType: "Film", directives: nil, selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "director", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "id", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "planetConnection", alias: "", arguments: ["first" : Variable(name: "first"), "last" : Variable(name: "last")], directives: nil, type: .object(selectionSet: [
                        Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                        Selection.field(name: "totalCount", alias: "", arguments: nil, directives: nil, type: .scalar)
                    ]))
                ]),
                Selection.inlineFragment(namedType: "Person", directives: nil, selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "birthYear", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "hairColor", alias: "", arguments: nil, directives: nil, type: .scalar)
                ])
            ])),
            Selection.field(name: "allFilms", alias: "", arguments: ["after" : Variable(name: "after")], directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "edges", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "node", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                        Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                        Selection.inlineFragment(namedType: "Film", directives: nil, selectionSet: [
                            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                            Selection.field(name: "episodeID", alias: "", arguments: nil, directives: nil, type: .scalar)
                        ]),
                        Selection.field(name: "characterConnection", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                            Selection.fragmentSpread(name: "CharacterConnFrag", directives: nil),
                            Selection.field(name: "pageInfo", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "hasPreviousPage", alias: "", arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "startCursor", alias: "", arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "hasNextPage", alias: "", arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "endCursor", alias: "", arguments: nil, directives: nil, type: .scalar)
                            ])),
                            Selection.field(name: "characters", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "birthYear", alias: "", arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "created", alias: "", arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "edited", alias: "", arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "eyeColor", alias: "", arguments: nil, directives: nil, type: .scalar),
                                Selection.field(name: "homeworld", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                    Selection.field(name: "climates", alias: "", arguments: nil, directives: nil, type: .scalar),
                                    Selection.field(name: "filmConnection", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                        Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                        Selection.field(name: "edges", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                            Selection.field(name: "node", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                                Selection.field(name: "characterConnection", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                                    Selection.field(name: "characters", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                                        Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                                        Selection.field(name: "filmConnection", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                                            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                                            Selection.field(name: "films", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                                                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                                                Selection.field(name: "id", alias: "", arguments: nil, directives: nil, type: .scalar),
                                                                Selection.field(name: "episodeID", alias: "", arguments: nil, directives: nil, type: .scalar),
                                                                Selection.field(name: "openingCrawl", alias: "", arguments: nil, directives: nil, type: .scalar)
                                                            ]))
                                                        ]))
                                                    ]))
                                                ]))
                                            ]))
                                        ]))
                                    ]))
                                ])),
                                Selection.field(name: "vehicleConnection", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                    Selection.field(name: "edges", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                        Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                        Selection.field(name: "node", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                                            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                                            Selection.field(name: "crew", alias: "", arguments: nil, directives: nil, type: .scalar),
                                            Selection.field(name: "edited", alias: "", arguments: nil, directives: nil, type: .scalar)
                                        ]))
                                    ]))
                                ]))
                            ]))
                        ]))
                    ]))
                ]))
            ]))
        ])
    }

    public static var fragments: [FragmentDefinition] {
        let characterConnFrag = SWAPIGQLSchema.CharacterConnFrag.fragments


        let fragments = [
            characterConnFrag
        ]
        .flatMap { $0 }
        .reduce(into: [:]) { (result: inout [String: FragmentDefinition], frag) in
            result[frag.name] = frag
        }
        .map { $0.1 }
    
        return fragments
    }
    
    public var fragments: [FragmentDefinition] {
        return ExampleStarWarsQuery.fragments
    }

    public struct FilmsConnection: Codable {
        public init(__typename: String = "FilmsConnection", edges: [FilmsConnection.FilmsEdge?]? = nil) {
            self.__typename = __typename
            self.edges = edges
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.edges = try values.decode([FilmsConnection.FilmsEdge?]?.self, forKey: .edges)
        }

        public private(set) var __typename: String = "FilmsConnection"

        public private(set) var edges: [FilmsEdge?]? = nil

        public struct FilmsEdge: Codable {
            public init(__typename: String = "FilmsEdge", node: FilmsEdge.Film? = nil) {
                self.__typename = __typename
                self.node = node
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.node = try values.decode(FilmsEdge.Film?.self, forKey: .node)
            }

            public private(set) var __typename: String = "FilmsEdge"

            public private(set) var node: Film? = nil

            public struct Film: Codable {
                public init(__typename: String = "Film", characterConnection: Film.FilmCharactersConnection? = nil, asFilm: AsFilm? = nil) {
                    self.__typename = __typename
                    self.characterConnection = characterConnection
                    self.asFilm = asFilm
                }

                public init(from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let typename = try values.decode(String.self, forKey: .__typename)
                    self.__typename = typename
                    self.characterConnection = try values.decode(Film.FilmCharactersConnection?.self, forKey: .characterConnection)
                    self.asFilm = typename == "Film" ? try AsFilm(from: decoder) : nil
                }

                public private(set) var __typename: String = "Film"

                public private(set) var characterConnection: FilmCharactersConnection? = nil

                public private(set) var asFilm: AsFilm? = nil

                public struct FilmCharactersConnection: Codable {
                    public init(__typename: String = "FilmCharactersConnection", characters: [FilmCharactersConnection.Person?]? = nil, pageInfo: FilmCharactersConnection.PageInfo = FilmCharactersConnection.PageInfo(), characterConnFrag: SWAPIGQLSchema.CharacterConnFrag = SWAPIGQLSchema.CharacterConnFrag()) {
                        self.__typename = __typename
                        self.characters = characters
                        self.pageInfo = pageInfo
                        self.characterConnFrag = characterConnFrag
                    }

                    public init(from decoder: Decoder) throws {
                        let values = try decoder.container(keyedBy: CodingKeys.self)
                        let typename = try values.decode(String.self, forKey: .__typename)
                        self.__typename = typename
                        self.characters = try values.decode([FilmCharactersConnection.Person?]?.self, forKey: .characters)
                        self.pageInfo = try values.decode(FilmCharactersConnection.PageInfo.self, forKey: .pageInfo)
                        self.characterConnFrag = try SWAPIGQLSchema.CharacterConnFrag(from: decoder)
                    }

                    public private(set) var __typename: String = "FilmCharactersConnection"

                    public private(set) var characters: [Person?]? = nil
                    public private(set) var pageInfo: PageInfo = PageInfo()

                    public private(set) var characterConnFrag: SWAPIGQLSchema.CharacterConnFrag = SWAPIGQLSchema.CharacterConnFrag()

                    public struct Person: Codable {
                        public init(__typename: String = "Person", birthYear: String? = nil, created: String? = nil, edited: String? = nil, eyeColor: String? = nil, homeworld: Person.Planet? = nil, vehicleConnection: Person.PersonVehiclesConnection? = nil) {
                            self.__typename = __typename
                            self.birthYear = birthYear
                            self.created = created
                            self.edited = edited
                            self.eyeColor = eyeColor
                            self.homeworld = homeworld
                            self.vehicleConnection = vehicleConnection
                        }

                        public init(from decoder: Decoder) throws {
                            let values = try decoder.container(keyedBy: CodingKeys.self)
                            let typename = try values.decode(String.self, forKey: .__typename)
                            self.__typename = typename
                            self.birthYear = try values.decode(String?.self, forKey: .birthYear)
                            self.created = try values.decode(String?.self, forKey: .created)
                            self.edited = try values.decode(String?.self, forKey: .edited)
                            self.eyeColor = try values.decode(String?.self, forKey: .eyeColor)
                            self.homeworld = try values.decode(Person.Planet?.self, forKey: .homeworld)
                            self.vehicleConnection = try values.decode(Person.PersonVehiclesConnection?.self, forKey: .vehicleConnection)
                        }

                        public private(set) var __typename: String = "Person"
                        public private(set) var birthYear: String? = nil
                        public private(set) var created: String? = nil
                        public private(set) var edited: String? = nil
                        public private(set) var eyeColor: String? = nil

                        public private(set) var homeworld: Planet? = nil
                        public private(set) var vehicleConnection: PersonVehiclesConnection? = nil

                        public struct Planet: Codable {
                            public init(__typename: String = "Planet", climates: [String?]? = nil, filmConnection: Planet.PlanetFilmsConnection? = nil) {
                                self.__typename = __typename
                                self.climates = climates
                                self.filmConnection = filmConnection
                            }

                            public init(from decoder: Decoder) throws {
                                let values = try decoder.container(keyedBy: CodingKeys.self)
                                let typename = try values.decode(String.self, forKey: .__typename)
                                self.__typename = typename
                                self.climates = try values.decode([String?]?.self, forKey: .climates)
                                self.filmConnection = try values.decode(Planet.PlanetFilmsConnection?.self, forKey: .filmConnection)
                            }

                            public private(set) var __typename: String = "Planet"
                            public private(set) var climates: [String?]? = nil

                            public private(set) var filmConnection: PlanetFilmsConnection? = nil

                            public struct PlanetFilmsConnection: Codable {
                                public init(__typename: String = "PlanetFilmsConnection", edges: [PlanetFilmsConnection.PlanetFilmsEdge?]? = nil) {
                                    self.__typename = __typename
                                    self.edges = edges
                                }

                                public init(from decoder: Decoder) throws {
                                    let values = try decoder.container(keyedBy: CodingKeys.self)
                                    let typename = try values.decode(String.self, forKey: .__typename)
                                    self.__typename = typename
                                    self.edges = try values.decode([PlanetFilmsConnection.PlanetFilmsEdge?]?.self, forKey: .edges)
                                }

                                public private(set) var __typename: String = "PlanetFilmsConnection"

                                public private(set) var edges: [PlanetFilmsEdge?]? = nil

                                public struct PlanetFilmsEdge: Codable {
                                    public init(__typename: String = "PlanetFilmsEdge", node: PlanetFilmsEdge.Film? = nil) {
                                        self.__typename = __typename
                                        self.node = node
                                    }

                                    public init(from decoder: Decoder) throws {
                                        let values = try decoder.container(keyedBy: CodingKeys.self)
                                        let typename = try values.decode(String.self, forKey: .__typename)
                                        self.__typename = typename
                                        self.node = try values.decode(PlanetFilmsEdge.Film?.self, forKey: .node)
                                    }

                                    public private(set) var __typename: String = "PlanetFilmsEdge"

                                    public private(set) var node: Film? = nil

                                    public struct Film: Codable {
                                        public init(__typename: String = "Film", characterConnection: Film.FilmCharactersConnection? = nil) {
                                            self.__typename = __typename
                                            self.characterConnection = characterConnection
                                        }

                                        public init(from decoder: Decoder) throws {
                                            let values = try decoder.container(keyedBy: CodingKeys.self)
                                            let typename = try values.decode(String.self, forKey: .__typename)
                                            self.__typename = typename
                                            self.characterConnection = try values.decode(Film.FilmCharactersConnection?.self, forKey: .characterConnection)
                                        }

                                        public private(set) var __typename: String = "Film"

                                        public private(set) var characterConnection: FilmCharactersConnection? = nil

                                        public struct FilmCharactersConnection: Codable {
                                            public init(__typename: String = "FilmCharactersConnection", characters: [FilmCharactersConnection.Person?]? = nil) {
                                                self.__typename = __typename
                                                self.characters = characters
                                            }

                                            public init(from decoder: Decoder) throws {
                                                let values = try decoder.container(keyedBy: CodingKeys.self)
                                                let typename = try values.decode(String.self, forKey: .__typename)
                                                self.__typename = typename
                                                self.characters = try values.decode([FilmCharactersConnection.Person?]?.self, forKey: .characters)
                                            }

                                            public private(set) var __typename: String = "FilmCharactersConnection"

                                            public private(set) var characters: [Person?]? = nil

                                            public struct Person: Codable {
                                                public init(__typename: String = "Person", filmConnection: Person.PersonFilmsConnection? = nil) {
                                                    self.__typename = __typename
                                                    self.filmConnection = filmConnection
                                                }

                                                public init(from decoder: Decoder) throws {
                                                    let values = try decoder.container(keyedBy: CodingKeys.self)
                                                    let typename = try values.decode(String.self, forKey: .__typename)
                                                    self.__typename = typename
                                                    self.filmConnection = try values.decode(Person.PersonFilmsConnection?.self, forKey: .filmConnection)
                                                }

                                                public private(set) var __typename: String = "Person"

                                                public private(set) var filmConnection: PersonFilmsConnection? = nil

                                                public struct PersonFilmsConnection: Codable {
                                                    public init(__typename: String = "PersonFilmsConnection", films: [PersonFilmsConnection.Film?]? = nil) {
                                                        self.__typename = __typename
                                                        self.films = films
                                                    }

                                                    public init(from decoder: Decoder) throws {
                                                        let values = try decoder.container(keyedBy: CodingKeys.self)
                                                        let typename = try values.decode(String.self, forKey: .__typename)
                                                        self.__typename = typename
                                                        self.films = try values.decode([PersonFilmsConnection.Film?]?.self, forKey: .films)
                                                    }

                                                    public private(set) var __typename: String = "PersonFilmsConnection"

                                                    public private(set) var films: [Film?]? = nil

                                                    public struct Film: Codable {
                                                        public init(__typename: String = "Film", episodeID: Int? = nil, id: String = String(), openingCrawl: String? = nil) {
                                                            self.__typename = __typename
                                                            self.episodeID = episodeID
                                                            self.id = id
                                                            self.openingCrawl = openingCrawl
                                                        }

                                                        public init(from decoder: Decoder) throws {
                                                            let values = try decoder.container(keyedBy: CodingKeys.self)
                                                            let typename = try values.decode(String.self, forKey: .__typename)
                                                            self.__typename = typename
                                                            self.episodeID = try values.decode(Int?.self, forKey: .episodeID)
                                                            self.id = try values.decode(String.self, forKey: .id)
                                                            self.openingCrawl = try values.decode(String?.self, forKey: .openingCrawl)
                                                        }

                                                        public private(set) var __typename: String = "Film"
                                                        public private(set) var episodeID: Int? = nil
                                                        public private(set) var id: String = String()
                                                        public private(set) var openingCrawl: String? = nil
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        public struct PersonVehiclesConnection: Codable {
                            public init(__typename: String = "PersonVehiclesConnection", edges: [PersonVehiclesConnection.PersonVehiclesEdge?]? = nil) {
                                self.__typename = __typename
                                self.edges = edges
                            }

                            public init(from decoder: Decoder) throws {
                                let values = try decoder.container(keyedBy: CodingKeys.self)
                                let typename = try values.decode(String.self, forKey: .__typename)
                                self.__typename = typename
                                self.edges = try values.decode([PersonVehiclesConnection.PersonVehiclesEdge?]?.self, forKey: .edges)
                            }

                            public private(set) var __typename: String = "PersonVehiclesConnection"

                            public private(set) var edges: [PersonVehiclesEdge?]? = nil

                            public struct PersonVehiclesEdge: Codable {
                                public init(__typename: String = "PersonVehiclesEdge", node: PersonVehiclesEdge.Vehicle? = nil) {
                                    self.__typename = __typename
                                    self.node = node
                                }

                                public init(from decoder: Decoder) throws {
                                    let values = try decoder.container(keyedBy: CodingKeys.self)
                                    let typename = try values.decode(String.self, forKey: .__typename)
                                    self.__typename = typename
                                    self.node = try values.decode(PersonVehiclesEdge.Vehicle?.self, forKey: .node)
                                }

                                public private(set) var __typename: String = "PersonVehiclesEdge"

                                public private(set) var node: Vehicle? = nil

                                public struct Vehicle: Codable {
                                    public init(__typename: String = "Vehicle", crew: String? = nil, edited: String? = nil) {
                                        self.__typename = __typename
                                        self.crew = crew
                                        self.edited = edited
                                    }

                                    public init(from decoder: Decoder) throws {
                                        let values = try decoder.container(keyedBy: CodingKeys.self)
                                        let typename = try values.decode(String.self, forKey: .__typename)
                                        self.__typename = typename
                                        self.crew = try values.decode(String?.self, forKey: .crew)
                                        self.edited = try values.decode(String?.self, forKey: .edited)
                                    }

                                    public private(set) var __typename: String = "Vehicle"
                                    public private(set) var crew: String? = nil
                                    public private(set) var edited: String? = nil
                                }
                            }
                        }
                    }

                    public struct PageInfo: Codable {
                        public init(__typename: String = "PageInfo", endCursor: String? = nil, hasNextPage: Bool = Bool(), hasPreviousPage: Bool = Bool(), startCursor: String? = nil) {
                            self.__typename = __typename
                            self.endCursor = endCursor
                            self.hasNextPage = hasNextPage
                            self.hasPreviousPage = hasPreviousPage
                            self.startCursor = startCursor
                        }

                        public init(from decoder: Decoder) throws {
                            let values = try decoder.container(keyedBy: CodingKeys.self)
                            let typename = try values.decode(String.self, forKey: .__typename)
                            self.__typename = typename
                            self.endCursor = try values.decode(String?.self, forKey: .endCursor)
                            self.hasNextPage = try values.decode(Bool.self, forKey: .hasNextPage)
                            self.hasPreviousPage = try values.decode(Bool.self, forKey: .hasPreviousPage)
                            self.startCursor = try values.decode(String?.self, forKey: .startCursor)
                        }

                        public private(set) var __typename: String = "PageInfo"
                        public private(set) var endCursor: String? = nil
                        public private(set) var hasNextPage: Bool = Bool()
                        public private(set) var hasPreviousPage: Bool = Bool()
                        public private(set) var startCursor: String? = nil
                    }
                }

                public struct AsFilm: Codable {
                    public init(__typename: String = "AsFilm", episodeID: Int? = nil) {
                        self.__typename = __typename
                        self.episodeID = episodeID
                    }

                    public init(from decoder: Decoder) throws {
                        let values = try decoder.container(keyedBy: CodingKeys.self)
                        let typename = try values.decode(String.self, forKey: .__typename)
                        self.__typename = typename
                        self.episodeID = try values.decode(Int?.self, forKey: .episodeID)
                    }

                    public private(set) var __typename: String = "AsFilm"
                    public private(set) var episodeID: Int? = nil
                }
            }
        }
    }

    public struct Node: Codable {
        public init(__typename: String = "Node", id: String = String(), asFilm: AsFilm? = nil, asPerson: AsPerson? = nil) {
            self.__typename = __typename
            self.id = id
            self.asFilm = asFilm
            self.asPerson = asPerson
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.id = try values.decode(String.self, forKey: .id)
            self.asFilm = typename == "Film" ? try AsFilm(from: decoder) : nil
            self.asPerson = typename == "Person" ? try AsPerson(from: decoder) : nil
        }

        public private(set) var __typename: String = "Node"
        public private(set) var id: String = String()

        public private(set) var asFilm: AsFilm? = nil
        public private(set) var asPerson: AsPerson? = nil

        public struct AsFilm: Codable {
            public init(__typename: String = "AsFilm", director: String? = nil, id: String = String(), planetConnection: AsFilm.FilmPlanetsConnection? = nil) {
                self.__typename = __typename
                self.director = director
                self.id = id
                self.planetConnection = planetConnection
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.director = try values.decode(String?.self, forKey: .director)
                self.id = try values.decode(String.self, forKey: .id)
                self.planetConnection = try values.decode(AsFilm.FilmPlanetsConnection?.self, forKey: .planetConnection)
            }

            public private(set) var __typename: String = "AsFilm"
            public private(set) var director: String? = nil
            public private(set) var id: String = String()

            public private(set) var planetConnection: FilmPlanetsConnection? = nil

            public struct FilmPlanetsConnection: Codable {
                public init(__typename: String = "FilmPlanetsConnection", totalCount: Int? = nil) {
                    self.__typename = __typename
                    self.totalCount = totalCount
                }

                public init(from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let typename = try values.decode(String.self, forKey: .__typename)
                    self.__typename = typename
                    self.totalCount = try values.decode(Int?.self, forKey: .totalCount)
                }

                public private(set) var __typename: String = "FilmPlanetsConnection"
                public private(set) var totalCount: Int? = nil
            }
        }

        public struct AsPerson: Codable {
            public init(__typename: String = "AsPerson", birthYear: String? = nil, hairColor: String? = nil) {
                self.__typename = __typename
                self.birthYear = birthYear
                self.hairColor = hairColor
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.birthYear = try values.decode(String?.self, forKey: .birthYear)
                self.hairColor = try values.decode(String?.self, forKey: .hairColor)
            }

            public private(set) var __typename: String = "AsPerson"
            public private(set) var birthYear: String? = nil
            public private(set) var hairColor: String? = nil
        }
    }
}

public struct TestTopLevelFragmentQuery: AutoGraphQLRequest {
    public typealias SerializedObject = Data

    public init() { }

    public var variables: [AnyHashable : Any]? { return nil }

    public var data: Data?
    public struct Data: Codable {
        public private(set) var person: Person? = nil

        public init(person: Person? = nil) {
            self.person = person
        }
    }

    public var operation: AutoGraphQL.Operation {
        return AutoGraphQL.Operation(type: .query, name: "TestTopLevelFragment", variableDefinitions: nil, directives: nil, selectionSet: [
            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
            Selection.field(name: "person", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.fragmentSpread(name: "PersonFrag", directives: nil)
            ]))
        ])
    }

    public static var fragments: [FragmentDefinition] {
        let personFrag = SWAPIGQLSchema.PersonFrag.fragments


        let fragments = [
            personFrag
        ]
        .flatMap { $0 }
        .reduce(into: [:]) { (result: inout [String: FragmentDefinition], frag) in
            result[frag.name] = frag
        }
        .map { $0.1 }
    
        return fragments
    }
    
    public var fragments: [FragmentDefinition] {
        return TestTopLevelFragmentQuery.fragments
    }

    public struct Person: Codable {
        public init(__typename: String = "Person", personFrag: SWAPIGQLSchema.PersonFrag = SWAPIGQLSchema.PersonFrag()) {
            self.__typename = __typename
            self.personFrag = personFrag
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.personFrag = try SWAPIGQLSchema.PersonFrag(from: decoder)
        }

        public private(set) var __typename: String = "Person"

        public private(set) var personFrag: SWAPIGQLSchema.PersonFrag = SWAPIGQLSchema.PersonFrag()
    }
}
