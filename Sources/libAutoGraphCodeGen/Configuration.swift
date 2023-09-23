import Foundation
import AutoGraphParser

/// Configuration for the code generator. May be populated by a config json file. See Tests
/// for example.
public struct Configuration {
    /// The path for the shared abstractions (protocols, enums, etc.) used by all requests to
    /// send through AutoGraph.
    ///
    /// E.g. if there are 2 schema configurations each would still require using the same always
    /// generated `OptionalInputValue` type. In order to share this type, the user would
    /// choose a `sharedOutputsPath` directory that both schema's seperate outputs still
    /// have access to, either in the same module or a separate module with they both depend on.
    public let sharedOutputsPath: String
    /// Per schema configurations for the code generator. AutoGraphCodeGen supports code generating
    /// for multiple schemas at once.
    public let schemaConfigurations: [SchemaConfiguration]
    /// When not `nil`, skips generating shared outputs (which areused in (nearly) every operation).
    /// Instead generates `import <String>` for every string declared in this Array at the top of the
    /// generated `<schema>.swift` file with the assumption that one of these imports also includes
    /// those shared outputs already.
    ///
    /// This is useful when separate instances of the code generator is used in separate modules and
    /// the user doesn't want to recreate the same shared outputs in both modules but rather share them via
    /// a module dependency.
    public let replaceRequestProtocolsWithImports: [String]?
    
    /// Per schema configurations. AutoGraphCodeGen supports code generating
    /// for multiple schemas at once.
    public struct SchemaConfiguration {
        /// The path to the schema `.json` file produced by introspection query. This is read into
        /// the code generator to type check and validate against the schema during code generation.
        ///
        /// One may use `scripts/introspection-schema-json` to generate the schema .json file.
        public let schemaPath: String
        /// The path to the GraphQL document files. Files should end in `.graphql` and contain either
        /// Operations or Fragments or both. These files are read and then used to code generate requests
        /// the user will send over AutoGraph.
        public let gqlDocumentsPath: String
        /// The path where requests code generated from Documents (Operations and Fragments) are
        /// outputted to. Custom Scalars are also generated at this path.
        public let requestsOutputPath: String
        /// The name file and of the namespace used for the generated code, except for Custom Scalars
        /// which have their own directory.
        /// All Operations, Enums, Fragments, and Input Objects end up in the file with this name under path
        /// `{requestsOutputPath}/{outputSchemaName}.swift`. Types other than operations are
        /// also further namespaced by `struct {outputSchemaName}` in order to disambiguate from
        /// conflicting type names in other schemas. Operations are not further namespaced because the user
        /// must choose a name for their Operations anyway.
        public let outputSchemaName: String
        /// Any additional imports that the user wishes to include in their output schema swift file they may
        /// include here.
        public let additionalImports: [String]
        
        public init(schemaPath: String, gqlDocumentsPath: String, requestsOutputPath: String, outputSchemaName: String, additionalImports: [String] = []) {
            self.schemaPath = schemaPath
            self.gqlDocumentsPath = gqlDocumentsPath
            self.requestsOutputPath = requestsOutputPath
            self.outputSchemaName = outputSchemaName
            self.additionalImports = additionalImports
        }
        
        public init(json: [AnyHashable: Any], relativePath: String, sharedOutputsPath: String, additionalImports: [String]) throws {
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
    
    public init(sharedOutputsPath: String, schemaConfigurations: [SchemaConfiguration], replaceRequestProtocolsWithImports: [String]? = nil) {
        self.sharedOutputsPath = sharedOutputsPath
        self.schemaConfigurations = schemaConfigurations
        self.replaceRequestProtocolsWithImports = replaceRequestProtocolsWithImports
    }
    
    public init(json: [AnyHashable : Any], relativePath: String) throws {
        guard case let sharedOutputsPath as String = json["sharedOutputsPath"] else {
            throw AutoGraphCodeGenError.configuration(message: "Config file must provide an 'sharedOutputsPath'")
        }
        self.sharedOutputsPath = relativePath + "/" + sharedOutputsPath
        print("sharedOutputsPath: \(self.sharedOutputsPath)")
        
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
            try SchemaConfiguration(json: $0, relativePath: relativePath, sharedOutputsPath: sharedOutputsPath, additionalImports: additionalImports)
        }
    }
}
