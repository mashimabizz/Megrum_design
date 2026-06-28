@testable import MegrumApp
import MegrumCore
import XCTest

final class OshiSettingsDraftTests: XCTestCase {
    func testOshiSettingsGroupSummaryOmitsBoxSelectionCopy() {
        let group = OshiSettingsGroupDraft(
            masterGroup: OshiGroup(id: uuid("10000000-0000-0000-0000-000000000201"), name: "BTS"),
            priority: 1
        )

        XCTAssertNil(OshiSettingsPresentationText.groupSummary(for: group))
    }

    func testOshiSettingsGroupSummaryShowsSpecificMemberCount() {
        let group = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000202"), name: "TWICE")
        let momo = OshiCharacter(
            id: uuid("10000000-0000-0000-0000-000000000203"),
            groupID: group.id,
            name: "モモ"
        )
        var draft = OshiSettingsGroupDraft(masterGroup: group, priority: 1)
        draft.members.append(OshiSettingsMemberDraft(character: momo))

        XCTAssertEqual(OshiSettingsPresentationText.groupSummary(for: draft), "推しメンバー 1人")
    }

    func testSoloOshiGroupDoesNotSupportMemberSelection() {
        let solo = OshiGroup(
            id: uuid("10000000-0000-0000-0000-000000000209"),
            name: "キム・スヒョン",
            kind: .solo
        )
        let draft = OshiSettingsGroupDraft(masterGroup: solo, priority: 1)

        XCTAssertFalse(draft.supportsMemberSelection)
        XCTAssertNil(OshiSettingsPresentationText.groupSummary(for: draft))
        XCTAssertEqual(
            OshiSettingsGroupDraft.accountSetupInputs(from: [draft]).first?.kind,
            .box
        )
    }

    func testOshiSettingsMemberChipCopyDoesNotPrefixPlus() {
        let group = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000204"), name: "TWICE")
        let character = OshiCharacter(
            id: uuid("10000000-0000-0000-0000-000000000205"),
            groupID: group.id,
            name: "サナ"
        )

        XCTAssertEqual(OshiSettingsPresentationText.availableMemberTitle(character), "サナ")
        XCTAssertFalse(OshiSettingsPresentationText.availableMemberTitle(character).hasPrefix("+"))
        XCTAssertEqual(OshiSettingsPresentationText.memberToggleTitle(isExpanded: false), "追加")
        XCTAssertEqual(OshiSettingsPresentationText.memberToggleTitle(isExpanded: true), "閉じる")
    }

    func testOshiSettingsDeleteConfirmationCopy() {
        XCTAssertEqual(OshiSettingsPresentationText.removeGroupConfirmationTitle, "本当に削除しますか？")
        XCTAssertEqual(OshiSettingsPresentationText.removeGroupConfirmationAction, "削除する")
    }

    func testMemberRequestCopyAndPendingMemberTitle() {
        let requestID = uuid("10000000-0000-0000-0000-000000000206")
        let member = OshiSettingsMemberDraft(
            characterRequestID: requestID,
            name: "ツウィ",
            pending: true
        )

        XCTAssertEqual(OshiSettingsPresentationText.memberRequestTagTitle, "追加リクエスト")
        XCTAssertEqual(OshiSettingsPresentationText.memberRequestSheetTitle, "メンバー追加リクエスト")
        XCTAssertEqual(OshiSettingsPresentationText.selectedMemberTitle(member), "ツウィ（承認待ち）")
    }

    func testMemberRequestContextSupportsMasterAndPendingGroups() {
        let group = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000207"), name: "TWICE")
        let masterContext = OshiMemberRequestContext(group: OshiSettingsGroupDraft(masterGroup: group, priority: 1))
        let requestID = uuid("10000000-0000-0000-0000-000000000208")
        let pendingContext = OshiMemberRequestContext(
            group: OshiSettingsGroupDraft(requestID: requestID, name: "承認待ちグループ", pending: true, priority: 2)
        )

        XCTAssertEqual(masterContext.groupID, group.id)
        XCTAssertNil(masterContext.oshiRequestID)
        XCTAssertTrue(masterContext.canCreateCharacterRequest)
        XCTAssertNil(pendingContext.groupID)
        XCTAssertEqual(pendingContext.oshiRequestID, requestID)
        XCTAssertTrue(pendingContext.canCreateCharacterRequest)
    }

    func testMasterSelectSheetUsesCompactTagLayoutMetrics() {
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.candidateTagMinimumWidth, 44)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.candidateTagMinHeight, 44)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.candidateTagHorizontalPadding, 12)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.candidateTagSpacing, 8)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.registerButtonHeight, 54)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.genreSegmentHeight, 38)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.genreSegmentMinWidth, 72)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.searchHeight, 54)
        XCTAssertEqual(OshiMasterSelectLayoutMetrics.selectedActionExtraPadding, 74)
        XCTAssertLessThan(OshiMasterSelectLayoutMetrics.candidateTagMinimumWidth, 68)
        XCTAssertLessThan(OshiMasterSelectLayoutMetrics.candidateTagMinHeight, 74)
        XCTAssertLessThan(OshiMasterSelectLayoutMetrics.genreSegmentHeight, 46)
        XCTAssertLessThan(OshiMasterSelectLayoutMetrics.bottomContentPadding, 156)
    }

    func testMasterSelectSheetShowsMultipleRegistrationCountCopy() {
        XCTAssertEqual(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: 1), "推しを登録")
        XCTAssertEqual(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: 2), "2件の推しを登録")
        XCTAssertEqual(OshiSettingsPresentationText.masterSelectionCountTitle(selectionCount: 2), "2件選択中")
    }

    func testOshiRequestSheetUsesFixedFooterMetrics() {
        XCTAssertEqual(OshiRequestSheetLayoutMetrics.submitButtonHeight, 58)
        XCTAssertGreaterThanOrEqual(OshiRequestSheetLayoutMetrics.scrollBottomPadding, 100)
    }

    func testMasterSelectionReducerTogglesMultipleGroupsAndKeepsLockedIDs() {
        let lockedID = uuid("10000000-0000-0000-0000-000000000001")
        let btsID = uuid("10000000-0000-0000-0000-000000000002")
        let twiceID = uuid("10000000-0000-0000-0000-000000000003")

        var selected: Set<UUID> = []
        selected = OshiMasterSelectionReducer.toggling(groupID: btsID, selectedIDs: selected, lockedIDs: [lockedID])
        selected = OshiMasterSelectionReducer.toggling(groupID: twiceID, selectedIDs: selected, lockedIDs: [lockedID])
        selected = OshiMasterSelectionReducer.toggling(groupID: lockedID, selectedIDs: selected, lockedIDs: [lockedID])

        XCTAssertEqual(selected, [btsID, twiceID])

        selected = OshiMasterSelectionReducer.toggling(groupID: btsID, selectedIDs: selected, lockedIDs: [lockedID])

        XCTAssertEqual(selected, [twiceID])
    }

    func testMasterSelectionReducerReturnsGroupsInMasterListOrder() {
        let bts = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000011"), name: "BTS")
        let snowMan = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000012"), name: "Snow Man")
        let twice = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000013"), name: "TWICE")

        let selected = OshiMasterSelectionReducer.selectedGroups(
            from: [bts, snowMan, twice],
            selectedIDs: [twice.id, bts.id]
        )

        XCTAssertEqual(selected.map(\.name), ["BTS", "TWICE"])
    }

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

    func testBuildKeepsPendingMemberRequests() {
        let userID = uuid("10000000-0000-0000-0000-000000000301")
        let groupID = uuid("10000000-0000-0000-0000-000000000302")
        let requestID = uuid("10000000-0000-0000-0000-000000000303")
        let group = OshiGroup(id: groupID, name: "TWICE")
        let selections = [
            UserOshiSelection(
                id: uuid("10000000-0000-0000-0000-000000000304"),
                userID: userID,
                groupID: groupID,
                characterID: nil,
                kind: .specific,
                priority: 1,
                characterRequestID: requestID,
                characterRequestName: "ナヨン"
            )
        ]

        let drafts = OshiSettingsGroupDraft.build(selections: selections, masterGroups: [group])

        XCTAssertEqual(drafts.first?.name, "TWICE")
        XCTAssertEqual(drafts.first?.members.first?.characterRequestID, requestID)
        XCTAssertEqual(drafts.first?.members.first?.name, "ナヨン")
        XCTAssertTrue(drafts.first?.members.first?.pending ?? false)
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

    func testAccountSetupInputsPreservesPendingMemberRequestID() {
        let group = OshiGroup(id: uuid("10000000-0000-0000-0000-000000000401"), name: "TWICE")
        let requestID = uuid("10000000-0000-0000-0000-000000000402")
        var draft = OshiSettingsGroupDraft(masterGroup: group, priority: 1)
        draft.members.append(
            OshiSettingsMemberDraft(
                characterRequestID: requestID,
                name: "ジヒョ",
                pending: true
            )
        )

        let inputs = OshiSettingsGroupDraft.accountSetupInputs(from: [draft])

        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(inputs[0].groupID, group.id)
        XCTAssertNil(inputs[0].characterID)
        XCTAssertEqual(inputs[0].characterRequestID, requestID)
        XCTAssertEqual(inputs[0].kind, .specific)
    }

    private func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
