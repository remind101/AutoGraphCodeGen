import Foundation
import AutoGraphParser

public enum AutoGraphCodeGenError: LocalizedError {
    /// Error from user configuration.
    case configuration(message: String)
    /// Error internal to the code generator.
    case codeGeneration(message: String)
    /// Errors parsing GraphQL.
    case parsing(message: String, underlying: Error)
    /// Validation error while validating user's input documents.
    case validation(message: String)
    
    public var errorDescription: String? {
        return "\(self)"
    }
}
