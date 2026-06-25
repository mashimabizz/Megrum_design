import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCreateTargetCard: View {
    var targetItem: GoodsItem
    var configuration: ProposalCreateConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("受け取る")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MegrumTheme.sky.opacity(0.24))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(targetItem.title)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(2)
                    Text(configuration.targetSubtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    if let targetSupplement = configuration.targetSupplement {
                        Text(targetSupplement)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.72), lineWidth: 1))
        }
    }
}

struct ProposalCreateSenderGoodsSection: View {
    var inventory: [GoodsItem]
    @Binding var selectedGoodsID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("私が出す")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if inventory.isEmpty {
                Text("マイグッズを登録すると選択できます")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(inventory) { item in
                            ProposalCreateGoodsChoice(
                                item: item,
                                selectedGoodsID: $selectedGoodsID
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct ProposalCreateGoodsChoice: View {
    var item: GoodsItem
    @Binding var selectedGoodsID: UUID?

    var body: some View {
        Button {
            selectedGoodsID = item.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.2))
                    .frame(width: 98, height: 116)
                    .overlay {
                        Image(systemName: selectedGoodsID == item.id ? "checkmark.circle.fill" : "photo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(selectedGoodsID == item.id ? MegrumTheme.lavender : .white)
                    }

                Text(item.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .frame(width: 98, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
