import Foundation
import AutoGraphParser
import SwiftSyntax

public func getConfiguration(_ path: String? = nil) throws -> Configuration {
    // Not sure why it's requiring this availability considering we're
    // forcing a higher version of MacOS in our Package.
    guard #available(macOS 13.0, *) else {
        throw AutoGraphCodeGenError.configuration(message: "Must be on MacOS 13 or higher.")
    }
    
    let configFilePath: String = {
        if let path = path { return path }
        let fileManager = FileManager.default
        let currentDirectoryPath = fileManager.currentDirectoryPath
        if CommandLine.arguments.count > 1 {
            return CommandLine.arguments[1]
        }
        else {
            return currentDirectoryPath + "/" + "autograph_codegen_config.json"
        }
    }()
    
    print("Config file path: \(configFilePath)")
    
    let configUrl = URL(filePath: configFilePath)
    let configData = try Data(contentsOf: configUrl)
    let jsonConfig = try JSONSerialization.jsonObject(with: configData, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! [AnyHashable: Any]
    return try Configuration(json: jsonConfig, relativePath: configUrl.deletingLastPathComponent().path)
}

public func codeGen(configuration: Configuration) throws {
    // TODO: Need to throw when `outputProductsPath` and `requestsOutputPath` include one
    // or the other otherwise they'll delete eachother on cleanup. "Shared" is just a bit
    // of a hack to reduce that chance. Probably should rename `outputProductsPath` to
    // `sharedOutputProductsPath` while we're at it.
    
    // TODO: When swift 5.9 releases, add configuration to allow namespacing shared stuff
    // under the schema namespace if desired. Requires `https://github.com/apple/swift-evolution/blob/main/proposals/0404-nested-protocols.md`
    let sharedOutputProductsPath = configuration.outputProductsPath + "/Shared"
    func writeProtocolDeclarations() throws {
        let fileName = "GraphQLSchemaRequest.swift"
        let path = sharedOutputProductsPath + "/" + fileName
        
        // Prints here are a subtle lie, since we write this all in one go...
        print("writing graphql request protocols to \(path)")
        let requestProtocolCode = RequestProtocolGenerator().protocolsCode
        print("writing optional input type to \(path)")
        let optionalInputValueCode = OptionalInputValueGenerator.typeDeclaration
        print("writing variable definition protocol requirements to \(path)")
        let variableInputParameterCode = VariableInputParameterEncodableGenerator.code
        
        let code =
            """
            import Foundation
            import AutoGraphQL
            import JSONValueRX
            
            \(requestProtocolCode)
            
            \(optionalInputValueCode)
            
            \(variableInputParameterCode)
            
            """
        try code.write(toFile: path, atomically: false, encoding: .utf8)
    }
    
    let fileManager = FileManager.default
    
    // TODO: Diff and only re-create files on diff.
    if fileManager.fileExists(atPath: sharedOutputProductsPath) {
        print("Cleaning out outputProductsPath shared folder")
        try fileManager.removeItem(atPath: sharedOutputProductsPath)
    }
    try fileManager.createDirectory(atPath: sharedOutputProductsPath, withIntermediateDirectories: true, attributes: nil)
    if configuration.replaceRequestProtocolsWithImports == nil {
        try writeProtocolDeclarations()
    }
    
    try configuration.schemaConfigurations.forEach {
        try codeGenSchema(configuration: $0)
    }
}

public func codeGenSchema(configuration: Configuration.SchemaConfiguration) throws {
    let fileManager = FileManager.default
    let schema = try __Schema.loadFrom(jsonSchemaPath: configuration.schemaPath)
    let allTypes = try AllTypes(schema: schema, outputSchemaName: configuration.outputSchemaName)
    try allTypes.loadExecutableDefinitions(configuration: configuration, fileManager: fileManager)
    
    let requestsOutputPath = configuration.requestsOutputPath
    if fileManager.fileExists(atPath: requestsOutputPath) {
        print("Cleaning out requestsOutputPath")
        try fileManager.contentsOfDirectory(atPath: requestsOutputPath).forEach {
            // We allow users to edit Custom Scalars directly, so it is their
            // responsibility to remove old objects.
            guard $0 != "Custom Scalars" else {
                return
            }
            let path = "\(requestsOutputPath)/\($0)"
            try fileManager.removeItem(atPath: path)
        }
    }
    
    func writeClientSchema(allTypes: AllTypes) throws {
        let file = allTypes.generateFileNameAndImports(configuration: configuration)
        let path = requestsOutputPath + "/" + file.fileName
        
        print("writing graphql schema to \(path)")
        try (file.fileText + "\n").write(toFile: path, atomically: false, encoding: .utf8)
        
        guard let fileHandle = FileHandle(forWritingAtPath: path) else {
            throw AutoGraphCodeGenError.codeGeneration(message: "Failed to open file at path \(path) for writing")
        }
        defer {
            fileHandle.closeFile()
        }
        fileHandle.seekToEndOfFile()
        
        // NOTE: Operations are not namespaced because the client controls their naming directly.
        // However, fragments are namespaced because it's typical to name a fragment as
        // `TypeFragment`, which has a higher chance of collision across schemas.
        // Everything else is namespaced because it's not within the client's control.
        let schemaNamespaceText = """
        public enum \(allTypes.outputSchemaName) {
        
        """
        let schemaNamespaceTextData = schemaNamespaceText.data(using: String.Encoding.utf8)!
        fileHandle.write(schemaNamespaceTextData)
        
        var needsNewlines = false
        print("writing graphql enums data structures to \(path)")
        if let enumText = allTypes.generateEnumDeclarations(indentation: "    ") {
            let enumTextData = enumText.data(using: String.Encoding.utf8)!
            fileHandle.write(enumTextData)
            needsNewlines = true
        }
        
        print("writing graphql input object data structures to \(path)")
        if let inputObjectText = allTypes.generateInputObjectStructDeclarations(indentation: "    ") {
            if needsNewlines {
                fileHandle.write("\n\n".data(using: String.Encoding.utf8)!)
            }
            let inputObjectTextData = inputObjectText.data(using: String.Encoding.utf8)!
            fileHandle.write(inputObjectTextData)
        }
        
        print("writing graphql fragments to \(path)")
        if let fragmentsStructsText = try allTypes.generateFragmentsStructs(indentation: "    ") {
            if needsNewlines {
                fileHandle.write("\n\n".data(using: String.Encoding.utf8)!)
            }
            let fragmentsTextData = fragmentsStructsText.data(using: String.Encoding.utf8)!
            fileHandle.write(fragmentsTextData)
        }
        
        let schemaNamespaceCloseText = "\n}\n\n"
        let schemaNamespaceCloseTextData = schemaNamespaceCloseText.data(using: String.Encoding.utf8)!
        fileHandle.write(schemaNamespaceCloseTextData)
        
        print("writing graphql operations to \(path)")
        let operationsStructsText = try allTypes.generateOperationsStructs(indentation: "")
        let operationsTextData = (operationsStructsText + "\n").data(using: String.Encoding.utf8)!
        fileHandle.write(operationsTextData)
    }
    
    func writeCustomScalarExtensionFiles(allTypes: AllTypes) throws {
        let orderedScalars = allTypes.customScalarTypes.sorted { lhs, rhs in lhs.key.rawValue < rhs.key.rawValue }
        guard orderedScalars.count > 0 else {
            return
        }

        let dir = "\(requestsOutputPath)/Custom Scalars"
        try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)

        try orderedScalars.forEach { (key, scalar) in
            let path = "\(dir)/\(key.rawValue).swift"
            guard !fileManager.fileExists(atPath: path) else {
                return
            }

            let output = """
                         public extension \(allTypes.outputSchemaName) {
                             typealias \(key.rawValue) = String
                         }\n
                         """
            guard let data = output.data(using: .utf8) else {
                throw AutoGraphCodeGenError.configuration(message: "Failed to create a custom scalar file at \(path)")
            }
            fileManager.createFile(atPath: path, contents: data)
        }
    }
    
    try fileManager.createDirectory(atPath: requestsOutputPath, withIntermediateDirectories: true, attributes: nil)
    
    try writeClientSchema(allTypes: allTypes)
    try writeCustomScalarExtensionFiles(allTypes: allTypes)
    
    print("Successfully code generated GraphQL schema(s) to Swift.")
}
