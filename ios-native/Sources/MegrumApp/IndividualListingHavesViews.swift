import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingHavesStep: View {
    var inventory: [GoodsItem]
    var selectedIDs: Set<UUID>
    @Binding var haveLogic: ListingLogic
    var onCash: () -> Void
    var onToggle: (GoodsItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            IndividualListingStepTitle(step: .haves)

            IndividualListingEditorTabsLike(
                leftTitle: "譲る候補から選ぶ",
                rightTitle: "定価",
                isLeftSelected: true,
                onLeft: {},
                onRight: onCash
            )

            Text("譲る候補")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .medium))
                    Text("グッズを検索")
                    Spacer()
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted.opacity(0.72))
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(MegrumTheme.ink.opacity(0.045), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                Button {} label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 52, height: 52)
                        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                IndividualListingFilterChip(title: "すべて", isSelected: true, color: MegrumTheme.lavender)
                IndividualListingFilterChip(title: "TWICE", isSelected: false, color: MegrumTheme.sky)
                IndividualListingFilterChip(title: "トレカ", isSelected: false, color: MegrumTheme.lavender)
                IndividualListingFilterChip(title: "未設定あり", isSelected: false, color: MegrumTheme.muted)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(inventory) { item in
                    Button {
                        onToggle(item)
                    } label: {
                        ListingSquareSelectableImageTile(
                            imageURL: item.imageURL,
                            title: item.title,
                            isSelected: selectedIDs.contains(item.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.title)を譲るものに選択")
                    .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
                }
            }
        }
    }
}

private struct IndividualListingEditorTabsLike: View {
    var leftTitle: String
    var rightTitle: String
    var isLeftSelected: Bool
    var onLeft: () -> Void
    var onRight: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tab(title: leftTitle, selected: isLeftSelected, action: onLeft)
            tab(title: rightTitle, selected: !isLeftSelected, action: onRight)
        }
        .padding(4)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }

    private func tab(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(selected ? .white : MegrumTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 53)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct IndividualListingFilterChip: View {
    var title: String
    var isSelected: Bool
    var color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 17)
            .frame(height: 36)
            .background((isSelected ? color : color.opacity(0.14)), in: Capsule())
    }
}

private struct ListingSquareSelectableImageTile: View {
    var imageURL: URL?
    var title: String
    var isSelected: Bool

    var body: some View {
        ListingGoodsImage(url: imageURL, title: title, cornerRadius: 12)
            .aspectRatio(1, contentMode: .fit)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "checkmark")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(MegrumTheme.lavender, in: Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 2)
                    }
                    .opacity(isSelected ? 1 : 0)
                    .padding(7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            }
    }
}
