import Foundation
public extension SpaceXGQLSchema {
    typealias uuid = UUID
}

extension UUID: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}
