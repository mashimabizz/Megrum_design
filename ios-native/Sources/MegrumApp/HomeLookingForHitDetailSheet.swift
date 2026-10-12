import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// 「◯◯を探し中」候補の専用シート（iter1226.411 / FB項目3）。
/// マッチ確定ではないため、相手の探し物テキストを主役の引用カードに置き、
/// うけとる＝相手グッズ確定 ⇄ ゆずる＝探し物に近い手持ちを先頭にした全在庫から1件選ぶ。
struct HomeLookingForHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var lookingForText: String
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    var otherExchangeCandidates: HomeOtherExchangeCandidateGroups = .empty
    var addedExtraSelections: [HomeDiscoveryProposalSelection] = []
    var showsProposalPreview: Bool = true
    var onOpenOwnerProfile: (UUID) -> Void
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    @State private var presentationState = HomeWishHitDetailPresentationState()
    @State private var proposalConfirmation: HomeProposalStartConfirmationPayload?

    // 取引ブロックの寸法は超求/求のシートと揃える。
    private let thumbSide: CGFloat = 58
    private let arrowWidth: CGFloat = 16
    private let blockHeaderHeight: CGFloat = 32
    private let receiveColumnWidth: CGFloat = 82

    var body: some View {
        HomeSheetScaffold(
            bottomButton: hasOfferCandidates ? "このグッズで打診してみる" : "交換内容を決める",
            bottomButtonDisabled: hasOfferCandidates ? !presentationState.canStartProposal : false,
            bottomButtonAction: startProposal
        ) {
            HomeCandidateSheetHeader(
                owner: selection.goods.ownerSummary,
                fallbackName: selection.goods.ownerDisplayName?.nilIfBlank ?? "ユーザー",
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            HomeLookingForQuoteCard(text: lookingForText)

            if hasOfferCandidates {
                exchangeBlock
            } else {
                HomeLookingForNoInventoryPanel(lookingForText: lookingForText)
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
                goodsUpdatedAt: selection.goods.updatedAt,
                isReadyToConfirm: presentationState.canStartProposal
            )

            if showsOtherExchangeRows {
                HomeSamePartnerExchangeSection(
                    groups: otherExchangeCandidates,
                    addedCandidateIDs: addedExtraCandidateIDs,
                    onOpenNestedSheet: onOpenNestedSheet
                )
            }
        }
        .onChange(of: selection.id) { _, _ in
            presentationState.prepareInitialSelection(preselectFirstOffer: false, offerGoods: orderedOfferGoods)
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

    private var exchangeBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 6) {
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

                VStack(alignment: .leading, spacing: 6) {
                    tierLabel("ゆずる", subtitle: offerSubtitle)
                    offerRail
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HomeDealAchievementBar(achievement: offerAchievement)
        }
    }

    private var offerSubtitle: String {
        relevantOfferCount > 0
            ? "探し物に近い順 · \(orderedOfferGoods.count)件"
            : "あなたの在庫 · \(orderedOfferGoods.count)件"
    }

    private var offerRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(orderedOfferGoods.enumerated()), id: \.element.id) { index, item in
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
            text: selected ? "1件選択済み・打診で相談できます" : "気になるグッズを1件選んで打診してみましょう",
            satisfied: selected
        )
    }

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

    private var orderedOfferGoods: [HomeMockGoods] {
        HomeLookingForOfferOrdering.ordered(viewerOfferGoods, lookingForText: lookingForText)
    }

    private var relevantOfferCount: Int {
        HomeLookingForOfferOrdering.relevantCount(viewerOfferGoods, lookingForText: lookingForText)
    }

    private var hasOfferCandidates: Bool {
        !orderedOfferGoods.isEmpty
    }

    private func startProposal() {
        let verdict = HomeConditionVerdictPolicy.make(
            from: selection.signals,
            partnerPaymentNote: selection.goods.ownerPaymentNote
        )
        let suggestedMessage = ProposalSuggestedMessageBuilder.make(from: verdict)

        // 在庫が無い場合は提示物未選択のまま打診フロー1/3へ（求シートと同じ作法）。
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
            offerGoods: orderedOfferGoods
        ) else {
            return
        }
        proposalSelection.suggestedMessage = suggestedMessage
        let merged = proposalSelection.includingExtraSelections(addedExtraSelections)
        guard showsProposalPreview else {
            onStartProposal(merged)
            return
        }
        let receiverGoods = HomeMockGoods.orderedUniqueByID(
            [selection.goods] + addedExtraSelections.compactMap(\.receiverGoods)
        )
        proposalConfirmation = HomeProposalStartConfirmationPayload(
            proposalSelection: merged,
            receiverGoods: receiverGoods,
            senderGoods: merged.senderGoods,
            senderCashAmount: merged.cashAmount
        )
    }

    private func confirmProposalStart(_ confirmedSelection: HomeDiscoveryProposalSelection) {
        proposalConfirmation = nil
        onStartProposal(confirmedSelection)
    }
}

/// 相手の探し物の引用カード。マッチ確定でないことが伝わるトーンにする。
private struct HomeLookingForQuoteCard: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 34, height: 34)
                .background(MegrumTheme.lavender.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("この人が探しているもの")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Text("「\(text)」")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(MegrumTheme.lavender.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// 譲れる在庫がまだ無い時の案内。
private struct HomeLookingForNoInventoryPanel: View {
    var lookingForText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("あなたの在庫に出せるグッズがありません")
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("「\(lookingForText)」に近いグッズを持っていれば、マイグッズに登録すると打診できます。そのまま打診して相談することもできます。")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// 探し物テキストと手持ちグッズの関連度順ソート（純ロジック・テスト可能）。
enum HomeLookingForOfferOrdering {
    /// 関連ヒット（タイトル・メンバー・グループ・種別・シリーズの部分一致）を先頭に、残りは元順。
    static func ordered(_ goods: [HomeMockGoods], lookingForText: String) -> [HomeMockGoods] {
        let scored = goods.enumerated().map { index, item in
            (item: item, score: relevanceScore(of: item, lookingForText: lookingForText), index: index)
        }
        return scored
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.index < rhs.index
                }
                return lhs.score > rhs.score
            }
            .map(\.item)
    }

    static func relevantCount(_ goods: [HomeMockGoods], lookingForText: String) -> Int {
        goods.filter { relevanceScore(of: $0, lookingForText: lookingForText) > 0 }.count
    }

    private static func relevanceScore(of goods: HomeMockGoods, lookingForText: String) -> Int {
        let query = normalized(lookingForText)
        guard !query.isEmpty else {
            return 0
        }
        var score = 0
        if matches(query, normalized(goods.title)) {
            score += 4
        }
        if let member = goods.memberName, matches(query, normalized(member)) {
            score += 3
        }
        if goods.rawTagNames.contains(where: { matches(query, normalized($0)) }) {
            score += 2
        }
        if let group = goods.groupName, matches(query, normalized(group)) {
            score += 1
        }
        if let type = goods.goodsTypeName, matches(query, normalized(type)) {
            score += 1
        }
        return score
    }

    /// どちらかがどちらかを含めばヒット（「サナのトレカ」vs「トレカ」の両方向を拾う）。
    private static func matches(_ query: String, _ target: String) -> Bool {
        guard !target.isEmpty else {
            return false
        }
        return query.contains(target) || target.contains(query)
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
