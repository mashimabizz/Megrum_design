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
    var isSelectionMode: Bool = false
    var selectedListingIDs: Set<UUID> = []
    var onBeginSelection: (IndividualListing) -> Void = { _ in }
    var onToggleSelection: (IndividualListing) -> Void = { _ in }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(Array(listings.enumerated()), id: \.element.id) { index, listing in
                    IndividualListingConditionStripCard(
                        index: index,
                        totalCount: listings.count,
                        isActive: activeListingID == listing.id,
                        isSelectionMode: isSelectionMode,
                        isMultiSelected: selectedListingIDs.contains(listing.id)
                    ) {
                        if isSelectionMode {
                            onToggleSelection(listing)
                        } else {
                            withAnimation(.smooth(duration: 0.22)) {
                                activeListingID = listing.id
                            }
                        }
                    } longPressAction: {
                        onBeginSelection(listing)
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
    var isActive: Bool
    var isSelectionMode: Bool
    var isMultiSelected: Bool
    var action: () -> Void
    var longPressAction: () -> Void
    @State private var didTriggerLongPress = false

    private var isHighlighted: Bool {
        isSelectionMode ? isMultiSelected : isActive
    }

    var body: some View {
        Button(action: performTap) {
            HStack(spacing: 7) {
                if isSelectionMode {
                    Image(systemName: isMultiSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }

                Text(IndividualListingListPresentation.conditionStripTitle(index: index, totalCount: totalCount))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .monospacedDigit()
            }
            .foregroundStyle(isHighlighted ? .white : MegrumTheme.ink)
            .padding(.horizontal, isSelectionMode ? 13 : 16)
            .frame(height: 46)
            .background(
                isHighlighted ? MegrumTheme.lavender : Color.white.opacity(0.88),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(isHighlighted ? MegrumTheme.lavender.opacity(0.35) : MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: isHighlighted ? MegrumTheme.lavender.opacity(0.20) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.36) {
            didTriggerLongPress = true
            longPressAction()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                didTriggerLongPress = false
            }
        }
        .accessibilityLabel(IndividualListingListPresentation.conditionStripTitle(index: index, totalCount: totalCount))
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        if isSelectionMode {
            return isMultiSelected ? "一括削除の選択中" : "未選択"
        }
        return isActive ? "選択中" : "\(totalCount)件中\(index + 1)件目"
    }

    private func performTap() {
        guard !didTriggerLongPress else {
            didTriggerLongPress = false
            return
        }
        action()
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
            Text("マイグッズとほしいものを選んで、ピンポイントの交換条件を作れます。")
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
