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
        let requestID = UUID(uuidString: "10000000-0000-0000-0000-000000000024")!
        let characterRequestID = UUID(uuidString: "10000000-0000-0000-0000-000000000025")!
        let drafts = [
            OnboardingOshiDraft(groupID: twice.id, groupName: twice.name, characterID: nil, characterName: nil),
            OnboardingOshiDraft(
                groupID: ive.id,
                groupName: ive.name,
                characterID: UUID(uuidString: "10000000-0000-0000-0000-000000000023")!,
                characterName: "LIZ"
            ),
            OnboardingOshiDraft(
                oshiRequestID: requestID,
                requestedName: "新しい推し",
                characterRequestID: characterRequestID,
                requestedCharacterName: "新しいメンバー"
            )
        ]

        let inputs = OnboardingOshiSelectionLogic.accountSetupInputs(from: drafts)

        XCTAssertEqual(inputs.map(\.priority), [1, 2, 3])
        XCTAssertEqual(inputs.map(\.kind), [.box, .specific, .specific])
        XCTAssertEqual(inputs.first?.groupID, twice.id)
        XCTAssertEqual(inputs[1].groupID, ive.id)
        XCTAssertNil(inputs.last?.groupID)
        XCTAssertEqual(inputs.last?.oshiRequestID, requestID)
        XCTAssertEqual(inputs.last?.characterRequestID, characterRequestID)
        XCTAssertEqual(inputs.last?.kind, .specific)
        XCTAssertEqual(drafts.last?.displayName, "新しい推し / 新しいメンバー（申請中）")
    }

    func testMemberRequestDraftsFilterByPendingOshiRequest() {
        let target = OnboardingOshiMemberTarget(
            oshiRequestID: UUID(uuidString: "10000000-0000-0000-0000-000000000041")!,
            name: "新しい作品"
        )
        let otherRequestID = UUID(uuidString: "10000000-0000-0000-0000-000000000042")!
        let drafts = [
            OnboardingOshiDraft(oshiRequestID: target.oshiRequestID, requestedName: target.name),
            OnboardingOshiDraft(
                oshiRequestID: target.oshiRequestID,
                requestedName: target.name,
                characterRequestID: UUID(uuidString: "10000000-0000-0000-0000-000000000043")!,
                requestedCharacterName: "主人公"
            ),
            OnboardingOshiDraft(
                oshiRequestID: otherRequestID,
                requestedName: "別の作品",
                characterRequestID: UUID(uuidString: "10000000-0000-0000-0000-000000000044")!,
                requestedCharacterName: "別キャラ"
            )
        ]

        let memberDrafts = OnboardingOshiSelectionLogic.memberRequestDrafts(for: target, in: drafts)

        XCTAssertEqual(memberDrafts.map(\.displayName), ["新しい作品 / 主人公（申請中）"])
    }

    func testRequestedMemberTargetsIncludeOnlyGroupAndWorkRequests() {
        let groupRequestID = UUID(uuidString: "10000000-0000-0000-0000-000000000051")!
        let soloRequestID = UUID(uuidString: "10000000-0000-0000-0000-000000000052")!
        let drafts = [
            OnboardingOshiDraft(
                oshiRequestID: groupRequestID,
                requestedName: "新しい作品",
                requestedKind: .work
            ),
            OnboardingOshiDraft(
                oshiRequestID: soloRequestID,
                requestedName: "ソロの人",
                requestedKind: .solo
            )
        ]

        let targets = OnboardingOshiSelectionLogic.requestedMemberTargets(from: drafts)

        XCTAssertEqual(targets.map(\.name), ["新しい作品"])
        XCTAssertEqual(targets.first?.requestContext.oshiRequestID, groupRequestID)
        XCTAssertNil(targets.first?.requestContext.groupID)
    }

    func testSeedingWholeGroupSelectionsKeepsRequestsAndRemovesUnselectedGroups() {
        let selectedSolo = OshiGroup(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000061")!,
            name: "ソロアーティスト",
            kind: .solo
        )
        let unselectedGroup = OshiGroup(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000062")!,
            name: "未選択グループ"
        )
        let requestID = UUID(uuidString: "10000000-0000-0000-0000-000000000063")!
        let drafts = [
            OnboardingOshiDraft(
                groupID: unselectedGroup.id,
                groupName: unselectedGroup.name,
                characterID: UUID(uuidString: "10000000-0000-0000-0000-000000000064")!,
                characterName: "未選択メンバー"
            ),
            OnboardingOshiDraft(
                oshiRequestID: requestID,
                requestedName: "追加リクエスト"
            )
        ]

        let seeded = OnboardingOshiSelectionLogic.draftsAfterSeedingWholeGroupSelections(
            selectedGroups: [selectedSolo],
            currentDrafts: drafts
        )

        XCTAssertEqual(seeded.map(\.displayName), ["追加リクエスト（申請中）", "ソロアーティスト 全体"])
        XCTAssertEqual(seeded.first?.oshiRequestID, requestID)
        XCTAssertTrue(OnboardingOshiSelectionLogic.isWholeGroupSelected(selectedSolo, in: seeded))
        XCTAssertFalse(OnboardingOshiSelectionLogic.groupHasSelection(unselectedGroup, in: seeded))
    }

    func testDraftsFromSavedSelectionsKeepSavedPriorityOrder() {
        let twice = OshiGroup(id: UUID(uuidString: "10000000-0000-0000-0000-000000000031")!, name: "TWICE")
        let ive = OshiGroup(id: UUID(uuidString: "10000000-0000-0000-0000-000000000032")!, name: "IVE")
        let sana = OshiCharacter(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000033")!,
            groupID: twice.id,
            name: "SANA"
        )
        let selections = [
            UserOshiSelection(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000034")!,
                userID: UUID(uuidString: "10000000-0000-0000-0000-000000000035")!,
                groupID: ive.id,
                characterID: nil,
                kind: .box,
                priority: 2
            ),
            UserOshiSelection(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000036")!,
                userID: UUID(uuidString: "10000000-0000-0000-0000-000000000035")!,
                groupID: twice.id,
                characterID: sana.id,
                kind: .specific,
                priority: 1
            )
        ]

        let drafts = OnboardingOshiSelectionLogic.drafts(
            from: selections,
            groups: [twice, ive],
            characters: [sana]
        )

        XCTAssertEqual(drafts.map(\.displayName), ["TWICE / SANA", "IVE 全体"])
        XCTAssertEqual(drafts.map(\.kind), [.specific, .box])
    }

    func testAccountSetupModeProvidesCompletionGuidance() {
        XCTAssertEqual(AccountSetupMode.onboarding.completionTitle, "初回設定が完了しました")
        XCTAssertTrue(AccountSetupMode.onboarding.completionFootnote.contains("ホームへ進みます"))
        XCTAssertEqual(AccountSetupMode.edit.completionTitle, "プロフィールを更新しました")
        XCTAssertTrue(AccountSetupMode.edit.completionMessage.contains("推し設定"))
    }
}
