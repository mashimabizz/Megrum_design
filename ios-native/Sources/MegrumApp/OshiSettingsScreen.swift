import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var groups: [OshiSettingsGroupDraft] = []
    @State private var charactersByGroupID: [UUID: [OshiCharacter]] = [:]
    @State private var expandedGroupKey: String?
    @State private var isSaving = false
    @State private var isLoading = false
    @State private var noticeMessage: String?
    @State private var errorMessage: String?
    @State private var showsMasterSheet = false
    @State private var requestSheet: OshiRequestSheetState?

    var body: some View {
        OshiSettingsMainContent(
            groups: groups,
            isLoading: isLoading || appState.isLoadingUserOshiSelections || appState.isLoadingOshiGroups,
            isSaving: isSaving,
            errorMessage: errorMessage,
            noticeMessage: noticeMessage,
            expandedGroupKey: expandedGroupKey,
            availableCharacters: availableCharacters(for:),
            onBack: closeScreen,
            onShowMasterSheet: showMasterSheet,
            onToggleExpanded: toggleExpandedGroup,
            onRemoveGroup: removeGroupTapped,
            onRemoveMember: removeMemberTapped(_:from:),
            onAddMember: addMemberTapped(_:to:)
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .sheet(isPresented: $showsMasterSheet) {
            OshiMasterSelectSheet(
                genres: appState.oshiGenres,
                groups: appState.oshiGroups,
                selectedGroupIDs: Set(groups.compactMap(\.groupID)),
                charactersByGroupID: charactersByGroupID,
                onClose: { showsMasterSheet = false },
                onRequest: { query in
                    showsMasterSheet = false
                    requestSheet = .oshi(initialName: query)
                },
                onSelect: addMasterGroupTapped
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $requestSheet) { state in
            OshiRequestSheet(
                state: state,
                genres: appState.oshiGenres,
                onClose: { requestSheet = nil },
                onSubmit: { submitRequestTapped($0, state: state) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .task {
            await prepare()
        }
    }

    private func closeScreen() {
        dismiss()
    }

    private func showMasterSheet() {
        showsMasterSheet = true
    }

    private func toggleExpandedGroup(_ group: OshiSettingsGroupDraft) {
        withAnimation(.snappy(duration: 0.2)) {
            expandedGroupKey = expandedGroupKey == group.key ? nil : group.key
        }
    }

    private func addMasterGroupTapped(_ group: OshiGroup) {
        Task { await addMasterGroup(group) }
    }

    private func removeGroupTapped(_ group: OshiSettingsGroupDraft) {
        Task { await removeGroup(group) }
    }

    private func removeMemberTapped(_ member: OshiSettingsMemberDraft, from group: OshiSettingsGroupDraft) {
        Task { await removeMember(member, from: group) }
    }

    private func addMemberTapped(_ character: OshiCharacter, to group: OshiSettingsGroupDraft) {
        Task { await addMember(character, to: group) }
    }

    private func submitRequestTapped(_ payload: OshiRequestSheetPayload, state: OshiRequestSheetState) {
        Task { await submitRequest(payload, state: state) }
    }

    private func prepare() async {
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

    private func availableCharacters(for group: OshiSettingsGroupDraft) -> [OshiCharacter] {
        guard let groupID = group.groupID else {
            return []
        }
        let selectedIDs = Set(group.members.compactMap(\.characterID))
        return (charactersByGroupID[groupID] ?? [])
            .filter { !selectedIDs.contains($0.id) }
            .sorted { $0.displayOrder == $1.displayOrder ? $0.name < $1.name : $0.displayOrder < $1.displayOrder }
    }

    private func loadCharactersIfNeeded(groupID: UUID) async {
        guard charactersByGroupID[groupID] == nil,
              let group = appState.oshiGroups.first(where: { $0.id == groupID })
        else {
            return
        }
        await appState.loadOshiCharacters(group: group)
        charactersByGroupID[groupID] = appState.oshiCharacters
    }

    private func addMasterGroup(_ group: OshiGroup) async {
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

    private func removeGroup(_ group: OshiSettingsGroupDraft) async {
        await persist(
            groups.filter { $0.key != group.key },
            success: "推し設定から削除しました。"
        )
    }

    private func removeMember(_ member: OshiSettingsMemberDraft, from group: OshiSettingsGroupDraft) async {
        var next = groups
        guard let index = next.firstIndex(where: { $0.key == group.key }) else {
            return
        }
        next[index].members.removeAll { $0.id == member.id }
        await persist(next, success: "推しメンバーを外しました。")
    }

    private func addMember(_ character: OshiCharacter, to group: OshiSettingsGroupDraft) async {
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

    private func submitRequest(_ payload: OshiRequestSheetPayload, state: OshiRequestSheetState) async {
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

    private func persist(_ nextGroups: [OshiSettingsGroupDraft], success: String) async {
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
