import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalGoodsFilterBar: View {
    var groupChoices: [ProposalFilterChoice]
    var goodsTypeChoices: [ProposalFilterChoice]
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: ProposalGoodsFilterMetrics.rowSpacing) {
            ProposalFilterRow(
                title: "推し",
                choices: groupChoices,
                selectedID: $selectedGroupID
            )
            ProposalFilterRow(
                title: "種別",
                choices: goodsTypeChoices,
                selectedID: $selectedGoodsTypeID
            )
        }
    }
}

struct ProposalFilterChoice: Identifiable, Equatable {
    var id: UUID
    var title: String
}

private struct ProposalFilterRow: View {
    var title: String
    var choices: [ProposalFilterChoice]
    @Binding var selectedID: UUID?

    var body: some View {
        if !choices.isEmpty {
            HStack(alignment: .center, spacing: ProposalGoodsFilterMetrics.chipSpacing) {
                Text(title)
                    .font(.system(size: ProposalGoodsFilterMetrics.labelFontSize, weight: .black, design: .rounded))
                    .tracking(ProposalGoodsFilterMetrics.labelTracking)
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: ProposalGoodsFilterMetrics.labelWidth, alignment: .trailing)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ProposalGoodsFilterMetrics.chipSpacing) {
                        ProposalFilterChip(title: "すべて", isSelected: selectedID == nil) {
                            selectedID = nil
                        }
                        ForEach(choices) { choice in
                            ProposalFilterChip(title: choice.title, isSelected: selectedID == choice.id) {
                                selectedID = choice.id
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }
}

private struct ProposalFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: ProposalGoodsFilterMetrics.chipFontSize, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, ProposalGoodsFilterMetrics.chipHorizontalPadding)
                .padding(.vertical, ProposalGoodsFilterMetrics.chipVerticalPadding)
                .background(isSelected ? MegrumTheme.lavender : Color.white.opacity(0.74), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? MegrumTheme.lavender.opacity(0.5) : .white.opacity(0.68), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ProposalSelectableGoodsRow: View {
    var item: GoodsItem
    var isSelected: Bool
    var hintText: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: ProposalSelectableGoodsRowMetrics.rowSpacing) {
            RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.thumbnailCornerRadius, style: .continuous)
                .fill(ProposalSelectableGoodsRowStyle.thumbnailColor(for: item))
                .frame(
                    width: ProposalSelectableGoodsRowMetrics.thumbnailWidth,
                    height: ProposalSelectableGoodsRowMetrics.thumbnailHeight
                )
                .overlay {
                    if let imageURL = item.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            case .empty:
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: ProposalSelectableGoodsRowMetrics.thumbnailCornerRadius,
                                style: .continuous
                            )
                        )
                    } else {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.25))
                                .frame(
                                    width: ProposalSelectableGoodsRowMetrics.thumbnailShineSize,
                                    height: ProposalSelectableGoodsRowMetrics.thumbnailShineSize
                                )
                                .offset(
                                    x: ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetX,
                                    y: ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetY
                                )
                            Text(ProposalSelectableGoodsRowStyle.glyph(for: item))
                                .font(.system(size: ProposalSelectableGoodsRowMetrics.glyphFontSize, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                if !subtitleText.isEmpty {
                    Text(subtitleText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }
                Text(hintText)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.sky)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(MegrumTheme.sky.opacity(0.22), in: Capsule())
            }

            Spacer()

            ProposalSelectableGoodsCheckmark(isSelected: isSelected)
        }
        .padding(ProposalSelectableGoodsRowMetrics.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            rowBackground,
            in: RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous)
                .stroke(rowBorderColor, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous))
        .onTapGesture(perform: action)
        .accessibilityLabel(item.title)
        .accessibilityValue(isSelected ? "選択中" : "未選択")
        .accessibilityAddTraits(.isButton)
    }

    private var subtitleText: String {
        item.tags.map(\.name).prefix(2).joined(separator: " / ")
    }

    private var rowBackground: Color {
        isSelected ? MegrumTheme.lavender.opacity(ProposalSelectableGoodsRowMetrics.selectedBackgroundOpacity) : .white
    }

    private var rowBorderColor: Color {
        isSelected
            ? MegrumTheme.lavender.opacity(ProposalSelectableGoodsRowMetrics.selectedBorderOpacity)
            : MegrumTheme.ink.opacity(ProposalSelectableGoodsRowMetrics.defaultBorderOpacity)
    }
}

private struct ProposalSelectableGoodsCheckmark: View {
    var isSelected: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? MegrumTheme.lavender : Color.clear)
            .frame(
                width: ProposalSelectableGoodsRowMetrics.checkCircleSize,
                height: ProposalSelectableGoodsRowMetrics.checkCircleSize
            )
            .overlay {
                Circle()
                    .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.16), lineWidth: 1)
            }
            .overlay {
                if isSelected {
                    Text("✓")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
    }
}

enum ProposalSelectableGoodsRowStyle {
    static func glyph(for item: GoodsItem) -> String {
        if item.title.contains("カリナ") {
            return "K"
        }
        if item.title.contains("ジョンウ") {
            return "J"
        }
        if item.title.contains("スア") {
            return "S"
        }
        if item.title.contains("ニンニン") {
            return "N"
        }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func thumbnailColor(for item: GoodsItem) -> Color {
        if item.title.contains("ジョンウ") || item.title.contains("ニンニン") {
            return MegrumTheme.sky.opacity(0.72)
        }
        if item.title.contains("スア") {
            return MegrumTheme.lavender.opacity(0.64)
        }
        return MegrumTheme.pink.opacity(0.68)
    }
}

private struct ProposalReceiveCard: View {
    var targetItem: GoodsItem
    var receiverGoodsCount: Int
    var isListingSource: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MegrumTheme.sky.opacity(0.24))
                    .frame(width: 76, height: 90)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(targetItem.title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(2)
                    Text(isListingSource ? "個別募集から選択" : "相手のマイグッズから選択")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    if receiverGoodsCount > 1 {
                        Text("ほか\(receiverGoodsCount - 1)件も条件に含まれます")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
            }

            Label("受け取る内容はこのステップで固定されています", systemImage: "lock.fill")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.68), lineWidth: 1)
        }
    }
}
