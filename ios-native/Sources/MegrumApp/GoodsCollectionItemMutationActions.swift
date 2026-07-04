import MegrumCore
import SwiftUI

extension GoodsCollectionScreen {
    func hideItem(_ item: GoodsItem) {
        guard let appState else {
            return
        }
        Task {
            _ = await appState.archiveGoodsItem(item.id)
        }
    }

    func deleteItem(_ item: GoodsItem) {
        guard let appState else {
            return
        }
        Task {
            _ = await appState.deleteGoodsItem(item.id)
        }
    }

    func requestSingleDelete(_ item: GoodsItem) {
        pendingSingleDeleteItem = item
        isConfirmingBulkDelete = false
        showDeleteConfirmation()
    }

    func requestBulkDelete() {
        guard !selectedItemIDs.isEmpty else {
            return
        }
        pendingSingleDeleteItem = nil
        isConfirmingBulkDelete = true
        showDeleteConfirmation()
    }

    func showDeleteConfirmation() {
        canConfirmDelete = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if hasPendingDeleteConfirmation {
                canConfirmDelete = true
            }
        }
    }

    func dismissDeleteConfirmation() {
        pendingSingleDeleteItem = nil
        isConfirmingBulkDelete = false
        canConfirmDelete = false
    }

    func confirmPendingDelete() {
        if let pendingSingleDeleteItem {
            deleteItem(pendingSingleDeleteItem)
        } else if isConfirmingBulkDelete {
            deleteSelectedItems()
        }
        dismissDeleteConfirmation()
    }

    func openQuickActionPanel(for item: GoodsItem) {
        quickActionItem = item
        Task {
            await loadCharactersIfNeeded(for: item)
        }
    }

    func beginSelection(with item: GoodsItem) {
        guard isOwnedItem(item) else {
            return
        }
        quickActionItem = nil
        selectedItemIDs = [item.id]
    }

    func toggleSelection(_ item: GoodsItem) {
        guard isOwnedItem(item) else {
            return
        }
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    func isOwnedItem(_ item: GoodsItem) -> Bool {
        guard let viewerID = appState?.viewer?.id else {
            return false
        }
        return item.ownerID == viewerID
    }

    func performQuickAction(_ action: GoodsQuickActionKind) {
        guard let item = quickActionItem else {
            return
        }
        quickActionItem = nil

        switch action {
        case .tag:
            bulkTagRoute = GoodsBulkTagRoute(itemIDs: [item.id])
        case .share:
            presentSharePrompt(for: [item])
        case .delete:
            requestSingleDelete(item)
        }
    }

    func moveItem(_ item: GoodsItem, to status: GoodsEntryStatus) {
        guard let appState, let input = updateInput(for: item, status: status) else {
            editorRoute = .edit(item, entryKind)
            return
        }
        Task {
            _ = await appState.updateGoodsEntry(itemID: item.id, kind: entryKind, input: input)
        }
    }

    func deleteSelectedItems() {
        guard let appState else {
            return
        }
        let targetIDs = Set(selectedItems.filter(isOwnedItem).map(\.id))
        Task {
            for itemID in targetIDs {
                _ = await appState.deleteGoodsItem(itemID)
            }
            selectedItemIDs.subtract(targetIDs)
        }
    }

    func updateInput(
        for item: GoodsItem,
        status: GoodsEntryStatus? = nil,
        appendingTag tagName: String? = nil
    ) -> GoodsEntryUpdateInput? {
        guard let groupID = item.groupID, let goodsTypeID = item.goodsTypeID else {
            return nil
        }
        var tagNames = item.tags.map(\.name)
        if let tagName, !tagNames.contains(where: { $0.caseInsensitiveCompare(tagName) == .orderedSame }) {
            tagNames.append(tagName)
        }
        return GoodsEntryUpdateInput(
            title: item.title,
            groupID: groupID,
            memberID: item.memberID,
            clearsMemberID: item.memberID == nil,
            goodsTypeID: goodsTypeID,
            quantity: item.quantity,
            status: status ?? item.status ?? .active,
            photoURLs: item.imageURL.map { [$0.absoluteString] },
            tagNames: tagNames
        )
    }
}
