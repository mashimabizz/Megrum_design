@testable import MegrumApp
import Foundation
import MegrumCore
import XCTest

final class AccountSetupProfileDraftTests: XCTestCase {
    func testProfileDraftUsesExistingStepValidation() {
        let draft = AccountSetupProfileDraft(
            displayName: "みち",
            handle: "michirion",
            prefecture: "東京都",
            birthDate: Date(timeIntervalSince1970: 0),
            gender: .female
        )

        XCTAssertNil(draft.validationMessage(for: .displayName, oshiSelections: [makeOshiInput()]))
        XCTAssertNil(draft.validationMessage(for: .area, oshiSelections: [makeOshiInput()]))
    }

    func testProfileDraftKeepsFullValidationOrder() {
        let draft = AccountSetupProfileDraft(
            displayName: "",
            handle: "bad handle",
            prefecture: "",
            birthDate: Date().addingTimeInterval(86_400),
            gender: nil
        )

        XCTAssertEqual(
            draft.validationMessage(oshiSelections: []),
            AccountSetupDraftValidator.missingDisplayNameMessage
        )
    }

    func testProfileDraftBuildsAccountSetupInputWithoutNormalizingValues() {
        let birthDate = Date(timeIntervalSince1970: 123_456)
        let oshiSelections = [makeOshiInput()]
        let draft = AccountSetupProfileDraft(
            displayName: " みち ",
            handle: " MICHIRION ",
            prefecture: " 東京都 ",
            birthDate: birthDate,
            gender: .female
        )

        let input = draft.accountSetupInput(oshiSelections: oshiSelections)

        XCTAssertEqual(input.displayName, " みち ")
        XCTAssertEqual(input.handle, " MICHIRION ")
        XCTAssertEqual(input.prefecture, " 東京都 ")
        XCTAssertEqual(input.birthDate, birthDate)
        XCTAssertEqual(input.gender, .female)
        XCTAssertEqual(input.oshiSelections, oshiSelections)
    }

    private func makeOshiInput() -> AccountSetupOshiInput {
        AccountSetupOshiInput(
            groupID: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            characterID: nil,
            kind: .box
        )
    }
}
