import Foundation
import AutoGraphQL
import JSONValueRX

public protocol AutoGraphQLRequest: Request {
    associatedtype QueryDocument = Document
    
    var operation: AutoGraphQL.Operation { get }
    var fragments: [FragmentDefinition] { get }
    var data: SerializedObject? { get set }
}

public extension AutoGraphQLRequest {
    var queryDocument: Document {
        let operation = self.operation
        let fragments = self.fragments
        return Document(operations: [operation], fragments: fragments)
    }
    
    var operationName: String {
        return self.operation.name
    }
    
    var rootKeyPath: String { return "data" }
    
    func willSend() throws { }
    func didFinishRequest(response: HTTPURLResponse?, json: JSONValue) throws { }
    func didFinish(result: AutoGraphResult<SerializedObject>) throws { }
}

public struct EnumConversionError: LocalizedError {
    let type: Any.Type

    init(type: Any.Type) {
        self.type = type
    }

    public var errorDescription: String? {
        return "Failed to convert JSON to \(self.type)"
    }
}

public indirect enum OptionalInputValue<T: Encodable & VariableInputParameterEncodable>: Encodable, ExpressibleByNilLiteral {
    case val(T), null, ignored
    public init(nilLiteral: ()) { self = .null }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .val(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .ignored: break
        }
    }
    
    public func encodeAsVariableInputParameter(into dictionary: inout [AnyHashable : VariableInputParameterEncodable], with key: AnyHashable) {
        switch self {
        case .val(let val):
            dictionary[key] = val.encodedAsVariableInputParameter
        case .null:
            dictionary[key] = NSNull()
        case .ignored:
            break
        }
    }
}

public protocol VariableInputParameterEncodable {
    var encodedAsVariableInputParameter: any VariableInputParameterEncodable { get }
}

public protocol EnumVariableInputParameterEncodable: VariableInputParameterEncodable, RawRepresentable where RawValue == String { }
extension EnumVariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable {
        return self.rawValue
    }
}

extension Bool: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Int: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Int64: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Int32: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Int16: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Int8: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension UInt: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension UInt64: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension UInt32: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension UInt16: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension UInt8: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Double: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Float: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension NSNumber: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension String: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension NSNull: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
}

extension Dictionary: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable {
        var encoded = [AnyHashable: Any]()
        for (key, value) in self {
            let encodedVal: Any = {
                guard case let castedVal as VariableInputParameterEncodable = value else {
                    return value
                }
                return castedVal.encodedAsVariableInputParameter
            }()
            encoded[key] = encodedVal
        }
        return encoded
    }
}

extension Array: VariableInputParameterEncodable {
    public var encodedAsVariableInputParameter: VariableInputParameterEncodable {
        let encoded: [Any] = self.map {
            guard case let castedVal as VariableInputParameterEncodable = $0 else {
                return $0
            }
            return castedVal.encodedAsVariableInputParameter
        }
        return encoded
    }
}
