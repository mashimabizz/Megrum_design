import Foundation
import MegrumCore
import SwiftUI

extension OshiSettingsScreen {
    func closeScreen() {
        dismiss()
    }

    func showMasterSheet() {
        showsMasterSheet = true
    }

    func toggleExpandedGroup(_ group: OshiSettingsGroupDraft) {
        withAnimation(.snappy(duration: 0.2)) {
            expandedGroupKey = expandedGroupKey == group.key ? nil : group.key
        }
    }

    func addMasterGroupTapped(_ group: OshiGroup) {
        Task { await addMasterGroup(group) }
    }

    func addMasterGroupsTapped(_ selectedGroups: [OshiGroup]) {
        Task { await addMasterGroups(selectedGroups) }
    }

    func removeGroupTapped(_ group: OshiSettingsGroupDraft) {
        Task { await removeGroup(group) }
    }

    func removeMemberTapped(_ member: OshiSettingsMemberDraft, from group: OshiSettingsGroupDraft) {
        Task { await removeMember(member, from: group) }
    }

    func addMemberTapped(_ character: OshiCharacter, to group: OshiSettingsGroupDraft) {
        Task { await addMember(character, to: group) }
    }

    func requestMemberTapped(_ group: OshiSettingsGroupDraft) {
        requestSheet = .member(OshiMemberRequestContext(group: group))
    }

    func submitOshiRequestTapped(_ payload: OshiRequestSheetPayload) {
        Task { await submitOshiRequest(payload) }
    }

    func submitMemberRequestTapped(_ payload: OshiMemberRequestSheetPayload, context: OshiMemberRequestContext) {
        Task { await submitMemberRequest(payload, context: context) }
    }

    func prepare() async {
        isLoading = true
        errorMessage = nil
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        await appState.loadUserOshiSelections()

        let selectedGroupIDs = appState.userOshiSelections.compactMap(\.groupID).uniqued()
        for groupID in selectedGroupIDs {
            await loadCharactersIfNeeded(groupID: groupID)
        }
        groups = OshiSettingsGroupDraft.build(
            selections: appState.userOshiSelections,
            masterGroups: appState.oshiGroups
        )
        isLoading = false
    }

    func loadCharactersIfNeeded(groupID: UUID) async {
        guard charactersByGroupID[groupID] == nil,
              let group = appState.oshiGroups.first(where: { $0.id == groupID })
        else {
            return
        }
        await appState.loadOshiCharacters(group: group)
        charactersByGroupID[groupID] = appState.oshiCharacters
    }

    func addMasterGroup(_ group: OshiGroup) async {
        showsMasterSheet = false
        guard groups.contains(where: { $0.groupID == group.id }) == false else {
            noticeMessage = "すでに追加済みです。"
            return
        }
        await loadCharactersIfNeeded(groupID: group.id)
        var next = groups
        next.append(OshiSettingsGroupDraft(masterGroup: group, priority: next.count + 1))
        await persist(next, success: "推しを追加しました。")
    }

    func addMasterGroups(_ selectedGroups: [OshiGroup]) async {
        showsMasterSheet = false
        let existingIDs = Set(groups.compactMap(\.groupID))
        let groupsToAdd = selectedGroups.filter { !existingIDs.contains($0.id) }
        guard !groupsToAdd.isEmpty else {
            noticeMessage = "すでに追加済みです。"
            return
        }

        for group in groupsToAdd {
            await loadCharactersIfNeeded(groupID: group.id)
        }

        var next = groups
        for group in groupsToAdd {
            next.append(OshiSettingsGroupDraft(masterGroup: group, priority: next.count + 1))
        }

        let success = groupsToAdd.count == 1 ? "推しを追加しました。" : "\(groupsToAdd.count)件の推しを追加しました。"
        await persist(next, success: success)
    }

    func removeGroup(_ group: OshiSettingsGroupDraft) async {
        await persist(
            groups.filter { $0.key != group.key },
            success: "推し設定から削除しました。"
        )
    }

    func removeMember(_ member: OshiSettingsMemberDraft, from group: OshiSettingsGroupDraft) async {
        var next = groups
        guard let index = next.firstIndex(where: { $0.key == group.key }) else {
            return
        }
        next[index].members.removeAll { $0.id == member.id }
        await persist(next, success: "推しメンバーを外しました。")
    }

    func addMember(_ character: OshiCharacter, to group: OshiSettingsGroupDraft) async {
        var next = groups
        guard let index = next.firstIndex(where: { $0.key == group.key }) else {
            return
        }
        guard next[index].members.contains(where: { $0.characterID == character.id }) == false else {
            return
        }
        next[index].members.append(OshiSettingsMemberDraft(character: character))
        await persist(next, success: "推しメンバーを追加しました。")
    }

    func submitOshiRequest(_ payload: OshiRequestSheetPayload) async {
        requestSheet = nil
        guard let requestID = await appState.createOshiRequest(
            OshiRequestCreateInput(
                requestedName: payload.name,
                requestedKind: payload.kind,
                requestedGenreID: payload.genreID,
                note: payload.note
            )
        ) else {
            errorMessage = appState.errorMessage
            return
        }
        var next = groups
        next.append(
            OshiSettingsGroupDraft(
                requestID: requestID,
                name: payload.name,
                pending: true,
                priority: next.count + 1
            )
        )
        await persist(next, success: "追加リクエストを送信し、推し設定に仮登録しました。")
    }

    func submitMemberRequest(
        _ payload: OshiMemberRequestSheetPayload,
        context: OshiMemberRequestContext
    ) async {
        requestSheet = nil
        let requestedName = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedName.isEmpty else {
            return
        }
        guard context.canCreateCharacterRequest else {
            errorMessage = "対象の推しを確認できませんでした"
            return
        }
        guard let groupIndex = groups.firstIndex(where: { $0.key == context.groupKey }) else {
            errorMessage = "対象の推しを確認できませんでした"
            return
        }
        guard groups[groupIndex].members.contains(where: { member in
            member.name.compare(requestedName, options: [.caseInsensitive, .widthInsensitive, .diacriticInsensitive]) == .orderedSame
        }) == false else {
            noticeMessage = "すでに追加済みです。"
            return
        }
        guard let requestID = await appState.createCharacterRequest(
            CharacterRequestCreateInput(
                groupID: context.groupID,
                oshiRequestID: context.oshiRequestID,
                requestedName: requestedName,
                note: payload.note
            )
        ) else {
            errorMessage = appState.errorMessage
            return
        }

        var next = groups
        next[groupIndex].members.append(
            OshiSettingsMemberDraft(
                characterRequestID: requestID,
                name: requestedName,
                pending: true
            )
        )
        await persist(next, success: OshiSettingsPresentationText.memberRequestSubmitSuccess)
    }

    func persist(_ nextGroups: [OshiSettingsGroupDraft], success: String) async {
        isSaving = true
        errorMessage = nil
        let inputs = OshiSettingsGroupDraft.accountSetupInputs(from: nextGroups)
        let saved = await appState.saveOshiSelections(inputs)
        if saved {
            withAnimation(.snappy(duration: 0.2)) {
                groups = nextGroups.reprioritized()
            }
            noticeMessage = success
        } else {
            errorMessage = appState.errorMessage
        }
        isSaving = false
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        reduce(into: []) { result, element in
            if !result.contains(element) {
                result.append(element)
            }
        }
    }
}
