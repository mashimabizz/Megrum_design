import Foundation
import MegrumCore

enum SearchSuggestionBuilder {
    static func tagCandidateNames(
        userOshiSelections: [UserOshiSelection],
        wishes: [WishItem],
        inventory: [GoodsItem],
        viewerID: UUID?,
        limitingToGroupID: UUID? = nil,
        limit: Int = 24
    ) -> [String] {
        var oshiGroupIDs = Set(userOshiSelections.compactMap(\.groupID))
        if let limitingToGroupID {
            guard oshiGroupIDs.contains(limitingToGroupID) else {
                return []
            }
            oshiGroupIDs = [limitingToGroupID]
        }
        guard let viewerID, !oshiGroupIDs.isEmpty else {
            return []
        }

        return TagNameNormalizer.uniquePreservingOrder(
            (wishes.map(\.asGoodsTagSource) + inventory)
                .filter { item in
                    item.ownerID == viewerID
                        && item.matchesOshiGroup(groupIDs: oshiGroupIDs)
                        && !item.tags.isEmpty
                }
                .flatMap { $0.tags.map(\.name) },
            limit: limit
        )
    }

    static func sections(
        userOshiSelections: [UserOshiSelection],
        oshiGroups: [OshiGroup],
        oshiCharacters: [OshiCharacter],
        wishes: [WishItem],
        inventory: [GoodsItem],
        listings: [IndividualListing] = [],
        viewer: UserProfile?
    ) -> [SearchSuggestionSection] {
        [
            SearchSuggestionSection(
                id: "oshi",
                title: "推しから探す",
                systemImageName: "sparkles",
                tintRole: .lavender,
                items: oshiItems(
                    userOshiSelections: userOshiSelections,
                    oshiGroups: oshiGroups,
                    oshiCharacters: oshiCharacters
                )
            ),
            SearchSuggestionSection(
                id: "tag",
                title: "シリーズから探す",
                systemImageName: "tag.fill",
                tintRole: .muted,
                items: tagItems(
                    userOshiSelections: userOshiSelections,
                    wishes: wishes,
                    inventory: inventory,
                    viewerID: viewer?.id
                )
            )
        ].filter { !$0.isEmpty }
    }

    private static func oshiItems(
        userOshiSelections: [UserOshiSelection],
        oshiGroups: [OshiGroup],
        oshiCharacters: [OshiCharacter]
    ) -> [SearchSuggestionItem] {
        var items: [SearchSuggestionItem] = []
        var seenIDs = Set<String>()

        for selection in userOshiSelections.sorted(by: { $0.priority < $1.priority }) {
            let groupName = selection.groupName
                ?? selection.groupID.flatMap { groupID in oshiGroups.first(where: { $0.id == groupID })?.name }
                ?? selection.oshiRequestName
                ?? "推し"

            if let groupID = selection.groupID {
                let id = "group-\(groupID.uuidString)"
                if seenIDs.insert(id).inserted {
                    items.append(
                        SearchSuggestionItem(
                            id: id,
                            title: groupName,
                            subtitle: "グループ・作品",
                            imageURL: nil,
                            action: .group(groupID)
                        )
                    )
                }
            } else if selection.oshiRequestName?.isBlank == false {
                let id = "group-request-\(groupName)"
                if seenIDs.insert(id).inserted {
                    items.append(
                        SearchSuggestionItem(
                            id: id,
                            title: groupName,
                            subtitle: "グループ・作品",
                            imageURL: nil,
                            action: .query(groupName)
                        )
                    )
                }
            }

            if let memberID = selection.characterID {
                let memberName = selection.characterName
                    ?? oshiCharacters.first(where: { $0.id == memberID })?.name
                    ?? selection.characterRequestName
                    ?? groupName
                let id = "member-\(memberID.uuidString)"
                guard seenIDs.insert(id).inserted else {
                    continue
                }
                items.append(
                    SearchSuggestionItem(
                        id: id,
                        title: memberName,
                        subtitle: "メンバー・キャラクター",
                        imageURL: nil,
                        action: selection.groupID.map { .member(groupID: $0, memberID: memberID) } ?? .query(memberName)
                    )
                )
            } else if let memberName = selection.characterRequestName, !memberName.isBlank {
                let id = "member-request-\(memberName)"
                guard seenIDs.insert(id).inserted else { continue }
                items.append(
                    SearchSuggestionItem(
                        id: id,
                        title: memberName,
                        subtitle: "メンバー・キャラクター",
                        imageURL: nil,
                        action: .query(memberName)
                    )
                )
            }
        }

        return Array(items.prefix(20))
    }

    static func wishItems(wishes: [WishItem]) -> [SearchSuggestionItem] {
        wishes.map { wish in
            SearchSuggestionItem(
                id: "wish-\(wish.id.uuidString)",
                title: wish.title,
                subtitle: wish.tags.first.map { "#\($0.name)" },
                imageURL: wish.imageURL,
                action: .wish(
                    groupID: wish.groupID,
                    memberID: wish.memberID,
                    goodsTypeID: wish.goodsTypeID,
                    tagNames: wish.tags.map(\.name)
                )
            )
        }
    }

    private static func tagItems(
        userOshiSelections: [UserOshiSelection],
        wishes: [WishItem],
        inventory: [GoodsItem],
        viewerID: UUID?
    ) -> [SearchSuggestionItem] {
        let tagNames = tagCandidateNames(
            userOshiSelections: userOshiSelections,
            wishes: wishes,
            inventory: inventory,
            viewerID: viewerID
        )

        return tagNames.map { tagName in
            SearchSuggestionItem(
                id: "tag-\(tagName)",
                title: tagName,
                systemImageName: "tag.fill",
                action: .tag(tagName)
            )
        }
    }
}

private extension WishItem {
    var asGoodsTagSource: GoodsItem {
        GoodsItem(
            id: id,
            ownerID: ownerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            title: title,
            imageURL: imageURL,
            tags: tags,
            quantity: quantity
        )
    }
}

private extension GoodsItem {
    func matchesOshiGroup(groupIDs: Set<UUID>) -> Bool {
        if let groupID, groupIDs.contains(groupID) {
            return true
        }
        return false
    }
}
