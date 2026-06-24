import MegrumDesign
import SwiftUI

struct HomeMutualMatchPage: View {
    var candidates: [HomeMutualMatchCandidate]
    var listingCount: Int = 0
    var contentTopPadding: CGFloat
    var onSelect: (HomeMutualMatchCandidate) -> Void
    var onCreateListing: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if candidates.isEmpty {
                    HomeMutualMatchEmptyStateView(
                        presentation: HomeMutualMatchEmptyStatePresentation(listingCount: listingCount),
                        onCreateListing: onCreateListing
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(candidates) { candidate in
                            HomeMutualMatchCard(candidate: candidate, onSelect: onSelect)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, contentTopPadding)
            .padding(.bottom, FloatingActionLayoutMetrics.contentBottomPadding)
        }
    }
}

private struct HomeMutualMatchCard: View {
    var candidate: HomeMutualMatchCandidate
    var onSelect: (HomeMutualMatchCandidate) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 11) {
                HomeMutualMatchUserHeader(candidate: candidate)

                TradeDealGoodsPanel(
                    offeredItems: candidate.viewerGoodsItems,
                    requestedItems: candidate.partnerGoodsItems,
                    offeredBadgeTitle: candidate.offeredGoodsBadgeTitle,
                    requestedBadgeTitle: candidate.requestedGoodsBadgeTitle
                )

                HomeMutualAttentionTagRow(tags: candidate.attentionTags)
            }
            .padding(.vertical, 16)

            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.065))
                .frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(candidate)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onSelect(candidate)
        }
        .accessibilityLabel("\(candidate.partnerName)さんと相互にマッチ")
        .accessibilityHint("タップで同じ相手との他の候補を見ます。")
    }
}

private struct HomeMutualMatchUserHeader: View {
    var candidate: HomeMutualMatchCandidate

    var body: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(MegrumTheme.lavender.opacity(0.12))
                .frame(width: 24, height: 24)
                .overlay {
                    Text(candidate.partnerInitial)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(candidate.partnerName)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)

                    Text("@\(candidate.partnerHandle)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.78))
                        .lineLimit(1)
                }

                Text(candidate.partnerMetaText)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 10)
        }
    }
}

private struct HomeMutualAttentionTagRow: View {
    var tags: [HomeMutualMatchAttentionTag]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags) { tag in
                Label(tag.title, systemImage: tag.systemImage)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(tag.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tag.tint.opacity(0.10), in: Capsule())
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
