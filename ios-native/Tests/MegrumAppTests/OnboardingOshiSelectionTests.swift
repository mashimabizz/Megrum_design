@testable import MegrumApp
import MegrumCore
import XCTest

final class OnboardingOshiSelectionTests: XCTestCase {
    func testWholeGroupSelectionReplacesMemberSelectionsForSameGroup() {
        let group = OshiGroup(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "TWICE")
        let sana = OshiCharacter(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            groupID: group.id,
            name: "SANA"
        )

        let memberSelected = OnboardingOshiSelectionLogic.toggleCharacter(sana, group: group, in: [])
        let wholeGroupSelected = OnboardingOshiSelectionLogic.toggleWholeGroup(group, in: memberSelected)

        XCTAssertEqual(wholeGroupSelected.count, 1)
        XCTAssertTrue(OnboardingOshiSelectionLogic.isWholeGroupSelected(group, in: wholeGroupSelected))
        XCTAssertFalse(OnboardingOshiSelectionLogic.isCharacterSelected(sana, in: wholeGroupSelected))
    }

    func testMultipleMembersCanBeSelectedAcrossGroups() {
        let twice = OshiGroup(id: UUID(uuidString: "10000000-0000-0000-0000-000000000011")!, name: "TWICE")
        let ive = OshiGroup(id: UUID(uuidString: "10000000-0000-0000-0000-000000000012")!, name: "IVE")
        let sana = OshiCharacter(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000013")!,
            groupID: twice.id,
            name: "SANA"
        )
        let momo = OshiCharacter(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000014")!,
            groupID: twice.id,
            name: "MOMO"
        )
        let wonyoung = OshiCharacter(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000015")!,
            groupID: ive.id,
            name: "WONYOUNG"
        )

        let drafts = [
            (sana, twice),
            (momo, twice),
            (wonyoung, ive)
        ].reduce(into: [OnboardingOshiDraft]()) { selected, pair in
            selected = OnboardingOshiSelectionLogic.toggleCharacter(pair.0, group: pair.1, in: selected)
        }

        XCTAssertEqual(drafts.map(\.displayName), ["TWICE / SANA", "TWICE / MOMO", "IVE / WONYOUNG"])
        XCTAssertEqual(drafts.map(\.kind), [.specific, .specific, .specific])
    }

    func testAccountSetupInputsKeepVisiblePriorityOrder() {
        let twice = OshiGroup(id: UUID(uuidString: "10000000-0000-0000-0000-000000000021")!, name: "TWICE")
        let ive = OshiGroup(id: UUID(uuidString: "10000000-0000-0000-0000-000000000022")!, name: "IVE")
        let drafts = [
            OnboardingOshiDraft(groupID: twice.id, groupName: twice.name, characterID: nil, characterName: nil),
            OnboardingOshiDraft(
                groupID: ive.id,
                groupName: ive.name,
                characterID: UUID(uuidString: "10000000-0000-0000-0000-000000000023")!,
                characterName: "LIZ"
            )
        ]

        let inputs = OnboardingOshiSelectionLogic.accountSetupInputs(from: drafts)

        XCTAssertEqual(inputs.map(\.priority), [1, 2])
        XCTAssertEqual(inputs.map(\.kind), [.box, .specific])
        XCTAssertEqual(inputs.first?.groupID, twice.id)
        XCTAssertEqual(inputs.last?.groupID, ive.id)
    }
}
