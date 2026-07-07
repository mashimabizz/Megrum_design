import MegrumDesign
import SwiftUI

/// 候補シートの「他にも交換できそうなもの」用に、同じ相手の他の候補をホームと同じ tier で束ねたもの。iter1226.383 / FB6-1。
struct HomeOtherExchangeCandidateGroups {
    var tagCandidates: [HomeDiscoveryCandidate]
    var memberCandidates: [HomeDiscoveryCandidate]
    var viewerGoodsImageURLByID: [UUID: URL]

    static let empty = HomeOtherExchangeCandidateGroups(
        tagCandidates: [],
        memberCandidates: [],
        viewerGoodsImageURLByID: [:]
    )

    var isEmpty: Bool {
        tagCandidates.isEmpty && memberCandidates.isEmpty
    }
}

/// 候補シート下部の「他にも交換できそうなもの」。同じ相手の他の候補を、ホーム画面と同じ
/// 「推し×シリーズでマッチ」「推しでマッチ」の2セクション（summaryRows）で並べる。iter1226.383 / FB6-1。
/// 候補タップは onOpenNestedSheet で入れ子シートを開く（そこではこのセクションは出さない）。
struct HomeSamePartnerExchangeSection: View {
    var groups: HomeOtherExchangeCandidateGroups
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("他にも交換できそうなもの")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                if !groups.tagCandidates.isEmpty {
                    HomeDiscoverySection(
                        title: "推し×シリーズでマッチ",
                        candidates: groups.tagCandidates,
                        layout: .summaryRows,
                        cardTitleStyle: .memberTag,
                        showsSeeAllButton: false,
                        displayLimit: HomeDiscoverySummarySectionMetrics.displayLimit,
                        viewerGoodsImageURLByID: groups.viewerGoodsImageURLByID,
                        onSelect: onOpenNestedSheet
                    )
                }

                if !groups.memberCandidates.isEmpty {
                    HomeDiscoverySection(
                        title: "推しでマッチ",
                        candidates: groups.memberCandidates,
                        layout: .summaryRows,
                        cardTitleStyle: .member,
                        showsSeeAllButton: false,
                        displayLimit: HomeDiscoverySummarySectionMetrics.displayLimit,
                        viewerGoodsImageURLByID: groups.viewerGoodsImageURLByID,
                        onSelect: onOpenNestedSheet
                    )
                }
            }
        }
    }
}
