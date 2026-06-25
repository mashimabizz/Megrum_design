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
}
