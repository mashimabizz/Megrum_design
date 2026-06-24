import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchResultSection: View {
    var results: [SearchResultItem]
    var bucket: SearchMatchBucket
    var viewerID: UUID?
    var onStartProposal: (GoodsItem) -> Void
    var onOpenOwnerProfile: (UUID) -> Void
    var onReportItem: (GoodsItem, GoodsReportReason, String) -> Void

    var body: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(bucket.displayName)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Text("\(results.count)件")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                GoodsGrid(
                    items: results.map(\.item),
                    viewerID: viewerID,
                    onOpenOwnerProfile: onOpenOwnerProfile,
                    onAddToExchangeList: onStartProposal,
                    onReportItem: onReportItem
                )
            }
        }
    }
}

struct SearchEmptyMessage: View {
    var body: some View {
        Text("検索に合うグッズがありません")
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 1)
            }
    }
}

struct SearchIdleMessage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("条件を入れて検索")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            } icon: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            Text("キーワードを入力するか、絞り込みでグループやグッズ種別を選ぶと結果を表示します。")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        }
    }
}

struct SearchResultSkeleton: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.76), lineWidth: 1)
                    )
                    .aspectRatio(0.78, contentMode: .fit)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

struct SearchResultToolbar: View {
    var resultCount: Int
    var isSearching: Bool
    @Binding var sort: SearchResultSort

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(resultCount)件")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            if isSearching {
                ProgressView()
                    .controlSize(.small)
            }
            Spacer()
            Menu {
                ForEach(SearchResultSort.allCases) { option in
                    Button(option.displayName) {
                        sort = option
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(sort.displayName)
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            }
        }
    }
}

struct SearchActiveCriteriaChips: View {
    var chips: [SearchActiveCriteriaChipItem]
    var onRemove: (SearchActiveCriteriaRemoval) -> Void

    var body: some View {
        if !chips.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(chips) { chip in
                        SearchActiveCriteriaChip(chip: chip, onRemove: onRemove)
                    }
                }
                .padding(.top, 7)
                .padding(.trailing, 8)
            }
        }
    }
}

private struct SearchActiveCriteriaChip: View {
    var chip: SearchActiveCriteriaChipItem
    var onRemove: (SearchActiveCriteriaRemoval) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(chip.title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(foreground)
                .padding(.leading, 16)
                .padding(.trailing, 20)
                .frame(height: 38)
                .background(background, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(border, lineWidth: 1)
                }

            Button {
                onRemove(chip.removal)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(foreground, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.92), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .offset(x: 5, y: -6)
            .accessibilityLabel("\(chip.title)を削除")
        }
        .padding(.top, 6)
        .padding(.trailing, 5)
    }

    private var foreground: Color {
        if chip.title.contains("グッズ") {
            return MegrumTheme.conditionExact
        }
        if chip.title.contains("条件") {
            return Color(red: 0.35, green: 0.52, blue: 0.72)
        }
        return MegrumTheme.lavender
    }

    private var background: Color {
        if chip.title.contains("グッズ") {
            return MegrumTheme.pink.opacity(0.18)
        }
        if chip.title.contains("条件") {
            return MegrumTheme.sky.opacity(0.24)
        }
        return MegrumTheme.lavender.opacity(0.16)
    }

    private var border: Color {
        foreground.opacity(0.22)
    }
}

struct SearchResultQuerySummary: View {
    var summaryTitles: [String]
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)

                Text(summaryText)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.68), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("現在の検索条件")
    }

    private var summaryText: String {
        summaryTitles.isEmpty ? "条件を追加" : summaryTitles.prefix(4).joined(separator: " / ")
    }
}
