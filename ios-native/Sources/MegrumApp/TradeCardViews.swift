import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeCard: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var profilesByUserID: [UUID: PublicUserProfile] = [:]
    var goodsByID: [UUID: GoodsItem] = [:]
    var lastActivityAt: Date?
    var viewerLastReadAt: Date?
    var isSelectionMode = false
    var isSelected = false
    var isSelectionEnabled = false
    var onLongPress: () -> Void = {}
    var onOpen: () -> Void

    private var presentation: TradeCardPresentation {
        TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: profilesByUserID,
            lastActivityAt: lastActivityAt,
            viewerLastReadAt: viewerLastReadAt
        )
    }

    private var offeredGoodsIDs: [UUID] {
        viewerID.flatMap { proposal.goodsOffered(by: $0) } ?? proposal.senderGoodsIDs
    }

    private var requestedGoodsIDs: [UUID] {
        viewerID.flatMap { proposal.goodsRequested(by: $0) } ?? proposal.receiverGoodsIDs
    }

    private var accessibilityLabel: String {
        let parts = [
            "取引",
            presentation.readState.title,
            proposal.exchangeMethod.displayName,
            "ゆずるグッズ \(offeredGoodsIDs.count)件",
            "求めるグッズ \(requestedGoodsIDs.count)件"
        ]
        return parts.joined(separator: "、")
    }

    var body: some View {
        TradeCardContent(
            presentation: presentation,
            offeredItems: previewItems(for: offeredGoodsIDs),
            requestedItems: previewItems(for: requestedGoodsIDs),
            isSelectionMode: isSelectionMode,
            isSelected: isSelected,
            isSelectionEnabled: isSelectionEnabled
        )
            .contentShape(Rectangle())
            .modifier(TradeCardExclusivePressModifier(
                onTap: onOpen,
                onLongPress: isSelectionEnabled ? onLongPress : nil
            ))
            .accessibilityAddTraits(.isButton)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(isSelectionMode ? "選択状態を切り替えます" : "取引詳細をページで開きます")
    }

    private func previewItems(for ids: [UUID]) -> [GoodsItem] {
        ids.compactMap { goodsByID[$0] }
    }
}

private struct TradeCardContent: View {
    var presentation: TradeCardPresentation
    var offeredItems: [GoodsItem]
    var requestedItems: [GoodsItem]
    var isSelectionMode: Bool
    var isSelected: Bool
    var isSelectionEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                TradeCardHeader(presentation: presentation)

                TradeDealGoodsPanel(
                    offeredItems: offeredItems,
                    requestedItems: requestedItems
                )

                TradeMeetupSummaryLine(
                    text: presentation.meetupSummaryText,
                    readState: presentation.readState
                )
            }
            .padding(.vertical, 17)

            TradeCardDivider(readState: presentation.readState)
        }
        .overlay(alignment: .topTrailing) {
            if isSelectionMode {
                TradeSelectionIndicator(
                    isSelected: isSelected,
                    isEnabled: isSelectionEnabled
                )
                .padding(.top, 15)
                .padding(.trailing, 4)
            }
        }
        .background {
            if presentation.readState == .unopened {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MegrumTheme.lavender.opacity(0.21),
                                MegrumTheme.pink.opacity(0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .opacity(isSelectionMode && !isSelectionEnabled ? 0.48 : 1)
    }
}
