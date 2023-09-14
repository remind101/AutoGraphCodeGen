import Foundation
import XCTest
import AutoGraphQL
import libAutoGraphCodeGen

class SystemTests: XCTestCase {
    func testSystem() throws {
        // TODO:
        // 1. Run the codegen.
        // 2. Run the compiler with new file included.
        // 3. Catch and print errors.
        @discardableResult
        func shell(_ args: String...) -> Int32 {
            let task = Process()
            task.launchPath = "/usr/bin/env"
            task.arguments = args
            task.launch()
            task.waitUntilExit()
            return task.terminationStatus
        }
        
        // E.g.
        // shell("xcodebuild", "-workspace", "myApp.xcworkspace")
      
        let components = URL(fileURLWithPath: #file).pathComponents
        guard let sourcePath = components.filter({ $0 != "/"}).split(separator: "libAutoGraphCodeGenTests").first?.joined(separator: "/") else {
            XCTFail("Unable to find root directory of project. Make sure your tests are in a folder named `Tests` in the root directory")
            return
        }
        
        let folderPath = "/\(sourcePath)"
        let configurationPath = folderPath + "/Resources/test_autograph_codegen_config.json"
        
        let configuration = try getConfiguration(configurationPath)
        try! codeGen(configuration: configuration)
    }
}
