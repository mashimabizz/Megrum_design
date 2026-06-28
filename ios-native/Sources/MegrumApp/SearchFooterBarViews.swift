import MegrumDesign
import SwiftUI

struct SearchFooterBar: View {
    @Binding var query: String
    var activeFilterCount: Int
    var onFilterTap: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        MegrumGlassGroup(spacing: SearchLayoutMetrics.footerGlassGroupSpacing) {
            HStack(spacing: SearchLayoutMetrics.footerGlassGroupSpacing) {
                Button {
                    MegrumHaptics.performButtonTap(onFilterTap)
                } label: {
                    SearchFilterIconButtonContent(activeFilterCount: activeFilterCount)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("検索フィルター")

                SearchInputBar(query: $query, onSubmit: onSubmit)

                Button {
                    MegrumHaptics.performButtonTap(onSubmit)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(
                            LinearGradient(
                                colors: [MegrumTheme.lavender, MegrumTheme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(.white.opacity(0.76), lineWidth: 1))
                        .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 16, y: 8)
                        .megrumLiquidGlass(.circle, tint: MegrumTheme.pink.opacity(0.16), interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("検索する")
            }
        }
    }
}

private struct SearchInputBar: View {
    @Binding var query: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink)

            TextField("さがす...", text: $query)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .disableAutocorrection(true)
                .submitLabel(.search)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        .megrumLiquidGlass(.capsule, tint: MegrumTheme.sky.opacity(0.10), interactive: true)
    }
}

private struct SearchFilterIconButtonContent: View {
    var activeFilterCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 62, height: 62)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))
                .megrumLiquidGlass(.circle, tint: MegrumTheme.lavender.opacity(0.14), interactive: true)
                .zIndex(SearchFilterBadgeLayering.surfaceZIndex)

            if activeFilterCount > 0 {
                SearchFilterCountBadge(count: activeFilterCount)
                    .offset(x: 8, y: -8)
                    .zIndex(SearchFilterBadgeLayering.badgeZIndex)
            }
        }
        .frame(width: 74, height: 74, alignment: .center)
        .contentShape(Circle())
    }
}

private struct SearchFilterCountBadge: View {
    var count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 23, height: 23)
            .background(MegrumTheme.lavender, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1.4))
            .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 6, y: 3)
            .allowsHitTesting(false)
    }
}
