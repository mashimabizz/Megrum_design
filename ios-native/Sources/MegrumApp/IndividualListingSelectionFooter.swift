import MegrumDesign
import SwiftUI

struct IndividualListingSelectionFooter: View {
    var selectedCount: Int
    var onDelete: () -> Void
    var onCancel: () -> Void

    var body: some View {
        MegrumGlassGroup(spacing: GoodsSelectionFooterMetrics.actionSpacing) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Text("\(selectedCount)件を選択中")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Button("解除", action: onCancel)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Button(role: .destructive) {
                    MegrumHaptics.performButtonTap(onDelete)
                } label: {
                    Label("削除する", systemImage: "trash")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity, minHeight: GoodsSelectionFooterMetrics.actionHeight)
                        .background(Color.white.opacity(0.18), in: Capsule())
                        .megrumLiquidGlass(
                            .capsule,
                            tint: Color.red.opacity(0.12),
                            interactive: true
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GoodsSelectionFooterMetrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GoodsSelectionFooterMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 20, y: 12)
            .megrumLiquidGlass(
                .rounded(cornerRadius: GoodsSelectionFooterMetrics.cornerRadius),
                tint: Color.white.opacity(0.16)
            )
        }
    }
}
