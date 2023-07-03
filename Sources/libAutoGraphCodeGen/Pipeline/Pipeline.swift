import Foundation
import AutoGraphParser
import SwiftSyntax

public func getConfiguration(_ path: String? = nil) throws -> Configuration {
    // Not sure why it's requiring this availability considering we're
    // forcing a higher version of MacOS.
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
        let variableInputParamterCode = VariableInputParameterEncodableGenerator.code
        
        let code =
            """
            import Foundation
            import AutoGraphQL
            import JSONValueRX
            
            \(requestProtocolCode)
            
            \(optionalInputValueCode)
            
            \(variableInputParamterCode)
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
        let file = allTypes.generateImports(configuration: configuration)
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
        
        print("writing graphql enums data structures to \(path)")
        let enumText = allTypes.genEnumDeclarations()
        let enumTextData = (enumText + "\n\n").data(using: String.Encoding.utf8)!
        fileHandle.write(enumTextData)
        
        print("writing graphql input object data structures to \(path)")
        let inputObjectText = allTypes.genInputObjectStructDeclarations()
        let inputObjectTextData = (inputObjectText + "\n\n").data(using: String.Encoding.utf8)!
        fileHandle.write(inputObjectTextData)
        
        print("writing graphql documents (fragments and operations) to \(path)")
        let fragmentsAndOperationsText = try allTypes.genFragmentsAndOperationsStructs(indentation: "    ")
        let fragmentsAndOperationsTextData = (fragmentsAndOperationsText + "\n").data(using: String.Encoding.utf8)!
        fileHandle.write(fragmentsAndOperationsTextData)
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
