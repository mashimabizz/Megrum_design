import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCreateSheetHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PROPOSAL")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text("打診を作成")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
    }
}

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

struct ProposalCreateExchangeMethodSection: View {
    @Binding var exchangeMethod: ExchangeMethod
    var configuration: ProposalCreateConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("交換手段")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Picker("交換手段", selection: $exchangeMethod) {
                ForEach(ExchangeMethod.allCases) { method in
                    Text(method.displayName).tag(method)
                }
            }
            .pickerStyle(.segmented)

            if let methodNotice = configuration.methodNotice {
                Text(methodNotice)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ProposalCreateConditionTagsSection: View {
    var tags: [String]
    var selectedTags: Set<String>
    var onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("交換条件タグ")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        onToggle(tag)
                    } label: {
                        Text(tag)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(selectedTags.contains(tag) ? .white : MegrumTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                selectedTags.contains(tag)
                                    ? AnyShapeStyle(MegrumTheme.lavender)
                                    : AnyShapeStyle(.regularMaterial),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ProposalCreateMessageSection: View {
    @Binding var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("メッセージ")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            TextField("よろしくお願いします", text: $message, axis: .vertical)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(3...6)
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

struct ProposalCreateSubmitButton: View {
    var title: String
    var isCreating: Bool
    var canSubmit: Bool
    var onSubmit: () -> Void

    var body: some View {
        Button(action: onSubmit) {
            HStack {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
            }
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.48)
    }
}
