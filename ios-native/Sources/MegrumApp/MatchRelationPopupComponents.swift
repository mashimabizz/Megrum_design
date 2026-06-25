import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationMiniAvatar: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title.prefix(1).uppercased())
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(color, in: Circle())
    }
}

struct MatchRelationPopupCandidateButton: View {
    var candidate: MatchRelationCandidate
    var isSelected: Bool
    var isHighlighted: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                candidatePreview
                highlightedBadge
                selectedBadge
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 82, alignment: .top)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(border)
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if isHighlighted {
            return Color(red: 1, green: 247 / 255, blue: 251 / 255)
        }
        return isSelected ? MegrumTheme.lavender.opacity(0.08) : .white
    }

    private var borderColor: Color {
        if isHighlighted {
            return MegrumTheme.pink
        }
        return isSelected ? MegrumTheme.lavender : .clear
    }

    private var borderWidth: CGFloat {
        isHighlighted || isSelected ? 2 : 0
    }

    private var candidatePreview: some View {
        VStack(alignment: .center, spacing: 0) {
            MatchRelationGoodsThumbnail(item: candidate.item, size: 56)

            Text(candidate.item.title)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .frame(maxWidth: 64)
                .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var highlightedBadge: some View {
        if isHighlighted {
            Text("選択元")
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(MegrumTheme.pink, in: Capsule())
                .offset(x: -8, y: -8)
        }
    }

    @ViewBuilder
    private var selectedBadge: some View {
        if isSelected {
            Text("✓")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(MegrumTheme.lavender, in: Circle())
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .offset(x: 8, y: -8)
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(borderColor, lineWidth: borderWidth)
    }
}
