import MegrumCore
import SwiftUI

extension GoodsCollectionScreen {
    var collectionMemberLookupGroupIDs: [UUID] {
        Array(Set(items.compactMap { item in
            guard item.memberID != nil else {
                return nil
            }
            return item.groupID
        }))
        .sorted { $0.uuidString < $1.uuidString }
    }

    func quickActionHeaderPresentation(for item: GoodsItem) -> GoodsQuickActionHeaderPresentation {
        GoodsQuickActionHeaderPresentation(
            item: item,
            l1Name: appState?.oshiGroups.first { $0.id == item.groupID }?.name,
            l2Name: resolvedMemberName(for: item)
        )
    }

    func resolvedMemberName(for item: GoodsItem) -> String? {
        guard let memberID = item.memberID else {
            return nil
        }
        if let groupID = item.groupID,
           let cachedMember = oshiCharactersByGroupID[groupID]?.first(where: { $0.id == memberID }) {
            return cachedMember.name
        }
        return appState?.oshiCharacters.first { $0.id == memberID }?.name
    }

    func loadFilterChoicesIfNeeded() async {
        guard let appState else {
            return
        }
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        await loadCollectionCharactersIfNeeded()
    }

    func loadCollectionCharactersIfNeeded() async {
        for groupID in collectionMemberLookupGroupIDs where oshiCharactersByGroupID[groupID] == nil {
            await loadCharactersIfNeeded(groupID: groupID)
        }
    }

    func loadCharactersIfNeeded(for item: GoodsItem) async {
        guard item.memberID != nil, let groupID = item.groupID else {
            return
        }
        await loadCharactersIfNeeded(groupID: groupID)
    }

    func loadCharactersIfNeeded(groupID: UUID) async {
        guard let appState, oshiCharactersByGroupID[groupID] == nil else {
            return
        }
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        guard let group = appState.oshiGroups.first(where: { $0.id == groupID }) else {
            return
        }
        await appState.loadOshiCharacters(group: group)
        oshiCharactersByGroupID[groupID] = appState.oshiCharacters
    }

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
        case .edit:
            editorRoute = .edit(item, entryKind)
        case .moveToKeep:
            moveItem(item, to: item.status == .keep ? .active : .keep)
        case .tag:
            bulkTagRoute = GoodsBulkTagRoute(itemIDs: [item.id])
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

    func applyBulkTag(_ tagName: String, to itemIDs: Set<UUID>) {
        guard let appState else {
            return
        }
        let targetItems = items.filter { itemIDs.contains($0.id) && isOwnedItem($0) }
        Task {
            for item in targetItems {
                guard let input = updateInput(for: item, appendingTag: tagName) else {
                    continue
                }
                _ = await appState.updateGoodsEntry(itemID: item.id, kind: entryKind, input: input)
            }
            selectedItemIDs.subtract(itemIDs)
        }
    }

    func bulkTagCandidateNames(for itemIDs: Set<UUID>) -> [String] {
        guard let appState else {
            return []
        }
        let groupIDs = orderedGroupIDs(from: bulkTagTargetItems(for: itemIDs))
        let suggestions = groupIDs.flatMap { groupID in
            GoodsEditorTagSuggestionBuilder.suggestions(
                groupID: groupID,
                selectedTags: [],
                inventory: items,
                wishes: appState.wishes,
                limit: 10
            )
        }
        return TagNameNormalizer.uniquePreservingOrder(suggestions, limit: 10)
    }

    func bulkTagPreviewItemsByTag(for itemIDs: Set<UUID>) -> [String: [TagPreviewItem]] {
        guard let appState else {
            return [:]
        }
        let groupIDs = orderedGroupIDs(from: bulkTagTargetItems(for: itemIDs))
        let selectedGroupID = groupIDs.count == 1 ? groupIDs.first : nil
        return IndividualListingConditionTagBuilder(
            inventory: items,
            wishes: appState.wishes,
            selectedGroupID: selectedGroupID
        )
        .previewItemsByTag()
    }

    func bulkTagTargetItems(for itemIDs: Set<UUID>) -> [GoodsItem] {
        items.filter { itemIDs.contains($0.id) && isOwnedItem($0) }
    }

    func orderedGroupIDs(from targetItems: [GoodsItem]) -> [UUID] {
        Array(Set(targetItems.compactMap(\.groupID)))
            .sorted { $0.uuidString < $1.uuidString }
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

    func resetFilters() {
        selectedGroupID = nil
        selectedGoodsTypeID = nil
        selectedTagNames = []
    }

    func reconcileSelectedTags() {
        let available = Set(availableTagNames)
        selectedTagNames = selectedTagNames.intersection(available)
    }

    func reconcileSelectedFilters() {
        if let selectedGroupID,
           appState?.isLoadingOshiGroups != true,
           !availableGroups.contains(where: { $0.id == selectedGroupID }) {
            self.selectedGroupID = nil
        }
        if let selectedGoodsTypeID,
           appState?.isLoadingGoodsTypes != true,
           !availableGoodsTypes.contains(where: { $0.id == selectedGoodsTypeID }) {
            self.selectedGoodsTypeID = nil
        }
        reconcileSelectedTags()
    }

    func openAddForm() {
        if appState == nil {
            isShowingUnavailableAlert = true
        } else {
            editorRoute = .create(entryKind)
        }
    }
}
