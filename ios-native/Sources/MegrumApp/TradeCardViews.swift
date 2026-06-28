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
        if presentation.needsEvaluationAttention {
            parts.insert("評価待ち", at: 2)
        }
        return parts.joined(separator: "、")
    }

    var body: some View {
        TradeCardContent(
            presentation: presentation,
            proposal: proposal,
            viewerID: viewerID,
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
    var proposal: TradeProposal
    var viewerID: UUID?
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
                    offeredCashOffer: cashBelongsToOfferedSide,
                    offeredCashAmount: proposal.cashAmount,
                    requestedCashOffer: cashBelongsToRequestedSide,
                    requestedCashAmount: proposal.cashAmount,
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
        .background(presentation.readState.stateBackgroundColor)
        .overlay(alignment: .topTrailing) {
            if isSelectionMode {
                TradeSelectionIndicator(
                    isSelected: isSelected,
                    isEnabled: isSelectionEnabled
                )
                .padding(.top, 15)
                .padding(.trailing, TradeCardLayout.horizontalPadding)
            } else if presentation.needsEvaluationAttention {
                TradeEvaluationAttentionBadge()
                    .padding(.top, 14)
                    .padding(.trailing, TradeCardLayout.horizontalPadding)
            }
        }
        .opacity(isSelectionMode && !isSelectionEnabled ? 0.48 : 1)
    }

    private var cashBelongsToOfferedSide: Bool {
        guard proposal.cashOffer, let side = resolvedCashSide else {
            return false
        }
        guard let viewerID else {
            return side == .sender
        }
        return proposal.isSender(viewerID) ? side == .sender : side == .receiver
    }

    private var cashBelongsToRequestedSide: Bool {
        proposal.cashOffer && !cashBelongsToOfferedSide
    }

    private var resolvedCashSide: ProposalCashSide? {
        if let cashAmountSide = proposal.cashAmountSide {
            return cashAmountSide
        }
        if proposal.senderGoodsIDs.isEmpty, !proposal.receiverGoodsIDs.isEmpty {
            return .sender
        }
        if proposal.receiverGoodsIDs.isEmpty, !proposal.senderGoodsIDs.isEmpty {
            return .receiver
        }
        return .receiver
    }
}

private struct TradeEvaluationAttentionBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)

            Text("評価待ち")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color(red: 0.94, green: 0.16, blue: 0.20), in: Capsule())
        .shadow(color: Color(red: 0.94, green: 0.16, blue: 0.20).opacity(0.24), radius: 10, y: 5)
        .accessibilityHidden(true)
    }
}
