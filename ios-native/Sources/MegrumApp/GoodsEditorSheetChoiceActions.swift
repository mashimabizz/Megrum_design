import Foundation
import MegrumCore

extension GoodsEditorSheet {
    func loadChoices() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        // グループ選択シートの初期カテゴリ「自分の推し」に使う。
        // 未ロードだと myOshiGroupIDs が空になり、ホーム検索フィルタと
        // 同じ「自分の推しを最初に表示」が効かない。
        if appState.userOshiSelections.isEmpty {
            await appState.loadUserOshiSelections()
        }
        assignDefaultsIfNeeded()
        await loadMembers(for: draft.groupID)
        isTagFieldFocused = false
    }

    func assignDefaultsIfNeeded() {
        guard draft.mode == .create, !didAssignDefaults else {
            return
        }
        let skipsGroupDefault = usesInventoryCreateFlow
        if draft.groupID == nil && !skipsGroupDefault {
            draft.groupID = appState.oshiGroups.first?.id
        }
        if draft.goodsTypeID == nil {
            draft.goodsTypeID = appState.goodsTypes.first?.id
        }
        didAssignDefaults = (skipsGroupDefault || draft.groupID != nil) && draft.goodsTypeID != nil
    }

    func loadMembers(for groupID: UUID?) async {
        guard let groupID,
              let group = appState.oshiGroups.first(where: { $0.id == groupID })
        else {
            draft.memberID = nil
            resetCreateMetaMembers()
            await appState.loadOshiCharacters(group: nil)
            return
        }
        guard group.supportsMemberSelection else {
            draft.memberID = nil
            resetCreateMetaMembers()
            await appState.loadOshiCharacters(group: nil)
            return
        }
        await appState.loadOshiCharacters(group: group)
        if let memberID = draft.memberID,
           !GoodsEditorMemberScope.canUseMemberID(memberID, group: group, members: appState.oshiCharacters) {
            draft.memberID = nil
        }
    }

    func addCurrentTag() {
        guard !isItemReadOnly else {
            return
        }
        draft.addTag(tagDraft)
        tagDraft = ""
    }

    func addSuggestedTag(_ tag: String) {
        guard !isItemReadOnly else {
            return
        }
        draft.addTag(tag)
    }

    func addTagFromSelectionSheet(_ tag: String) {
        guard !isItemReadOnly else {
            return
        }
        draft.addTag(tag)
    }

    func showCreateOshiMasterSheet() {
        showsCreateOshiMasterSheet = true
    }

    func selectCreateOshiGroup(_ group: OshiGroup) {
        draft.groupID = group.id
        draft.memberID = nil
        createError = nil
        showsCreateOshiMasterSheet = false
        Task {
            await loadMembers(for: group.id)
        }
    }

    func submitCreateOshiRequest(_ payload: OshiRequestSheetPayload) {
        Task {
            await submitCreateOshiRequestAsync(payload)
        }
    }

    func submitCreateOshiRequestAsync(_ payload: OshiRequestSheetPayload) async {
        createOshiRequestSheet = nil
        guard await appState.createOshiRequest(
            OshiRequestCreateInput(
                requestedName: payload.name,
                requestedKind: payload.kind,
                requestedGenreID: payload.genreID,
                note: payload.note
            )
        ) != nil else {
            createError = appState.errorMessage ?? "追加リクエストを送信できませんでした"
            return
        }
        createError = nil
    }

    func removeTag(_ tag: String) {
        draft.removeTag(tag)
    }
}
