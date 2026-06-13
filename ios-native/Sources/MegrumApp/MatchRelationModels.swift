import Foundation
import MegrumCore

struct MatchRelationProposalTarget: Identifiable, Equatable {
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]
    var senderGoodsIDs: [UUID]
    var matchType: ProposalMatchType

    var id: String {
        [
            targetItem.id.uuidString,
            listingID?.uuidString ?? "multi-or-simple",
            receiverGoodsIDs.map(\.uuidString).joined(separator: ","),
            senderGoodsIDs.map(\.uuidString).joined(separator: ","),
            matchType.rawValue
        ]
        .joined(separator: "|")
    }
}

struct MatchRelationListingDetail: Identifiable, Equatable {
    var listing: IndividualListing
    var isMyListing: Bool
    var haves: [MatchRelationHave]
    var options: [MatchRelationOption]

    var id: UUID { listing.id }

    var selectableOptionCount: Int {
        options.filter { !$0.option.isCashOffer }.count
    }
}

struct MatchRelationHave: Identifiable, Equatable {
    var item: GoodsItem
    var quantity: Int
    var matched: Bool

    var id: UUID { item.id }
}

struct MatchRelationOption: Identifiable, Equatable {
    var option: IndividualListingWishOption
    var wishes: [MatchRelationWish]
    var matched: Bool

    var id: UUID { option.id }
}

struct MatchRelationWish: Identifiable, Equatable {
    var item: GoodsItem
    var quantity: Int
    var candidates: [MatchRelationCandidate]

    var id: UUID { item.id }
}

struct MatchRelationCandidate: Identifiable, Equatable {
    var item: GoodsItem
    var quantity: Int

    var id: UUID { item.id }
}

struct MatchRelationWishPopupTarget: Identifiable, Equatable {
    var listingID: UUID
    var viewpoint: MatchRelationViewpoint
    var wish: MatchRelationWish
    var exchangeType: IndividualListingExchangeType
    var fallbackHave: MatchRelationHave

    var id: String {
        [
            listingID.uuidString,
            viewpoint.rawValue,
            wish.id.uuidString
        ]
        .joined(separator: "|")
    }
}

enum MatchRelationViewpoint: String, Equatable {
    case mine
    case partner
}

enum MatchRelationPopupCopy {
    static func candidateOwnerTitle(viewpoint: MatchRelationViewpoint, partnerHandle: String) -> String {
        switch viewpoint {
        case .mine:
            "@\(partnerHandle) が譲るもの"
        case .partner:
            "あなたが譲るもの"
        }
    }

    static func subtitle(quantity: Int, candidateCount: Int) -> String {
        "wish ×\(quantity)・\(candidateCount) 件の候補"
    }

    static func fallbackTitle(_ title: String) -> String {
        "↑ あなたの譲：\(title)"
    }
}

struct MatchRelationAggregate: Equatable {
    var senderItems: [GoodsItem]
    var receiverItems: [GoodsItem]
    var senderIDs: [UUID]
    var receiverIDs: [UUID]
    var referencedListingIDs: [UUID]

    static let empty = MatchRelationAggregate(
        senderItems: [],
        receiverItems: [],
        senderIDs: [],
        receiverIDs: [],
        referencedListingIDs: []
    )

    var isEmpty: Bool {
        senderIDs.isEmpty || receiverIDs.isEmpty || referencedListingIDs.isEmpty
    }
}

enum MatchRelationBottomBarCopy {
    static func primaryTitle(isEnabled: Bool, showsReset: Bool, totalSelectionCount: Int) -> String {
        guard isEnabled else {
            return "候補を読み込んでいます"
        }
        if showsReset {
            return "打診に進む（\(totalSelectionCount)件）"
        }
        return "この内容で打診へ"
    }

    static func secondaryTitle(showsReset: Bool) -> String {
        showsReset ? "リセット" : "閉じる"
    }
}
