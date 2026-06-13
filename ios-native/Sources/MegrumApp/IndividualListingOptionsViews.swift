import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingOptionsStep: View {
    @Binding var optionKind: IndividualListingOptionKind
    var wishes: [WishItem]
    var selectedWishIDs: Set<UUID>
    @Binding var selectedWishLogic: ListingLogic
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    @Binding var selectedConditionGroupID: UUID?
    @Binding var selectedConditionGoodsTypeID: UUID?
    @Binding var cashAmount: Int
    @Binding var note: String
    var onToggleWish: (WishItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            IndividualListingStepTitle(step: .options)

            IndividualListingEditorTabs(selection: $optionKind)

            switch optionKind {
            case .wish:
                IndividualListingWishTab(
                    wishes: wishes,
                    selectedIDs: selectedWishIDs,
                    selectedLogic: $selectedWishLogic,
                    onToggle: onToggleWish
                )
            case .condition:
                IndividualListingConditionTab(
                    groups: groups,
                    goodsTypes: goodsTypes,
                    selectedGroupID: $selectedConditionGroupID,
                    selectedGoodsTypeID: $selectedConditionGoodsTypeID,
                    selectedLogic: $selectedWishLogic
                )
            case .cash:
                IndividualListingCashTab(
                    amount: $cashAmount,
                    note: $note
                )
            }
        }
    }
}

private struct IndividualListingEditorTabs: View {
    @Binding var selection: IndividualListingOptionKind

    var body: some View {
        HStack(spacing: 0) {
            ForEach(IndividualListingOptionKind.allCases) { kind in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        selection = kind
                    }
                } label: {
                    Text(kind.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(selection == kind ? .white : MegrumTheme.ink.opacity(0.78))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            if selection == kind {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(MegrumTheme.lavender)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct IndividualListingWishTab: View {
    var wishes: [WishItem]
    var selectedIDs: Set<UUID>
    @Binding var selectedLogic: ListingLogic
    var onToggle: (WishItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("受け取れる候補")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                Text("Wishを検索")
                Spacer()
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted.opacity(0.68))
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(MegrumTheme.ink.opacity(0.05), in: Capsule())

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(wishes) { item in
                    Button {
                        onToggle(item)
                    } label: {
                        ListingSelectableImageTile(
                            imageURL: item.imageURL,
                            title: item.title,
                            isSelected: selectedIDs.contains(item.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.title)を候補に選択")
                    .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
                }
            }

            IndividualListingLogicSelector(selection: $selectedLogic)
        }
    }
}

private struct IndividualListingConditionTab: View {
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    @Binding var selectedLogic: ListingLogic

    private var selectedGroup: OshiGroup? {
        groups.first { $0.id == selectedGroupID } ?? groups.first
    }

    private var selectedGoodsType: GoodsType? {
        goodsTypes.first { $0.id == selectedGoodsTypeID } ?? goodsTypes.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("画像なしで条件を作る")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(spacing: 0) {
                conditionMenuRow(
                    title: "グループ / 作品",
                    value: selectedGroup?.name ?? "未選択",
                    values: groups.map { ($0.id, $0.name) },
                    selection: $selectedGroupID
                )
                Divider()
                conditionFreeRow(title: "メンバー / キャラ", chips: ["指定なし", "他メンバーOK"])
                Divider()
                conditionMenuRow(
                    title: "グッズ種別",
                    value: selectedGoodsType?.name ?? "未選択",
                    values: goodsTypes.map { ($0.id, $0.name) },
                    selection: $selectedGoodsTypeID
                )
                Divider()
                conditionFreeRow(title: "シリーズ", chips: ["シリーズ不問も相談"])
                Divider()
                HStack {
                    Text("数量")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Text("1点")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                }
                .padding(.horizontal, 16)
                .frame(height: 58)
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
            }

            IndividualListingLogicSelector(selection: $selectedLogic)
        }
    }

    private func conditionMenuRow(
        title: String,
        value: String,
        values: [(UUID, String)],
        selection: Binding<UUID?>
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            Menu {
                ForEach(values, id: \.0) { id, title in
                    Button(title) {
                        selection.wrappedValue = id
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
            }
            .disabled(values.isEmpty)
        }
        .padding(.horizontal, 16)
        .frame(height: 62)
    }

    private func conditionFreeRow(title: String, chips: [String]) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 62)
    }
}

private struct IndividualListingCashTab: View {
    @Binding var amount: Int
    @Binding var note: String
    @State private var includesShipping = false
    @State private var allowsMarkup = false
    @State private var acceptsOutsideCondition = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("定価で受け付ける")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("定価")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text("購入時の税込価格")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer()
                    TextField("1100", value: $amount, format: .number)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 22, weight: .regular, design: .rounded))
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
                }
                .padding(.horizontal, 16)
                .frame(height: 92)

                Divider()
                cashToggleRow(title: "送料", subtitle: "発送が必要な時だけ使います", isOn: $includesShipping, labels: ["なし", "相手負担", "相談"])
                Divider()
                cashToggleRow(title: "受け渡し", subtitle: nil, isOn: .constant(true), labels: ["現地", "発送も相談"])
                Divider()
                Toggle(isOn: $allowsMarkup) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("上乗せ")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text("定価以上の打診は受け付けない")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }
                .tint(MegrumTheme.lavender)
                .padding(.horizontal, 16)
                .frame(height: 78)
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
            }

            Toggle(isOn: $acceptsOutsideCondition) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("条件外の打診も受け付ける")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("近い条件なら相手から相談できます")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            .tint(MegrumTheme.lavender)
            .padding(16)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("メモ（任意）")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                TextField("例：現地で手渡し希望", text: $note, axis: .vertical)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(3...5)
                    .padding(14)
                    .frame(minHeight: 96, alignment: .topLeading)
                    .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(MegrumTheme.ink.opacity(0.12), lineWidth: 1)
                    }
            }
        }
    }

    private func cashToggleRow(title: String, subtitle: String?, isOn: Binding<Bool>, labels: [String]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            Spacer()
            HStack(spacing: 0) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(label == labels.first ? .white : MegrumTheme.ink.opacity(0.72))
                        .frame(width: label.count >= 4 ? 92 : 70, height: 44)
                        .background {
                            if label == labels.first {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(MegrumTheme.lavender)
                            }
                        }
                }
            }
            .padding(3)
            .background(MegrumTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .padding(.horizontal, 16)
        .frame(height: 78)
    }
}
