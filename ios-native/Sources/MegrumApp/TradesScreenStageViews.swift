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
    var evaluatedProposalIDs: Set<UUID> = []
    var isSelectingPendingProposals: Bool
    var selectedPendingProposalIDs: Set<UUID>
    var adDisplayContext: AdDisplayContext
    var topContentInset: CGFloat = 0
    var canWithdraw: (TradeProposal) -> Bool
    var onStartSelection: (TradeProposal) -> Void
    var onToggleSelection: (TradeProposal) -> Void
    var onOpen: (TradeProposal) -> Void

    private var isSelectionMode: Bool {
        isSelectingPendingProposals && stage == .pending
    }

    /// タブスワイプ中に全カードを一気に構築するとカクつくため、
    /// 最初は数件だけ描画し、スクロールで末尾に近づくたびに追加する。
    private static let initialVisibleCount = 4
    private static let visibleCountStep = 4
    @State private var visibleCount = TradeStagePage.initialVisibleCount

    private var visibleProposals: [TradeProposal] {
        Array(proposals.prefix(visibleCount))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                listTopAd
                if proposals.isEmpty {
                    EmptyTradeStage(stage: stage)
                        .padding(.horizontal, TradeCardLayout.horizontalPadding)
                        .padding(.top, 8)
                } else {
                    proposalRows

                    if visibleCount < proposals.count {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                visibleCount += Self.visibleCountStep
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, topContentInset + 8)
            // ステージフッター＋タブバーに最後のパネルが隠れないよう余白を確保
            .padding(.bottom, 176)
            .megrumSuppressesEnclosingScrollEdgeEffects()
        }
        .megrumHiddenBottomScrollEdgeEffect()
        .ignoresSafeArea(.container, edges: .bottom)
        .background(Color.white)
    }

    private var proposalRows: some View {
        ForEach(visibleProposals) { proposal in
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
                viewerHasSubmittedEvaluation: evaluatedProposalIDs.contains(proposal.id),
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
    private var listTopAd: some View {
        AdBannerSlot(
            placement: .tradesListTopBanner,
            displayContext: adDisplayContext,
            bottomSpacing: 12
        )
        .padding(.horizontal, TradeCardLayout.horizontalPadding)
    }
}

struct TradesFooter: View {
    @Binding var selectedStage: TradeStage
    var isSelectingPendingProposals: Bool
    var selectedPendingCount: Int
    var isResponding: Bool
    var pendingBadgeCount: Int
    var inProgressBadgeCount: Int
    var completedBadgeCount: Int
    var onWithdrawSelected: () -> Void

    var body: some View {
        if isSelectingPendingProposals {
            withdrawButton
        } else {
            TradeStageBar(
                selectedStage: $selectedStage,
                pendingBadgeCount: pendingBadgeCount,
                inProgressBadgeCount: inProgressBadgeCount,
                completedBadgeCount: completedBadgeCount
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
