import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeCardLayout {
    static let horizontalPadding: CGFloat = 20
}

struct TradeCard: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var profilesByUserID: [UUID: PublicUserProfile] = [:]
    var goodsByID: [UUID: GoodsItem] = [:]
    var messages: [TradeMessage] = []
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
            messages: messages,
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
        var parts = [
            "取引",
            presentation.readState.title,
            proposal.exchangeMethod.displayName,
            "ゆずるグッズ \(offeredGoodsIDs.count)件",
            "求めるグッズ \(requestedGoodsIDs.count)件"
        ]
        if presentation.unreadBadgeCount > 0 {
            parts.insert("未読\(presentation.unreadBadgeCount)件", at: 2)
        }
        return parts.joined(separator: "、")
    }

    var body: some View {
        TradeCardContent(
            presentation: presentation,
            offeredItems: previewItems(for: offeredGoodsIDs),
            requestedItems: previewItems(for: requestedGoodsIDs),
            isSelectionMode: isSelectionMode,
            isSelected: isSelected,
            isSelectionEnabled: isSelectionEnabled,
            onOpen: onOpen
        )
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(TradeCardExclusivePressModifier(
                onTap: onOpen,
                onLongPress: isSelectionEnabled ? onLongPress : nil
            ))
            .megrumInteractionFeedback(clipsToBounds: true)
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
    var onOpen: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                TradeCardHeader(presentation: presentation)

                TradeDealGoodsPanel(
                    offeredItems: offeredItems,
                    requestedItems: requestedItems,
                    onCarouselTap: onOpen
                )

                if let meetupSummaryText = presentation.meetupSummaryText {
                    TradeMeetupSummaryLine(
                        text: meetupSummaryText,
                        systemImage: presentation.conditionIconSystemName,
                        readState: presentation.readState
                    )
                }
            }
            .padding(.horizontal, TradeCardLayout.horizontalPadding)
            .padding(.vertical, 12)

            TradeCardDivider(readState: presentation.readState)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            if isSelectionMode {
                TradeSelectionIndicator(
                    isSelected: isSelected,
                    isEnabled: isSelectionEnabled
                )
                .padding(.top, 15)
                .padding(.trailing, TradeCardLayout.horizontalPadding)
            }
        }
        .opacity(isSelectionMode && !isSelectionEnabled ? 0.48 : 1)
    }
}
