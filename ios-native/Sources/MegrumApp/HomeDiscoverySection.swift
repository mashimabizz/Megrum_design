import MegrumDesign
import SwiftUI

enum HomeDiscoverySectionLayout {
    case grid
    case rail
}

struct HomeDiscoverySection: View {
    var title: String
    var candidates: [HomeDiscoveryCandidate]
    var layout: HomeDiscoverySectionLayout
    var cardTitleStyle: HomeDiscoveryCardTitleStyle = .plain
    var showsGridHeaderTitle = true
    var showsSeeAllButton = false
    var onSelect: (HomeDiscoverySheet) -> Void
    var onSearchCandidate: (HomeDiscoveryCandidate, HomeMockGoods?) -> Void = { _, _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: layout == .grid ? 8 : 10) {
            HomeDiscoverySectionHeader(
                title: title,
                layout: layout,
                showsGridHeaderTitle: showsGridHeaderTitle,
                showsSeeAllButton: showsSeeAllButton,
                isSeeAllDisabled: candidates.isEmpty,
                onSeeAll: openFirstCandidate
            )

            switch layout {
            case .grid:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 22), GridItem(.flexible(), spacing: 22)], spacing: 14) {
                    ForEach(candidates) { candidate in
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
                        ForEach(candidates) { candidate in
                            HomeHavesCandidateButton(
                                candidate: candidate,
                                onSelect: onSelect
                            )
                            .frame(width: 94)
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
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
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            if showsSeeAllButton {
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text("すべて見る")
                            .font(.system(size: 14, weight: .heavy))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .black))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                }
                .buttonStyle(.plain)
                .disabled(isSeeAllDisabled)
            }
        }
        .frame(minHeight: layout == .grid ? 18 : 24)
    }
}
