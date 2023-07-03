import Foundation
import AutoGraphParser

// TODO: Encode into an Encodable. Requires either inserting data into a `JSONValue`
// which by definition should be `Encodable` or by having `VariableDefinitions`
// generate a `struct Variables` that is `Encodable` which requires some even deeper
// refactoring of `AutoGraph` though that is probably the right direction.
// Once that's solved we can completely remove `encodedAsVariableInputParameter` junk.

public struct OptionalInputValueGenerator {
    public static let TypeName = "OptionalInputValue"
    public static let typeDeclaration =
        """
        public indirect enum \(OptionalInputValueGenerator.TypeName)<T: Encodable & VariableInputParameterEncodable>: Encodable, ExpressibleByNilLiteral {
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
        """
}

/// `VariableInputParameterEncodable` describes a type that can be encoded
/// into a value that will transport correctly as a value in an `[AnyHashable : Any]`
/// variables dictionary into JSON.
///
/// Variables are inserted into an `[AnyHashable : Any]` and added to the body of the
/// GraphQL request. Since GraphQL is encoded as application/json we need all values to conform
/// to the set of values that are accepted by Foundation.JSONSerialization. Some base values for
/// this set are `Int` and it's variations, `String`, `Double`, `Float`, `NSNull`, and any `Array`
/// or `Dictionary` that contains _only_ those accepted values. All code-generated InputObject types
/// conform to `VariableInputParameterEncodable` which reduces them to these base types.
public struct VariableInputParameterEncodableGenerator {
    public static let code = """
    public protocol VariableInputParameterEncodable {
        var encodedAsVariableInputParameter: any VariableInputParameterEncodable { get }
    }
    
    public protocol EnumVariableInputParameterEncodable: VariableInputParameterEncodable, RawRepresentable where RawValue == String { }
    extension EnumVariableInputParameterEncodable {
        public var encodedAsVariableInputParameter: VariableInputParameterEncodable {
            return self.rawValue
        }
    }
    
    extension UUID: VariableInputParameterEncodable {
        public var encodedAsVariableInputParameter: VariableInputParameterEncodable { return self }
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
    """
}

