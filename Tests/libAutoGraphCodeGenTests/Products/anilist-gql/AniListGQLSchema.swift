import Foundation
import AutoGraphQL
import JSONValueRX

public enum AniListGQLSchema {
    /// Media type enum, anime or manga.
    public enum MediaType: RawRepresentable, Codable, Hashable, EnumVariableInputParameterEncodable, EnumValueProtocol {
        public typealias RawValue = String

        /// Japanese Anime
        case anime
        /// Asian comic
        case manga
        case __unknown(RawValue)

        public init() {
            self = .__unknown("")
        }

        public init?(rawValue: String) {
            switch rawValue {
            case "ANIME":
                self = .anime
            case "MANGA":
                self = .manga
            default:
                self = .__unknown(rawValue)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            self = MediaType(rawValue: value) ?? .__unknown(value)
        }

        public var rawValue: String {
            switch self {
            case .anime:
                return "ANIME"
            case .manga:
                return "MANGA"
            case .__unknown(let val):
                return val
            }
        }

        public func graphQLInputValue() throws -> String {
            return self.rawValue
        }
    }
}

public struct ExampleAniListWithEnumFieldQuery: AutoGraphQLRequest {
    public typealias SerializedObject = Data

    public init() { }

    public var variables: [AnyHashable : Any]? { return nil }

    public var data: Data?
    public struct Data: Codable {
        public private(set) var Page: Page? = nil

        public init(Page: Page? = nil) {
            self.Page = Page
        }
    }

    public var operation: AutoGraphQL.Operation {
        return AutoGraphQL.Operation(type: .query, name: "ExampleAniListWithEnumField", variableDefinitions: nil, directives: nil, selectionSet: [
            Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
            Selection.field(name: "Page", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                Selection.field(name: "media", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                    Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "type", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "siteUrl", alias: "", arguments: nil, directives: nil, type: .scalar),
                    Selection.field(name: "title", alias: "", arguments: nil, directives: nil, type: .object(selectionSet: [
                        Selection.field(name: "__typename", alias: nil, arguments: nil, directives: nil, type: .scalar),
                        Selection.field(name: "english", alias: "", arguments: nil, directives: nil, type: .scalar),
                        Selection.field(name: "native", alias: "", arguments: nil, directives: nil, type: .scalar)
                    ])),
                    Selection.field(name: "description", alias: "", arguments: nil, directives: nil, type: .scalar)
                ]))
            ]))
        ])
    }

    public static var fragments: [FragmentDefinition] {

        let fragments = [FragmentDefinition]()
    
        return fragments
    }
    
    public var fragments: [FragmentDefinition] {
        return ExampleAniListWithEnumFieldQuery.fragments
    }

    public struct Page: Codable {
        public init(__typename: String = String(), media: [Page.Media?]? = nil) {
            self.__typename = __typename
            self.media = media
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try values.decode(String.self, forKey: .__typename)
            self.__typename = typename
            self.media = try values.decode([Page.Media?]?.self, forKey: .media)
        }

        public private(set) var __typename: String = String()

        public private(set) var media: [Media?]? = nil

        public struct Media: Codable {
            public init(__typename: String = String(), description: String? = nil, siteUrl: String? = nil, type: AniListGQLSchema.MediaType? = nil, title: Media.MediaTitle? = nil) {
                self.__typename = __typename
                self.description = description
                self.siteUrl = siteUrl
                self.type = type
                self.title = title
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let typename = try values.decode(String.self, forKey: .__typename)
                self.__typename = typename
                self.description = try values.decode(String?.self, forKey: .description)
                self.siteUrl = try values.decode(String?.self, forKey: .siteUrl)
                self.type = try values.decode(AniListGQLSchema.MediaType?.self, forKey: .type)
                self.title = try values.decode(Media.MediaTitle?.self, forKey: .title)
            }

            public private(set) var __typename: String = String()
            public private(set) var description: String? = nil
            public private(set) var siteUrl: String? = nil
            public private(set) var type: AniListGQLSchema.MediaType? = nil

            public private(set) var title: MediaTitle? = nil

            public struct MediaTitle: Codable {
                public init(__typename: String = String(), english: String? = nil, native: String? = nil) {
                    self.__typename = __typename
                    self.english = english
                    self.native = native
                }

                public init(from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let typename = try values.decode(String.self, forKey: .__typename)
                    self.__typename = typename
                    self.english = try values.decode(String?.self, forKey: .english)
                    self.native = try values.decode(String?.self, forKey: .native)
                }

                public private(set) var __typename: String = String()
                public private(set) var english: String? = nil
                public private(set) var native: String? = nil
            }
        }
    }
}
