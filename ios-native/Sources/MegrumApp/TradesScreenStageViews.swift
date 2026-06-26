import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeStagePage: View {
    var stage: TradeStage
    var proposals: [TradeProposal]
    var viewerID: UUID?
    var profilesByUserID: [UUID: PublicUserProfile]
    var goodsByID: [UUID: GoodsItem]
    var messagesByProposalID: [UUID: [TradeMessage]]
    var viewerReadAtByProposalID: [UUID: Date]
    var isSelectingPendingProposals: Bool
    var selectedPendingProposalIDs: Set<UUID>
    var adDisplayContext: AdDisplayContext
    var canWithdraw: (TradeProposal) -> Bool
    var onStartSelection: (TradeProposal) -> Void
    var onToggleSelection: (TradeProposal) -> Void
    var onOpen: (TradeProposal) -> Void

    private var isSelectionMode: Bool {
        isSelectingPendingProposals && stage == .pending
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if proposals.isEmpty {
                    EmptyTradeStage(stage: stage)
                        .padding(.horizontal, TradeCardLayout.horizontalPadding)
                        .padding(.top, 8)
                } else {
                    proposalRows
                    completedFooterAd
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.bottom, 132)
        }
    }

    private var proposalRows: some View {
        ForEach(proposals) { proposal in
            let isWithdrawable = canWithdraw(proposal)
            TradeCard(
                proposal: proposal,
                viewerID: viewerID,
                profilesByUserID: profilesByUserID,
                goodsByID: goodsByID,
                messages: messagesByProposalID[proposal.id] ?? [],
                lastActivityAt: TradeListOrdering.lastActivityAt(
                    for: proposal,
                    messagesByProposalID: messagesByProposalID
                ),
                viewerLastReadAt: viewerReadAtByProposalID[proposal.id],
                isSelectionMode: isSelectionMode,
                isSelected: selectedPendingProposalIDs.contains(proposal.id),
                isSelectionEnabled: isWithdrawable,
                onLongPress: {
                    guard isWithdrawable else {
                        return
                    }
                    onStartSelection(proposal)
                }
            ) {
                if isSelectionMode {
                    onToggleSelection(proposal)
                } else {
                    onOpen(proposal)
                }
            }
        }
    }

    @ViewBuilder
    private var completedFooterAd: some View {
        if stage == .completed {
            AdBannerSlot(
                placement: .pastTradesFooterBanner,
                displayContext: adDisplayContext
            )
            .padding(.horizontal, TradeCardLayout.horizontalPadding)
            .padding(.top, 12)
        }
    }
}

struct TradesFooter: View {
    @Binding var selectedStage: TradeStage
    var isSelectingPendingProposals: Bool
    var selectedPendingCount: Int
    var isResponding: Bool
    var pendingCount: Int
    var inProgressCount: Int
    var completedCount: Int
    var onWithdrawSelected: () -> Void

    var body: some View {
        if isSelectingPendingProposals {
            withdrawButton
        } else {
            TradeStageBar(
                selectedStage: $selectedStage,
                pendingCount: pendingCount,
                inProgressCount: inProgressCount,
                completedCount: completedCount
            )
        }
    }

    private var withdrawButton: some View {
        Button(action: onWithdrawSelected) {
            Label("打診を取り下げる", systemImage: "arrow.uturn.backward")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(MegrumTheme.lavender, in: Capsule())
                .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(selectedPendingCount == 0 || isResponding)
        .accessibilityLabel("選択した\(selectedPendingCount)件の打診を取り下げる")
    }
}
