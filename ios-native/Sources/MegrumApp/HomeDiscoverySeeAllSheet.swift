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

    var mirrored: Bool {
        self == .user
    }

    var cardTitleStyle: HomeDiscoveryCardTitleStyle {
        switch self {
        case .userTag: .memberTag
        case .user: .member
        }
    }

    var searchSource: HomeDiscoveryCandidateSource {
        switch self {
        case .userTag: .userTag
        case .user: .user
        }
    }
}

/// 「すべて見る」から開く、セクション全候補の一覧シート。
struct HomeDiscoverySeeAllSheet: View {
    var route: HomeDiscoverySeeAllRoute
    var candidates: [HomeDiscoveryCandidate]
    var onSelect: (HomeDiscoverySheet) -> Void
    var onSearch: (HomeDiscoveryCandidate, HomeMockGoods?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(candidates) { candidate in
                        HomeDiscoveryCandidateSummaryRow(
                            candidate: candidate,
                            titleStyle: route.cardTitleStyle,
                            mirrored: route.mirrored,
                            onSelect: onSelect,
                            onSearch: onSearch
                        )
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
