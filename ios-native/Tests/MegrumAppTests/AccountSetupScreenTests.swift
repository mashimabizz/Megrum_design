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

    func testAccountSetupDraftValidatorAcceptsReadyDraft() {
        let message = AccountSetupDraftValidator.validationMessage(
            displayName: " みち ",
            oshiSelections: [makeOshiInput()]
        )

        XCTAssertNil(message)
    }

    private func makeOshiInput() -> AccountSetupOshiInput {
        AccountSetupOshiInput(
            groupID: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            characterID: nil,
            kind: .box
        )
    }
}
