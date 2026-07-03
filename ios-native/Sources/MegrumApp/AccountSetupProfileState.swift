import Foundation
import MegrumCore

struct AccountSetupProfileState {
    var prefectureSearchText = ""
    var displayName: String
    var handle: String
    var prefecture: String
    var birthDate: Date
    var gender: UserGender?
    var inputErrorMessage: String?

    var draft: AccountSetupProfileDraft {
        AccountSetupProfileDraft(
            displayName: displayName,
            handle: handle,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender
        )
    }
}

struct AccountSetupProfileDraft: Equatable {
    var displayName: String
    var handle: String
    var prefecture: String
    var birthDate: Date
    var gender: UserGender?

    func validationMessage(
        for step: AccountSetupStep,
        oshiSelections: [AccountSetupOshiInput]
    ) -> String? {
        AccountSetupDraftValidator.validationMessage(
            for: step,
            displayName: displayName,
            handle: handle,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender,
            oshiSelections: oshiSelections
        )
    }

    func validationMessage(oshiSelections: [AccountSetupOshiInput]) -> String? {
        AccountSetupDraftValidator.validationMessage(
            displayName: displayName,
            handle: handle,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender,
            oshiSelections: oshiSelections
        )
    }

    func accountSetupInput(oshiSelections: [AccountSetupOshiInput]) -> AccountSetupInput {
        AccountSetupInput(
            handle: handle,
            displayName: displayName,
            gender: gender,
            prefecture: prefecture,
            birthDate: birthDate,
            oshiSelections: oshiSelections
        )
    }
}
