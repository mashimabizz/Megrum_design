import MegrumDesign
import SwiftUI

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
