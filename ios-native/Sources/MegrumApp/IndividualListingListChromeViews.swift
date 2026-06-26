import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingTopBar: View {
    var title: String
    var accessory: AnyView?

    var body: some View {
        if let accessory {
            IndividualListingAccessoryTopBar(title: title, accessory: accessory)
        } else {
            IndividualListingCenteredTopBar()
        }
    }
}

private struct IndividualListingAccessoryTopBar: View {
    var title: String
    var accessory: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            accessory
                .padding(.top, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
                .padding(.bottom, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct IndividualListingCenteredTopBar: View {
    var body: some View {
        HStack(alignment: .center) {
            IndividualListingBackPlaceholder()

            Spacer()

            VStack(spacing: 5) {
                Text("個別募集")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("譲るものごとに条件を見る")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer()

            IndividualListingMorePlaceholder()
        }
    }
}

private struct IndividualListingBackPlaceholder: View {
    var body: some View {
        Button {} label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 50, height: 50)
                .background(.white.opacity(0.88), in: Circle())
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
        .opacity(0.001)
    }
}

private struct IndividualListingMorePlaceholder: View {
    var body: some View {
        Image(systemName: "ellipsis")
            .font(.system(size: 21, weight: .black))
            .foregroundStyle(MegrumTheme.ink)
            .frame(width: 50, height: 50)
            .background(.white.opacity(0.88), in: Circle())
            .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 6)
            .accessibilityHidden(true)
    }
}

struct IndividualListingSkeletons: View {
    var body: some View {
        VStack(spacing: 22) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(height: 430)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

struct IndividualListingConditionStrip: View {
    var listings: [IndividualListing]
    @Binding var activeListingID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(Array(listings.enumerated()), id: \.element.id) { index, listing in
                    IndividualListingConditionStripCard(
                        index: index,
                        totalCount: listings.count,
                        isSelected: activeListingID == listing.id
                    ) {
                        withAnimation(.smooth(duration: 0.22)) {
                            activeListingID = listing.id
                        }
                    }
                    .id(listing.id)
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 2)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $activeListingID)
        .accessibilityLabel("交換条件の切り替え")
    }
}

private struct IndividualListingConditionStripCard: View {
    var index: Int
    var totalCount: Int
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                Text("交換条件 \(index + 1)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("\(index + 1)/\(max(1, totalCount))")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.92) : MegrumTheme.lavender)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .frame(width: 136, height: 74, alignment: .leading)
            .background(
                isSelected ? MegrumTheme.lavender : Color.white.opacity(0.88),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? MegrumTheme.lavender.opacity(0.35) : MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: isSelected ? MegrumTheme.lavender.opacity(0.20) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("交換条件\(index + 1)")
        .accessibilityValue(isSelected ? "選択中" : "\(totalCount)件中\(index + 1)件目")
    }
}

struct EmptyListingView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(MegrumTheme.lavender)
            Text("個別募集はまだありません")
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text("マイグッズとWishを選んで、ピンポイントの交換条件を作れます。")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        }
    }
}

struct AddIndividualListingButton: View {
    var title: String = "募集を追加"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.20), in: Circle())
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.sky],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.65), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
