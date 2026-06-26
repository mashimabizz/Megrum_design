@testable import MegrumApp
import MegrumCore
import XCTest

final class AccountSetupScreenTests: XCTestCase {
    func testAccountSetupDraftValidatorRequiresDisplayName() {
        let message = AccountSetupDraftValidator.validationMessage(
            displayName: " ",
            oshiSelections: [makeOshiInput()]
        )

        XCTAssertEqual(message, AccountSetupDraftValidator.missingDisplayNameMessage)
    }

    func testAccountSetupDraftValidatorRequiresOshiSelection() {
        let message = AccountSetupDraftValidator.validationMessage(
            displayName: "みち",
            oshiSelections: []
        )

        XCTAssertEqual(message, AccountSetupDraftValidator.missingOshiMessage)
    }

    func testAccountSetupDraftValidatorRequiresHandle() {
        let message = validationMessage(handle: " ")

        XCTAssertEqual(message, AccountSetupDraftValidator.missingHandleMessage)
    }

    func testAccountSetupDraftValidatorRejectsInvalidHandle() {
        let message = validationMessage(handle: "みち")

        XCTAssertEqual(message, AccountSetupDraftValidator.invalidHandleMessage)
    }

    func testAccountSetupDraftValidatorRequiresPrefecture() {
        let message = validationMessage(prefecture: nil)

        XCTAssertEqual(message, AccountSetupDraftValidator.missingPrefectureMessage)
    }

    func testAccountSetupDraftValidatorRejectsInvalidPrefecture() {
        let message = validationMessage(prefecture: "東都")

        XCTAssertEqual(message, AccountSetupDraftValidator.invalidPrefectureMessage)
    }

    func testAccountSetupDraftValidatorRequiresBirthDate() {
        let message = validationMessage(birthDate: nil)

        XCTAssertEqual(message, AccountSetupDraftValidator.missingBirthDateMessage)
    }

    func testAccountSetupDraftValidatorRejectsFutureBirthDate() {
        let message = validationMessage(birthDate: Date().addingTimeInterval(86_400))

        XCTAssertEqual(message, AccountSetupDraftValidator.futureBirthDateMessage)
    }

    func testAccountSetupDraftValidatorRequiresGender() {
        let message = validationMessage(gender: nil)

        XCTAssertEqual(message, AccountSetupDraftValidator.missingGenderMessage)
    }

    func testAccountSetupDraftValidatorAcceptsReadyDraft() {
        let message = AccountSetupDraftValidator.validationMessage(
            displayName: " みち ",
            oshiSelections: [makeOshiInput()]
        )

        XCTAssertNil(message)
    }

    func testAccountSetupDraftValidatorAcceptsCompleteDraft() {
        XCTAssertNil(validationMessage())
    }

    private func validationMessage(
        displayName: String = "みち",
        handle: String = "michirion",
        prefecture: String? = "東京都",
        birthDate: Date? = Date(timeIntervalSince1970: 0),
        gender: UserGender? = .female,
        oshiSelections: [AccountSetupOshiInput]? = nil
    ) -> String? {
        AccountSetupDraftValidator.validationMessage(
            displayName: displayName,
            handle: handle,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender,
            oshiSelections: oshiSelections ?? [makeOshiInput()]
        )
    }

    private func makeOshiInput() -> AccountSetupOshiInput {
        AccountSetupOshiInput(
            groupID: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            characterID: nil,
            kind: .box
        )
    }
}
