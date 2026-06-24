import MegrumDesign
import SwiftUI

struct HomeListingTimelinePage: View {
    var contentTopPadding: CGFloat

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                VStack(spacing: 12) {
                    ForEach(0..<HomeListingTimelinePresentation.placeholderRowCount, id: \.self) { index in
                        HomeListingTimelinePlaceholderRow(index: index)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, contentTopPadding)
            .padding(.bottom, FloatingActionLayoutMetrics.contentBottomPadding)
        }
        .accessibilityLabel(HomeListingTimelinePresentation.title)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(HomeListingTimelinePresentation.title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer(minLength: 12)

            Text(HomeListingTimelinePresentation.sortLabel)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.conditionExact)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(MegrumTheme.conditionExact.opacity(0.10), in: Capsule())
        }
    }
}

enum HomeListingTimelinePresentation {
    static let title = "募集タイムライン"
    static let sortLabel = "新着順"
    static let placeholderRowCount = 3
}

private struct HomeListingTimelinePlaceholderRow: View {
    var index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(MegrumTheme.lavender.opacity(0.14))
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 7) {
                    placeholder(width: index.isMultiple(of: 2) ? 132 : 112, height: 12)
                    placeholder(width: index.isMultiple(of: 2) ? 94 : 124, height: 9)
                }

                Spacer(minLength: 12)

                placeholder(width: 42, height: 10)
            }

            HStack(spacing: 10) {
                placeholderBlock()
                placeholderBlock()
                placeholderBlock()
            }
        }
        .padding(14)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private func placeholder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(MegrumTheme.ink.opacity(0.085))
            .frame(width: width, height: height)
    }

    private func placeholderBlock() -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(MegrumTheme.canvas)
            .frame(height: 70)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.055), lineWidth: 1)
            }
    }
}
