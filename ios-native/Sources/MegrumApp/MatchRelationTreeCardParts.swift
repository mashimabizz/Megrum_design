import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationTreeCardHeader: View {
    var index: Int
    var selectableOptionCount: Int
    var cashOption: IndividualListingWishOption?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("個別募集\(index + 1)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("選択肢 \(selectableOptionCount) 件")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            Spacer()

            if let cashOption {
                Text(cashText(cashOption))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
            }
        }
    }

    private func cashText(_ option: IndividualListingWishOption) -> String {
        TradeAmountFormatter.fixedPrice(amount: option.cashAmount, fallback: "定価も可")
    }
}

struct MatchRelationTreeCardColumns: View {
    var detail: MatchRelationListingDetail
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MatchRelationTreePartnerColumn(
                detail: detail,
                partnerHandle: partnerHandle,
                highlightedItemID: highlightedItemID,
                selectedCandidateIDs: selectedCandidateIDs,
                selectedHaveIDs: selectedHaveIDs,
                onToggleHave: onToggleHave,
                onOpenPopup: onOpenPopup
            )

            MatchRelationTreeViewerColumn(
                detail: detail,
                partnerHandle: partnerHandle,
                highlightedItemID: highlightedItemID,
                selectedCandidateIDs: selectedCandidateIDs,
                selectedHaveIDs: selectedHaveIDs,
                onToggleHave: onToggleHave,
                onOpenPopup: onOpenPopup
            )
        }
    }
}

struct MatchRelationTreePartnerColumn: View {
    var detail: MatchRelationListingDetail
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MatchRelationOwnerLabel(
                title: detail.isMyListing ? "@\(partnerHandle) が譲る候補" : "@\(partnerHandle) が譲るもの",
                color: MegrumTheme.pink
            )

            if detail.isMyListing {
                MatchRelationOptionList(
                    detail: detail,
                    viewpoint: .mine,
                    partnerHandle: partnerHandle,
                    highlightedItemID: highlightedItemID,
                    selectedCandidateIDs: selectedCandidateIDs,
                    onOpenPopup: onOpenPopup
                )
            } else {
                MatchRelationHaveList(
                    detail: detail,
                    highlightedItemID: highlightedItemID,
                    selectedHaveIDs: selectedHaveIDs,
                    onToggleHave: onToggleHave
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct MatchRelationTreeViewerColumn: View {
    var detail: MatchRelationListingDetail
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MatchRelationOwnerLabel(
                title: detail.isMyListing ? "あなたが譲るもの" : "あなたが譲れる候補",
                color: MegrumTheme.lavender
            )

            if detail.isMyListing {
                MatchRelationHaveList(
                    detail: detail,
                    highlightedItemID: highlightedItemID,
                    selectedHaveIDs: selectedHaveIDs,
                    onToggleHave: onToggleHave
                )
            } else {
                MatchRelationOptionList(
                    detail: detail,
                    viewpoint: .partner,
                    partnerHandle: partnerHandle,
                    highlightedItemID: highlightedItemID,
                    selectedCandidateIDs: selectedCandidateIDs,
                    onOpenPopup: onOpenPopup
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
