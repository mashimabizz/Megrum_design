import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardScopeSelector: View {
    var selectedScope: BoardThread.Audience
    var prefectureTitle: String
    var onNearbyTap: () -> Void
    var onPrefectureTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onNearbyTap) {
                scopeChip(
                    title: "1km圏内",
                    systemImage: "location.fill",
                    isSelected: selectedScope == .nearby3km
                )
            }
            .buttonStyle(.plain)

            Button(action: onPrefectureTap) {
                scopeChip(
                    title: prefectureTitle,
                    systemImage: "map.fill",
                    isSelected: selectedScope == .samePrefecture
                )
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .contain)
    }

    private func scopeChip(title: String, systemImage: String, isSelected: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(isSelected ? .white.opacity(0.28) : MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: isSelected ? MegrumTheme.lavender.opacity(0.22) : MegrumTheme.ink.opacity(0.05), radius: 10, y: 5)
    }
}
