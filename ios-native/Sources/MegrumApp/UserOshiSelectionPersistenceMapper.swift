import Foundation
import MegrumCore

enum UserOshiSelectionPersistenceMapper {
    static func selections(
        from inputs: [AccountSetupOshiInput],
        userID: UUID,
        idFactory: () -> UUID = UUID.init
    ) -> [UserOshiSelection] {
        inputs.map { input in
            UserOshiSelection(
                id: idFactory(),
                userID: userID,
                groupID: input.groupID,
                characterID: input.characterID,
                kind: input.kind,
                priority: input.priority,
                oshiRequestID: input.oshiRequestID,
                characterRequestID: input.characterRequestID
            )
        }
    }
}
