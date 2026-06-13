@testable import MegrumApp
import MegrumCore
import XCTest

final class OshiSettingsDraftTests: XCTestCase {
    func testBuildCombinesSavedSelectionsByGroupAndKeepsPriorityOrder() {
        let userID = uuid("10000000-0000-0000-0000-000000000101")
        let groupID = uuid("10000000-0000-0000-0000-000000000102")
        let sanaID = uuid("10000000-0000-0000-0000-000000000103")
        let momoID = uuid("10000000-0000-0000-0000-000000000104")
        let requestID = uuid("10000000-0000-0000-0000-000000000105")
        let group = OshiGroup(id: groupID, name: "TWICE")
        let selections = [
            UserOshiSelection(
                id: uuid("10000000-0000-0000-0000-000000000106"),
                userID: userID,
                groupID: groupID,
                characterID: momoID,
                kind: .specific,
                priority: 2,
                characterName: "MOMO"
            ),
            UserOshiSelection(
                id: uuid("10000000-0000-0000-0000-000000000107"),
                userID: userID,
                groupID: groupID,
                characterID: sanaID,
                kind: .specific,
                priority: 1,
                characterName: "SANA"
            ),
            UserOshiSelection(
                id: uuid("10000000-0000-0000-0000-000000000108"),
                userID: userID,
                groupID: nil,
                characterID: nil,
                kind: .box,
                priority: 3,
                oshiRequestID: requestID,
                oshiRequestName: "New Group"
            )
        ]

        let drafts = OshiSettingsGroupDraft.build(selections: selections, masterGroups: [group])

        XCTAssertEqual(drafts.map(\.name), ["TWICE", "New Group"])
        XCTAssertEqual(drafts.first?.members.map(\.name), ["SANA", "MOMO"])
        XCTAssertEqual(drafts.first?.priority, 1)
        XCTAssertFalse(drafts.first?.pending ?? true)
        XCTAssertTrue(drafts.last?.pending ?? false)
    }

    func testAccountSetupInputsReprioritizesGroupsAndMembers() {
        let group = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000111"), name: "aespa")
        let member = OshiCharacter(
            id: uuid("10000000-0000-0000-0000-000000000112"),
            groupID: group.id,
            name: "KARINA"
        )
        let requestID = uuid("10000000-0000-0000-0000-000000000113")
        let pending = OshiSettingsGroupDraft(
            requestID: requestID,
            name: "Pending Group",
            pending: true,
            priority: 20
        )
        var selectedMember = OshiSettingsGroupDraft(masterGroup: group, priority: 10)
        selectedMember.members.append(OshiSettingsMemberDraft(character: member))

        let inputs = OshiSettingsGroupDraft.accountSetupInputs(from: [pending, selectedMember])

        XCTAssertEqual(inputs.count, 2)
        XCTAssertEqual(inputs[0].oshiRequestID, requestID)
        XCTAssertEqual(inputs[0].kind, .box)
        XCTAssertEqual(inputs[0].priority, 1)
        XCTAssertEqual(inputs[1].groupID, group.id)
        XCTAssertEqual(inputs[1].characterID, member.id)
        XCTAssertEqual(inputs[1].kind, .specific)
        XCTAssertEqual(inputs[1].priority, 2_000)
    }

    private func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
