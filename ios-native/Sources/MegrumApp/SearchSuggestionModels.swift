import Foundation
import MegrumCore

struct SearchInitialCriteria: Equatable, Sendable {
    var query: String
    var groupID: UUID?
    var memberID: UUID?
    var goodsTypeID: UUID?
    var tagNames: [String]

    init(
        query: String = "",
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        tagNames: [String] = []
    ) {
        self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.tagNames = TagNameNormalizer.uniquePreservingOrder(tagNames, limit: 8)
    }

    var id: String {
        [
            query,
            groupID?.uuidString ?? "",
            memberID?.uuidString ?? "",
            goodsTypeID?.uuidString ?? "",
            tagNames.joined(separator: ",")
        ].joined(separator: "|")
    }
}

enum SearchSuggestionAction: Hashable, Sendable {
    case group(UUID)
    case member(groupID: UUID, memberID: UUID)
    case wish(groupID: UUID?, memberID: UUID?, goodsTypeID: UUID?, tagNames: [String])
    case goodsType(UUID)
    case tag(String)
    case payment(UserPaymentMethod)
    case meetupPrefecture(String)
    case query(String)
}

struct SearchSuggestionItem: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var subtitle: String?
    var imageURL: URL?
    var systemImageName: String?
    var action: SearchSuggestionAction

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        imageURL: URL? = nil,
        systemImageName: String? = nil,
        action: SearchSuggestionAction
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.systemImageName = systemImageName
        self.action = action
    }
}

struct SearchSuggestionSection: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var systemImageName: String
    var tintRole: SearchSuggestionTintRole
    var items: [SearchSuggestionItem]

    var isEmpty: Bool {
        items.isEmpty
    }
}

enum SearchSuggestionTintRole: Equatable, Sendable {
    case lavender
    case pink
    case muted
}

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
                id: "wish",
                title: "Wishから探す",
                systemImageName: "heart.fill",
                tintRole: .pink,
                items: wishItems(wishes: wishes)
            ),
            SearchSuggestionSection(
                id: "tag",
                title: "タグから探す",
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
                            subtitle: "L1",
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
                            subtitle: "L1",
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
                        subtitle: "L2",
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
                        subtitle: "L2",
                        imageURL: nil,
                        action: .query(memberName)
                    )
                )
            }
        }

        return Array(items.prefix(20))
    }

    private static func wishItems(wishes: [WishItem]) -> [SearchSuggestionItem] {
        wishes.prefix(10).map { wish in
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
