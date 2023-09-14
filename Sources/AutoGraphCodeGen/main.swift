import Foundation
import libAutoGraphCodeGen

do {
    let configuration = try getConfiguration()
    try codeGen(configuration: configuration)
}
catch let e {
    print("Error: \(e.localizedDescription)")
    FileHandle.standardError.write(Data(e.localizedDescription.utf8))
    exit(1)
}
