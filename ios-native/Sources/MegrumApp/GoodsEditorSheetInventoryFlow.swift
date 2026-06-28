import Foundation
import MegrumCore

extension GoodsEditorSheet {
    var canSaveInventoryCreateMetas: Bool {
        !GoodsInventoryCreateValidation.hasMissingPhotos(metas: createMetas, photos: createPhotos)
            && !inventoryCreateInputs().isEmpty
            && !appState.isCreatingGoodsEntry
    }

    var selectedCreateMetas: [GoodsCreateMetaDraft] {
        createMetas.filter { selectedCreateMetaIDs.contains($0.id) }
    }

    func toggleCreateMetaSelection(_ metaID: UUID) {
        if selectedCreateMetaIDs.contains(metaID) {
            selectedCreateMetaIDs.remove(metaID)
        } else {
            selectedCreateMetaIDs.insert(metaID)
        }
        createError = nil
    }

    func selectAllCreateMetas() {
        selectedCreateMetaIDs = Set(createMetas.map(\.id))
    }

    func clearCreateMetaSelection() {
        selectedCreateMetaIDs = []
    }

    func pruneCreateMetaSelection() {
        let validIDs = Set(createMetas.map(\.id))
        selectedCreateMetaIDs = selectedCreateMetaIDs.intersection(validIDs)
    }

    func applyCreateBulkMember(_ memberID: UUID?) {
        guard !selectedCreateMetaIDs.isEmpty else {
            createError = "メンバーを設定する画像を選択してください"
            return
        }
        guard memberID == nil || GoodsEditorMemberScope.canUseMemberID(
            memberID,
            group: selectedGroup,
            members: appState.oshiCharacters
        ) else {
            createError = "この推しに登録できないメンバーです"
            return
        }
        createMetas = createMetas.map { meta in
            guard selectedCreateMetaIDs.contains(meta.id) else {
                return meta
            }
            var next = meta
            next.memberID = memberID
            return next
        }
        createError = nil
    }

    func showCreateBulkTagSheet() {
        guard !selectedCreateMetaIDs.isEmpty else {
            createError = "シリーズを設定する画像を選択してください"
            return
        }
        createError = nil
        resetImageSeriesSuggestions()
        isShowingCreateBulkTagSelectionSheet = true
    }

    func applyCreateBulkTag(_ tagName: String) {
        guard !selectedCreateMetaIDs.isEmpty else {
            createError = "シリーズを設定する画像を選択してください"
            return
        }
        createMetas = createMetas.map { meta in
            guard selectedCreateMetaIDs.contains(meta.id) else {
                return meta
            }
            var next = meta
            next.addTag(tagName)
            return next
        }
        createError = nil
    }

    func removeCreateMetaTag(metaID: UUID, tagName: String) {
        guard let index = createMetas.firstIndex(where: { $0.id == metaID }) else {
            return
        }
        createMetas[index].removeTag(tagName)
        createError = nil
    }

    func inventoryCreateInputs() -> [GoodsEntryInput] {
        GoodsInventoryCreateInputBuilder.inputs(
            metas: createMetas,
            photos: createPhotos,
            sharedDraft: draft,
            groupName: selectedGroup?.name,
            members: scopedOshiCharacters,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    func saveInventoryCreateFlow() async {
        guard canAdvanceFromCreateCommon else {
            createError = "グループとグッズ種別を選択してください"
            return
        }
        guard !GoodsInventoryCreateValidation.hasMissingPhotos(metas: createMetas, photos: createPhotos) else {
            createError = "登録する画像を選んでください"
            return
        }
        guard !GoodsInventoryCreateValidation.hasMissingMemberAssignments(
            metas: createMetas,
            requiresMemberAssignment: inventoryCreateAllowsMemberAssignment
        ) else {
            createError = "メンバーがある推しは、すべての画像にメンバーを登録してください"
            return
        }
        let inputs = inventoryCreateInputs()
        guard !inputs.isEmpty else {
            createError = "登録するアイテムがありません"
            return
        }

        createError = nil
        var savedCount = 0
        var createdItems: [GoodsItem] = []
        for input in inputs {
            guard let created = await appState.createGoodsEntryRecord(input) else {
                let base = appState.errorMessage ?? "保存に失敗しました"
                createError = savedCount > 0 ? "\(savedCount)件は登録済みです。\(base)" : base
                return
            }
            if input.kind == .inventory {
                createdItems.append(created)
            }
            savedCount += 1
        }
        if !createdItems.isEmpty {
            onCreatedInventoryItems(createdItems)
        }
        dismiss()
    }
}
