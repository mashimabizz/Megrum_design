import MegrumDesign
import SwiftUI

enum HomeDiscoverySummarySectionMetrics {
    /// ホームの各マッチセクションに表示する上位件数（超過分はすべて見る）。
    static let displayLimit = 3
}

enum HomeDiscoverySeeAllRoute: String, Identifiable, Sendable {
    case userTag
    case user

    var id: String { rawValue }

    var title: String {
        switch self {
        case .userTag: "推し×シリーズでマッチ"
        case .user: "推しでマッチ"
        }
    }

    var cardTitleStyle: HomeDiscoveryCardTitleStyle {
        switch self {
        case .userTag: .memberTag
        case .user: .member
        }
    }

}

/// 「すべて見る」から開く、セクション全候補の一覧シート。
struct HomeDiscoverySeeAllSheet: View {
    var route: HomeDiscoverySeeAllRoute
    var candidates: [HomeDiscoveryCandidate]
    var viewerGoodsImageURLByID: [UUID: URL] = [:]
    var onSelect: (HomeDiscoverySheet) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                        if index > 0 {
                            HomeDiscoveryRowSeparator()
                        }
                        HomeDiscoveryCandidateSummaryRow(
                            candidate: candidate,
                            titleStyle: route.cardTitleStyle,
                            viewerGoodsImageURLByID: viewerGoodsImageURLByID,
                            onSelect: onSelect
                        )
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(route.title)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
