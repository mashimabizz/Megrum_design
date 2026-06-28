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
            Text("交換条件シリーズ")
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
