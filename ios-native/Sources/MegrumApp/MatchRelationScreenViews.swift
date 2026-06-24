import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationLoadingPanel: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(MegrumTheme.lavender)
            Text("マイグッズと個別募集を確認しています")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct MatchRelationSectionHeader: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MatchRelationContent: View {
    var isLoading: Bool
    var ownDetails: [MatchRelationListingDetail]
    var partnerDetails: [MatchRelationListingDetail]
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDsByListingID: [UUID: Set<UUID>]
    var selectedHaveIDsByListingID: [UUID: Set<UUID>]
    var targetItem: GoodsItem
    var simpleSenderItems: [GoodsItem]
    var showsSummary: Bool
    var summarySenderItems: [GoodsItem]
    var summaryReceiverItems: [GoodsItem]
    var onToggleHave: (UUID, UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var showsSimplePanel: Bool {
        ownDetails.isEmpty && partnerDetails.isEmpty && !isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if isLoading {
                MatchRelationLoadingPanel()
            }

            if !ownDetails.isEmpty {
                MatchRelationSectionHeader(title: "あなたの個別募集")
                relationCards(ownDetails)
            }

            if !partnerDetails.isEmpty {
                MatchRelationSectionHeader(title: "@\(partnerHandle) の個別募集")
                relationCards(partnerDetails)
            }

            if showsSimplePanel {
                MatchRelationSimplePanel(
                    targetItem: targetItem,
                    senderItems: simpleSenderItems
                )
            }

            if showsSummary {
                MatchRelationSummaryPanel(
                    senderItems: summarySenderItems,
                    receiverItems: summaryReceiverItems
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 112)
    }

    @ViewBuilder
    private func relationCards(_ details: [MatchRelationListingDetail]) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(details.enumerated()), id: \.element.id) { index, detail in
                MatchRelationTreeCard(
                    detail: detail,
                    index: index,
                    partnerHandle: partnerHandle,
                    highlightedItemID: highlightedItemID,
                    selectedCandidateIDs: selectedCandidateIDsByListingID[detail.id] ?? [],
                    selectedHaveIDs: selectedHaveIDsByListingID[detail.id] ?? [],
                    onToggleHave: { haveID in
                        onToggleHave(detail.id, haveID)
                    },
                    onOpenPopup: onOpenPopup
                )
            }
        }
    }
}

struct MatchRelationTreeCard: View {
    var detail: MatchRelationListingDetail
    var index: Int
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var cashOption: IndividualListingWishOption? {
        detail.listing.options.first(where: \.isCashOffer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("個別募集\(index + 1)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("選択肢 \(detail.selectableOptionCount) 件")
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

            HStack(alignment: .top, spacing: 12) {
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
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.04), radius: 8, y: 2)
    }

    private func cashText(_ option: IndividualListingWishOption) -> String {
        TradeAmountFormatter.fixedPrice(amount: option.cashAmount, fallback: "定価も可")
    }
}
