import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingHavesStep: View {
    enum Tab: String {
        case goods
        case cash
    }

    var inventory: [GoodsItem]
    var selectedIDs: Set<UUID>
    @Binding var selectedTab: Tab
    @Binding var cashAmount: Int
    var onToggle: (GoodsItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            IndividualListingStepTitle(step: .haves)

            IndividualListingEditorTabsLike(
                leftTitle: "譲る候補から選ぶ",
                rightTitle: "定価",
                isLeftSelected: selectedTab == .goods,
                onLeft: {
                    withAnimation(.smooth(duration: 0.2)) {
                        selectedTab = .goods
                    }
                },
                onRight: {
                    withAnimation(.smooth(duration: 0.2)) {
                        selectedTab = .cash
                    }
                }
            )

            if selectedTab == .goods {
                goodsSelection
            } else {
                cashSelection
            }
        }
    }

    private var goodsSelection: some View {
        VStack(alignment: .leading, spacing: 18) {
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

    private var cashSelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("定価で譲る")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            IndividualListingCashAmountCard(amount: $cashAmount)
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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(selected ? .white : MegrumTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
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

struct IndividualListingCashAmountCard: View {
    @Binding var amount: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("定価")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("購入時の税込価格")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer()

                amountField
            }
            .padding(.horizontal, 20)
            .frame(height: 92)
        }
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var amountField: some View {
        let field = TextField("1100", value: $amount, format: .number)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 22, weight: .regular, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 16)
            .frame(width: 136, height: 56)
            .background(.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.12), lineWidth: 1)
            }
            .overlay(alignment: .leading) {
                Text("¥")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.68))
                    .padding(.leading, 14)
            }

        #if os(iOS)
        field.keyboardType(.numberPad)
        #else
        field
        #endif
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
