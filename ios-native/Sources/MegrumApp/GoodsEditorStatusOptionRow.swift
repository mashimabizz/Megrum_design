import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsEditorStatusOptionRow: View {
    var status: GoodsEditorStatus
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isSelected ? .white : MegrumTheme.lavender)
                .frame(width: 34, height: 34)
                .background(
                    isSelected ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.12),
                    in: Circle()
                )
            Text(status.title)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
