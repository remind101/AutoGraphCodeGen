import Foundation
import AutoGraphParser

public struct Configuration {
    public let outputProductsPath: String
    public let schemaConfigurations: [SchemaConfiguration]
    /// If this is set, rather than generate the request protocols used in (nearly) every operation,
    /// it imports a module that already has those protocols generated. This is useful when separate
    /// instances of the code generator is used in separate modules and you don't want to recreate the same
    /// protocols in both modules. Requires that one module is a dependency of another.
    public let replaceRequestProtocolsWithImports: [String]?
    
    public struct SchemaConfiguration {
        public let schemaPath: String
        public let gqlDocumentsPath: String
        public let requestsOutputPath: String
        public let outputSchemaName: String
        public let additionalImports: [String]
        
        public init(schemaPath: String, gqlDocumentsPath: String, requestsOutputPath: String, outputSchemaName: String, additionalImports: [String] = []) {
            self.schemaPath = schemaPath
            self.gqlDocumentsPath = gqlDocumentsPath
            self.requestsOutputPath = requestsOutputPath
            self.outputSchemaName = outputSchemaName
            self.additionalImports = additionalImports
        }
        
        public init(json: [AnyHashable: Any], relativePath: String, outputProductsPath: String, additionalImports: [String]) throws {
            guard case let outputSchemaName as String = json["outputSchemaName"] else {
                throw AutoGraphCodeGenError.configuration(message: "Config file must provide a 'outputSchemaName'")
            }
            self.outputSchemaName = outputSchemaName
            print("outputSchemaName: \(self.outputSchemaName)")
            
            guard case let schemaPath as String = json["schemaPath"] else {
                throw AutoGraphCodeGenError.configuration(message: "Config file must provide a 'schemaPath'")
            }
            self.schemaPath = relativePath + "/" + schemaPath
            print("schemaPath: \(self.schemaPath)")
            
            guard case let gqlDocumentsPath as String = json["gqlDocumentsPath"] else {
                throw AutoGraphCodeGenError.configuration(message: "Config file must provide a 'gqlDocumentsPath'")
            }
            self.gqlDocumentsPath = relativePath + "/" + gqlDocumentsPath
            print("gqlDocumentsPath: \(self.gqlDocumentsPath)")
            
            guard case let requestsOutputPath as String = json["requestsOutputPath"] else {
                throw AutoGraphCodeGenError.configuration(message: "Config file must provide a 'requestsOutputPath'")
            }
            self.requestsOutputPath = relativePath + "/" + requestsOutputPath
            print("requestsOutputPath: \(self.requestsOutputPath)")
            
            self.additionalImports = additionalImports
        }
    }
    
    public init(outputProductsPath: String, schemaConfigurations: [SchemaConfiguration], replaceRequestProtocolsWithImports: [String]? = nil) {
        self.outputProductsPath = outputProductsPath
        self.schemaConfigurations = schemaConfigurations
        self.replaceRequestProtocolsWithImports = replaceRequestProtocolsWithImports
    }
    
    public init(json: [AnyHashable : Any], relativePath: String) throws {
        guard case let outputProductsPath as String = json["outputProductsPath"] else {
            throw AutoGraphCodeGenError.configuration(message: "Config file must provide an 'outputProductsPath'")
        }
        self.outputProductsPath = relativePath + "/" + outputProductsPath
        print("outputProductsPath: \(self.outputProductsPath)")
        
        guard case let schemas as [[AnyHashable : Any]] = json["schemas"] else {
            throw AutoGraphCodeGenError.configuration(message: "Config file must provide 'schemas'")
        }
        
        if case let replaceRequestProtocolsWithImports as [String] = json["replaceRequestProtocolsWithImports"] {
            self.replaceRequestProtocolsWithImports = replaceRequestProtocolsWithImports
        }
        else {
            self.replaceRequestProtocolsWithImports = nil
        }
        let additionalImports = self.replaceRequestProtocolsWithImports ?? []
        
        self.schemaConfigurations = try schemas.map {
            try SchemaConfiguration(json: $0, relativePath: relativePath, outputProductsPath: outputProductsPath, additionalImports: additionalImports)
        }
    }
}
