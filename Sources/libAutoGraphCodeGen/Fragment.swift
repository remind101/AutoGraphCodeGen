import Foundation
import AutoGraphParser

struct FragmentDefinitionIR {
    let fragment: FragmentDefinition
    let selectionSet: SelectionSetIR
}

extension FragmentDefinition {
    func lowerToIR(allTypes: AllTypes) throws -> (ir: FragmentDefinitionIR, liftedEnumTypes: [GraphQLTypeName: EnumType]) {
        guard let typeInformation = self.typeCondition.typeInformation(allTypes: allTypes) else {
            throw AutoGraphCodeGenError.validation(message: "Type of Fragment \(name) cannot be resolved, type of \(self.typeCondition) does not exist")
        }
        let selectionSet = try self.selectionSet.lowerToIR(on: typeInformation, along: [], allTypes: allTypes)
        
        switch selectionSet {
        case (let ir, let liftedEnumTypes):
            return (FragmentDefinitionIR(fragment: self, selectionSet: ir), liftedEnumTypes)
        }
    }
}
