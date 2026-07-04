import MegrumDesign
import SwiftUI

enum HomeDiscoverySectionLayout: Equatable {
    case grid
    case rail
    /// 案2：1カラムの「扇状カード＋塊ラベル・強タグ・結論一文」行。
    /// 全セクション同一構造（画像左・テキスト左揃え）で比較しやすさを優先。
    case summaryRows
}

struct HomeDiscoverySection: View {
    var title: String
    var candidates: [HomeDiscoveryCandidate]
    var layout: HomeDiscoverySectionLayout
    var cardTitleStyle: HomeDiscoveryCardTitleStyle = .plain
    var showsGridHeaderTitle = true
    var showsSeeAllButton = false
    /// summaryRows で表示する最大行数（超過分は「すべて見る」で開く想定）。
    var displayLimit: Int? = nil
    var onSelect: (HomeDiscoverySheet) -> Void
    var onSearchCandidate: (HomeDiscoveryCandidate, HomeMockGoods?) -> Void = { _, _ in }
    /// 「すべて見る」タップ時の遷移。未指定時は従来どおり先頭候補のシートを開く。
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            HomeDiscoverySectionHeader(
                title: title,
                layout: layout,
                showsGridHeaderTitle: showsGridHeaderTitle,
                showsSeeAllButton: showsSeeAllButton,
                isSeeAllDisabled: candidates.isEmpty,
                onSeeAll: onSeeAll ?? openFirstCandidate
            )

            switch layout {
            case .grid:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 22), GridItem(.flexible(), spacing: 22)], spacing: 14) {
                    ForEach(displayedCandidates) { candidate in
                        HomeDiscoveryCandidateButton(
                            candidate: candidate,
                            titleStyle: cardTitleStyle,
                            cardHeight: 170,
                            onSelect: onSelect,
                            onSearch: onSearchCandidate
                        )
                    }
                }
            case .rail:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(displayedCandidates) { candidate in
                            HomeHavesCandidateButton(
                                candidate: candidate,
                                onSelect: onSelect
                            )
                            .frame(width: 94)
                        }
                    }
                    .padding(.trailing, 20)
                }
            case .summaryRows:
                VStack(spacing: 14) {
                    ForEach(displayedCandidates) { candidate in
                        HomeDiscoveryCandidateSummaryRow(
                            candidate: candidate,
                            titleStyle: cardTitleStyle,
                            onSelect: onSelect,
                            onSearch: onSearchCandidate
                        )
                    }
                }
            }
        }
        .padding(.bottom, layout == .rail ? 6 : 8)
    }

    private var displayedCandidates: [HomeDiscoveryCandidate] {
        guard let displayLimit else {
            return candidates
        }
        return Array(candidates.prefix(displayLimit))
    }

    private var sectionSpacing: CGFloat {
        switch layout {
        case .grid: 8
        case .rail: 10
        case .summaryRows: 10
        }
    }

    private func openFirstCandidate() {
        if let firstCandidate = candidates.first {
            onSelect(firstCandidate.sheet)
        }
    }
}

private struct HomeDiscoverySectionHeader: View {
    var title: String
    var layout: HomeDiscoverySectionLayout
    var showsGridHeaderTitle: Bool
    var showsSeeAllButton: Bool
    var isSeeAllDisabled: Bool
    var onSeeAll: () -> Void

    var body: some View {
        HStack {
            if layout == .rail || showsGridHeaderTitle {
                Text(title)
                    .font(.system(size: layout == .rail ? 20 : 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            if showsSeeAllButton {
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text("すべて見る")
                            .font(.system(size: seeAllFontSize, weight: .heavy))
                        Image(systemName: "chevron.right")
                            .font(.system(size: seeAllFontSize, weight: .black))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                }
                .buttonStyle(.plain)
                .disabled(isSeeAllDisabled)
            }
        }
        .frame(minHeight: layout == .rail ? 24 : 18)
    }

    private var seeAllFontSize: CGFloat {
        if case .summaryRows = layout {
            return 12.5
        }
        return 14
    }
}
