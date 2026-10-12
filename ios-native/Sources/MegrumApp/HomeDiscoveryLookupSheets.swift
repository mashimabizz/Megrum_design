import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// 「求められているグッズ」一覧（iter1226.410 刷新）：
/// この画面の目的は「このグッズを一番欲しがっているのは誰か」なので、
/// マッチ経路（推し×シリーズ/推し）ではなく**需要の強さでグルーピング**する。
/// 経路はスタイル（行タイトルの塊ラベル）として残し、選んだグッズは大カード→コンパクト行に降格。
struct HomeHavesLookupSheet: View {
    var payload: HomeHavesLookupPayload
    var viewerGoodsImageURLByID: [UUID: URL] = [:]
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        HomeSheetScaffold(bottomButton: nil) {
            HomeHavesSelectedGoodsCompactRow(
                goods: payload.offeredGoods,
                candidateCount: rankedCandidates.count
            )

            if payload.hasAnyMatches {
                ForEach(demandSections) { section in
                    HomeHavesDemandSection(
                        section: section,
                        viewerGoodsImageURLByID: viewerGoodsImageURLByID,
                        onOpenNestedSheet: onOpenNestedSheet
                    )
                }
            } else {
                HomeHavesEmptyMatchPanel()
            }
        }
    }

    // MARK: - 需要グルーピング

    private var rankedCandidates: [HomeHavesRankedCandidate] {
        HomeHavesDemandGrouping.rankedCandidates(
            tagMatched: payload.shouldShowTagMatches ? payload.tagMatchedCandidates : [],
            memberMatched: payload.memberMatchedCandidates
        )
    }

    private var demandSections: [HomeHavesDemandSectionModel] {
        HomeHavesDemandGrouping.sections(from: rankedCandidates)
    }
}

/// 経路スタイル付き候補＋需要ランク。
struct HomeHavesRankedCandidate: Identifiable {
    var candidate: HomeDiscoveryCandidate
    var titleStyle: HomeDiscoveryCardTitleStyle
    var rank: Int

    var id: UUID { candidate.id }
}

struct HomeHavesDemandSectionModel: Identifiable {
    var title: String
    var tier: HomeHavesDemandTier
    var candidates: [HomeHavesRankedCandidate]

    var id: String { title }
}

enum HomeHavesDemandTier {
    case hot
    case wanted
    case other
}

/// 需要ランクへの振り分け（純ロジック・テスト可能）。
enum HomeHavesDemandGrouping {
    /// 推し×シリーズ→推しの順で重複を除いて統合し、需要ランク降順（同ランクは元順）に並べる。
    static func rankedCandidates(
        tagMatched: [HomeDiscoveryCandidate],
        memberMatched: [HomeDiscoveryCandidate]
    ) -> [HomeHavesRankedCandidate] {
        var seen = Set<UUID>()
        var merged: [HomeHavesRankedCandidate] = []
        for candidate in tagMatched where seen.insert(candidate.id).inserted {
            merged.append(
                HomeHavesRankedCandidate(
                    candidate: candidate,
                    titleStyle: .memberTag,
                    rank: HomeCandidateDemandPolicy.bestDemandRank(of: candidate)
                )
            )
        }
        for candidate in memberMatched where seen.insert(candidate.id).inserted {
            merged.append(
                HomeHavesRankedCandidate(
                    candidate: candidate,
                    titleStyle: .member,
                    rank: HomeCandidateDemandPolicy.bestDemandRank(of: candidate)
                )
            )
        }
        return merged
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.rank == rhs.element.rank {
                    return lhs.offset < rhs.offset
                }
                return lhs.element.rank > rhs.element.rank
            }
            .map(\.element)
    }

    /// 超求（rank5以上）＞求（rank3-4）＞その他 の3セクション。空セクションは出さない。
    static func sections(from ranked: [HomeHavesRankedCandidate]) -> [HomeHavesDemandSectionModel] {
        let hot = ranked.filter { $0.rank >= 5 }
        let wanted = ranked.filter { (3...4).contains($0.rank) }
        let other = ranked.filter { $0.rank < 3 }
        return [
            HomeHavesDemandSectionModel(title: "超求！している人", tier: .hot, candidates: hot),
            HomeHavesDemandSectionModel(title: "求めている人", tier: .wanted, candidates: wanted),
            HomeHavesDemandSectionModel(title: "その他のマッチ", tier: .other, candidates: other),
        ]
        .filter { !$0.candidates.isEmpty }
    }
}

/// 需要セクション（見出し＋summaryRow列）。見出し色は需要行の配色（超求=ピンクグラデ/求=ラベンダー）と揃える。
private struct HomeHavesDemandSection: View {
    var section: HomeHavesDemandSectionModel
    var viewerGoodsImageURLByID: [UUID: URL]
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                titleText
                Text("\(section.candidates.count)人")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            VStack(spacing: 0) {
                ForEach(Array(section.candidates.enumerated()), id: \.element.id) { index, ranked in
                    if index > 0 {
                        HomeDiscoveryRowSeparator()
                    }
                    HomeDiscoveryCandidateSummaryRow(
                        candidate: ranked.candidate,
                        titleStyle: ranked.titleStyle,
                        viewerGoodsImageURLByID: viewerGoodsImageURLByID,
                        onSelect: onOpenNestedSheet
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var titleText: some View {
        switch section.tier {
        case .hot:
            Text(section.title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.accentGradient)
        case .wanted:
            Text(section.title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
        case .other:
            Text(section.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

/// 選んだグッズのコンパクト行（旧・大カードの降格版）。
private struct HomeHavesSelectedGoodsCompactRow: View {
    var goods: HomeMockGoods
    var candidateCount: Int

    var body: some View {
        HStack(spacing: 12) {
            HomeTinyGoodsThumbnail(goods: goods)
                .frame(width: 46, height: 46)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(goods.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(candidateCount > 0 ? "このグッズを求めている人：\(candidateCount)人" : "このグッズを求めている人")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }
}

private struct HomeHavesEmptyMatchPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
            Text("一致する候補はまだありません")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("このグッズを欲しがっている相手が見つかったらここに表示されます。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

struct HomeExtraHitDetailSheet: View {
    var payload: HomeExtraHitPayload
    var viewerOfferGoods: [HomeMockGoods]
    var onClose: (() -> Void)?
    var onOpenOwnerProfile: (UUID) -> Void

    var body: some View {
        HomeSheetScaffold(
            bottomButton: nil,
            dismissAction: onClose
        ) {
            HomeSelectedGoodsHeader(
                title: "他にも交換できそうなグッズ",
                goods: payload.goods,
                conditionTags: payload.conditionTags,
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(payload.signals),
                conditionVerdict: HomeConditionVerdictPolicy.make(
                    from: payload.signals,
                    partnerPaymentNote: payload.goods.ownerPaymentNote
                ),
                listingNote: payload.individualListingSelection.listingNote,
                listingDetail: payload.individualListingSelection.detail,
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "line.3.horizontal.decrease.circle",
                title: "交換条件",
                trailing: selectionRequirementLabel
            )
            wantedSelectionRail
        }
    }

    private var wantedGoods: [HomeMockGoods] {
        HomeDiscoveryFixtures.wantedGoods
    }

    private var wantedOptions: [HomeIndividualListingWantedOption] {
        payload.individualListingSelection.wantedOptions
    }

    private var usesListingWantedOptions: Bool {
        !wantedOptions.isEmpty
    }

    private var allOfferGoods: [HomeMockGoods] {
        viewerOfferGoods.isEmpty ? HomeDiscoveryFixtures.offerGoods : viewerOfferGoods
    }

    private var wantedLogic: ListingLogic {
        payload.individualListingSelection.wantedLogic
    }

    private var selectionRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: wantedLogic)
    }

    @ViewBuilder
    private var wantedSelectionRail: some View {
        if usesListingWantedOptions {
            HomeListingWantedOptionRail(
                options: wantedOptions,
                selectedIndices: [],
                previewGoodsByOptionID: previewGoodsByWantedOptionID,
                isSelectionEnabled: false,
                onSelect: { _ in }
            )
        } else {
            HomeGoodsImagePanelRail(
                goods: wantedGoods,
                selectedIndices: [],
                onSelect: { _ in }
            )
        }
    }

    private var previewGoodsByWantedOptionID: [UUID: HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.previewGoodsByOptionID(
            options: wantedOptions,
            goodsPool: wantedOptionPreviewGoodsPool
        )
    }

    private var wantedOptionPreviewGoodsPool: [HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.uniqueGoodsPool([
            allOfferGoods,
            wantedGoods,
            HomeDiscoveryFixtures.offerGoods,
            HomeDiscoveryFixtures.wantedGoods,
            [payload.goods]
        ])
    }
}
