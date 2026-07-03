import MegrumCore

extension GoodsEditorSheet {
    func save() async {
        lastSaveFailure = nil
        let saved: Bool
        var createdItems: [GoodsItem] = []
        switch draft.mode {
        case .create:
            guard let input = draft.createInput(
                groupName: selectedGroup?.name,
                memberName: selectedMember?.name,
                goodsTypeName: selectedGoodsType?.name
            ) else {
                return
            }
            if let created = await appState.createGoodsEntryRecord(input) {
                saved = true
                createdItems = [created]
            } else {
                saved = false
            }
        case .edit:
            guard let itemID = draft.existingItemID,
                  let input = draft.updateInput(
                    groupName: selectedGroup?.name,
                    memberName: selectedMember?.name,
                    goodsTypeName: selectedGoodsType?.name
                  )
            else {
                return
            }
            saved = await appState.updateGoodsEntry(itemID: itemID, kind: draft.entryKind, input: input)
        case .readonly:
            return
        }
        if saved {
            if !createdItems.isEmpty {
                onCreatedInventoryItems(createdItems)
            }
            dismiss()
        } else {
            lastSaveFailure = GoodsEditorSaveFailure.make(draft: draft, appMessage: appState.errorMessage)
        }
    }

    func deleteInventoryItem() async {
        guard draft.entryKind == .inventory,
              draft.mode == .edit,
              let itemID = draft.existingItemID,
              !isItemReadOnly
        else {
            return
        }
        let deleted = await appState.archiveGoodsItem(itemID)
        if deleted {
            dismiss()
        } else {
            deleteErrorMessage = appState.errorMessage ?? "通信状況を確認してからもう一度お試しください。"
        }
    }
}
