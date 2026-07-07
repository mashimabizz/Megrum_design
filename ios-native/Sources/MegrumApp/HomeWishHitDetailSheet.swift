import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeWishHitDetailSheet: View {
    /// 「求められているグッズ」経由の画面でのみ 推し以外でマッチ を表示する。
    var showsNonOshiOfferSection: Bool = false
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    var bottomButtonTitle: String = "交換内容を確認する"
    var preselectFirstOffer: Bool = true
    var onOpenOwnerProfile: (UUID) -> Void
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    var onCopyToWish: (HomeMockGoods) -> Void
    var isWishCopyInProgress: Bool
    @State private var presentationState = HomeWishHitDetailPresentationState()
    @State private var proposalConfirmation: HomeProposalStartConfirmationPayload?

    // 取引ブロックの寸法は超求（HomeDealBlockView）と揃える。
    private let thumbSide: CGFloat = 58
    private let arrowWidth: CGFloat = 16
    private let blockHeaderHeight: CGFloat = 32
    private let receiveColumnWidth: CGFloat = 82

    var body: some View {
        HomeSheetScaffold(
            // 譲れる候補が無くても打診に進める。文言は「交換内容を決める」で、1/3から手動で選ぶ（iter1226.365）。
            bottomButton: hasOfferCandidates ? bottomButtonTitle : "交換内容を決める",
            showsWishCopyButton: false,
            wishCopyButtonDisabled: isWishCopyInProgress,
            wishCopyButtonAction: { onCopyToWish(selection.goods) },
            bottomButtonDisabled: hasOfferCandidates ? !presentationState.canStartProposal : false,
            bottomButtonAction: startProposal
        ) {
            // 候補シート再設計と統一：名前＋評価のみ（大画像・判定羅列は撤去）。iter1226.375。
            HomeCandidateSheetHeader(
                owner: selection.goods.ownerSummary,
                fallbackName: selection.goods.ownerDisplayName?.nilIfBlank ?? "ユーザー",
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            // 求（wishマッチ）は個別募集が無いので、うけとる＝相手グッズ（確定 receiverGoods）／
            // ゆずる＝相手が求めるあなたのグッズ（1件選ぶ）の2列で、超求と同じ取引ブロックに揃える。iter1226.379。
            if matchedOfferGoods.isEmpty {
                HomeNoMatchingOfferGoodsPanel()
            } else {
                wishExchangeBlock
            }

            // 推しの登録に紐づかない手持ちグッズの提示は、
            // 「求められているグッズ」画像タップ経由の画面でのみ出す。
            if showsNonOshiOfferSection, !otherOfferGoods.isEmpty {
                nonOshiOfferSection
            }

            HomeCandidateDealAboutSection(
                verdict: HomeConditionVerdictPolicy.make(
                    from: selection.signals,
                    partnerPaymentNote: selection.goods.ownerPaymentNote
                ),
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(selection.signals),
                paymentSummaryText: selection.goods.ownerPaymentSummaryText,
                exchangeCalendarContext: HomePartnerExchangeCalendarContext.from(
                    signals: selection.signals,
                    ownerName: selection.goods.ownerSummary?.displayName
                ),
                listingNote: selection.individualListingSelection.listingNote,
                listingUpdatedAt: selection.individualListingSelection.listingUpdatedAt,
                goodsUpdatedAt: selection.goods.updatedAt
            )

            if showsOtherExchangeRows {
                HomeOtherExchangeRows(
                    addedCandidateIDs: addedExtraCandidateIDs,
                    excludedGoodsIDs: [selection.goods.id],
                    onOpenNestedSheet: onOpenNestedSheet
                )
            }
        }
        .onAppear(perform: prepareInitialSelection)
        .onChange(of: selection.id) { _, _ in
            prepareInitialSelection()
        }
        .sheet(item: $proposalConfirmation) { confirmation in
            HomeProposalStartConfirmationSheet(
                payload: confirmation,
                onConfirm: confirmProposalStart
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 取引ブロック（うけとる ⇄ ゆずる）

    private var wishExchangeBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 6) {
                // うけとる：相手のグッズ（打診の receiverGoods として確定）。細かい条件は打診で相談。
                VStack(alignment: .leading, spacing: 6) {
                    tierLabel("うけとる", subtitle: "打診で相談")
                    HomeDealThumb(
                        cell: HomeDealGoodsCell(
                            id: selection.goods.id,
                            index: 0,
                            imageURL: selection.goods.imageURL,
                            title: selection.goods.title,
                            selected: true,
                            selectable: false,
                            tentative: false
                        ),
                        side: thumbSide,
                        onTap: nil
                    )
                }
                .frame(width: receiveColumnWidth, alignment: .leading)

                connectorArrow

                // ゆずる：相手が求めるあなたのグッズを1件選ぶ。
                VStack(alignment: .leading, spacing: 6) {
                    tierLabel("ゆずる", subtitle: "相手が求めてる · \(matchedOfferGoods.count)件")
                    offerRail(goods: matchedOfferGoods, indexOffset: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HomeDealAchievementBar(achievement: offerAchievement)
        }
    }

    private var nonOshiOfferSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HomeSheetSectionTitle(
                systemName: "sparkles",
                title: "推し以外でマッチ"
            )
            offerRail(goods: otherOfferGoods, indexOffset: matchedOfferGoods.count)
        }
    }

    /// ゆずる候補の横スクロール列。選択済み＝グラデチェック、未選択＝破線＋（超求の HomeDealThumb と同一作法）。
    /// 選択は単一（selectedOfferIndex）で、推しマッチ＋推し以外を連結した通し index で扱う。
    private func offerRail(goods: [HomeMockGoods], indexOffset: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(goods.enumerated()), id: \.element.id) { position, item in
                    let index = indexOffset + position
                    HomeDealThumb(
                        cell: HomeDealGoodsCell(
                            id: item.id,
                            index: index,
                            imageURL: item.imageURL,
                            title: item.title,
                            selected: presentationState.selectedOfferIndices.contains(index),
                            selectable: true,
                            tentative: false
                        ),
                        side: thumbSide,
                        onTap: { presentationState.selectOffer(at: index) }
                    )
                }
            }
            .padding(.vertical, 2)
            .padding(.trailing, 4)
        }
    }

    private var offerAchievement: HomeDealAchievement {
        let selected = presentationState.canStartProposal
        return HomeDealAchievement(
            text: selected ? "1件選択済み・このまま打診に進めます" : "譲るグッズを1件選んでください",
            satisfied: selected
        )
    }

    // MARK: - 見出し・矢印（超求 HomeDealBlockView と同じ見た目・寸法）

    private func tierLabel(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.82))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(height: blockHeaderHeight, alignment: .topLeading)
    }

    private var connectorArrow: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: blockHeaderHeight + 6)
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(MegrumTheme.ink.opacity(0.3))
                .frame(height: thumbSide)
        }
        .frame(width: arrowWidth)
        .accessibilityHidden(true)
    }

    // MARK: - 候補データ

    private var matchedOfferGoods: [HomeMockGoods] {
        HomeWishHitOfferGoodsPolicy.offerGoods(
            viewerOfferGoods: viewerOfferGoods,
            matchedOfferGoodsIDs: selection.signals.wishMatchedOfferGoodsIDs,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
    }

    /// 推しマッチに含まれない、自分が交換に出せる残りのグッズ。
    private var otherOfferGoods: [HomeMockGoods] {
        let matchedIDs = Set(matchedOfferGoods.map(\.id))
        return viewerOfferGoods.filter { !matchedIDs.contains($0.id) }
    }

    /// 選択・打診処理は「推しマッチ＋（表示時のみ）推し以外」を連結した1つの配列として扱う。
    private var offerGoods: [HomeMockGoods] {
        showsNonOshiOfferSection ? matchedOfferGoods + otherOfferGoods : matchedOfferGoods
    }

    /// 譲れる候補があるか。無ければ「交換内容を決める」で1/3から手動選択に進む（iter1226.365）。
    private var hasOfferCandidates: Bool {
        !offerGoods.isEmpty
    }

    private func prepareInitialSelection() {
        presentationState.prepareInitialSelection(
            preselectFirstOffer: preselectFirstOffer,
            offerGoods: offerGoods
        )
    }

    private func startProposal() {
        let verdict = HomeConditionVerdictPolicy.make(
            from: selection.signals,
            partnerPaymentNote: selection.goods.ownerPaymentNote
        )
        let suggestedMessage = ProposalSuggestedMessageBuilder.make(from: verdict)

        // 譲れる候補が無い場合は、提示物未選択のまま打診フロー1/3へ直行する（iter1226.365）。
        // exchangeMethod=nil → HomeDiscoveryProposalRouteResolver が initialStep=.give を選ぶ。
        guard hasOfferCandidates else {
            onStartProposal(
                HomeDiscoveryProposalSelection(
                    receiverGoodsID: selection.goods.id,
                    senderGoodsIDs: [],
                    matchType: .forward,
                    receiverGoods: selection.goods,
                    senderGoods: [],
                    exchangeMethod: nil,
                    suggestedMessage: suggestedMessage
                )
            )
            return
        }

        guard var proposalSelection = presentationState.proposalSelection(
            selection: selection,
            offerGoods: offerGoods
        ) else {
            return
        }
        proposalSelection.suggestedMessage = suggestedMessage
        // 激求（グッズ指定）と同様に、交換内容のプレビューを挟んでから打診へ進む。
        proposalConfirmation = HomeProposalStartConfirmationPayload(
            proposalSelection: proposalSelection,
            receiverGoods: [selection.goods],
            senderGoods: proposalSelection.senderGoods,
            senderCashAmount: proposalSelection.cashAmount
        )
    }

    private func confirmProposalStart(_ confirmedSelection: HomeDiscoveryProposalSelection) {
        proposalConfirmation = nil
        onStartProposal(confirmedSelection)
    }
}

enum HomeWishHitOfferGoodsPolicy {
    static func offerGoods(
        viewerOfferGoods: [HomeMockGoods],
        matchedOfferGoodsIDs: [UUID],
        preferredOfferGoodsID: UUID?
    ) -> [HomeMockGoods] {
        let matchedOfferIDs = Set(matchedOfferGoodsIDs)
        guard !matchedOfferIDs.isEmpty else {
            return []
        }
        return HomeOfferGoodsOrdering.ordered(
            viewerOfferGoods.filter { matchedOfferIDs.contains($0.id) },
            preferredOfferGoodsID: preferredOfferGoodsID
        )
    }
}
