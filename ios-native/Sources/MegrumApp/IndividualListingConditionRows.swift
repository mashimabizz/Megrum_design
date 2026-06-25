import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingActionRow: View {
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                IndividualListingConditionRowTitle(title)
                Spacer()
                IndividualListingConditionRowValue(value: value, showsChevron: true)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }
}

struct IndividualListingGoodsTypeRow: View {
    let goodsTypes: [GoodsType]
    let selectedGoodsTypeName: String
    @Binding var selectedGoodsTypeID: UUID?

    var body: some View {
        HStack {
            IndividualListingConditionRowTitle("グッズ種別")
            Spacer()
            Menu {
                ForEach(goodsTypes) { type in
                    Button(type.name) {
                        selectedGoodsTypeID = type.id
                    }
                }
            } label: {
                IndividualListingConditionRowValue(value: selectedGoodsTypeName, showsChevron: true)
            }
            .disabled(goodsTypes.isEmpty)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }
}

struct IndividualListingTagRow: View {
    let tagSummary: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                IndividualListingConditionRowTitle("タグ")
                Spacer()
                IndividualListingConditionRowValue(value: tagSummary, showsChevron: true)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }
}

struct IndividualListingQuantityRow: View {
    @Binding var quantity: Int

    var body: some View {
        HStack {
            IndividualListingConditionRowTitle("数量")
            Spacer()
            HStack(spacing: 10) {
                IndividualListingQuantityButton(systemName: "minus") {
                    quantity = max(1, quantity - 1)
                }
                Text("\(quantity)点")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 52)
                IndividualListingQuantityButton(systemName: "plus") {
                    quantity = min(99, quantity + 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }
}

struct IndividualListingLogicHintRow: View {
    var body: some View {
        HStack {
            IndividualListingConditionRowTitle("希望の扱い")
            Spacer()
            Text("下の選択で指定")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }
}

private struct IndividualListingConditionRowTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
    }
}

private struct IndividualListingConditionRowValue: View {
    let value: String
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundStyle(MegrumTheme.lavender)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
    }
}

private struct IndividualListingQuantityButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.lavender.opacity(0.10), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
