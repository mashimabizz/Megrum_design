import MegrumCore
import MegrumDesign
import SwiftUI

struct PaymentSettingsMethodsCard: View {
    var selectedMethods: [UserPaymentMethod]
    @Binding var otherNote: String
    var focusedField: FocusState<PaymentSettingsField?>.Binding
    var onToggleMethod: (UserPaymentMethod) -> Void

    var body: some View {
        VStack(spacing: 0) {
            PaymentSettingsMethodRow(
                method: .bankTransfer,
                description: "口座情報を登録して、必要な相手に表示します",
                isSelected: isSelected(.bankTransfer),
                action: { onToggleMethod(.bankTransfer) }
            )
            PaymentSettingsDivider()
            PaymentSettingsMethodRow(
                method: .paypay,
                description: "リンク登録なし。対応可否だけを表示します",
                isSelected: isSelected(.paypay),
                action: { onToggleMethod(.paypay) }
            )
            PaymentSettingsDivider()
            PaymentSettingsMethodRow(
                method: .cashExchange,
                description: "現地で差額を手渡しできます",
                isSelected: isSelected(.cashExchange),
                action: { onToggleMethod(.cashExchange) }
            )
            PaymentSettingsDivider()
            PaymentSettingsMethodRow(
                method: .other,
                description: "自由入力で支払い方法を補足できます",
                isSelected: isSelected(.other),
                action: { onToggleMethod(.other) }
            )
            if isSelected(.other) {
                PaymentSettingsDivider()
                PaymentSettingsOtherInlineField(
                    otherNote: $otherNote,
                    focusedField: focusedField
                )
            }
        }
        .paymentSettingsCardStyle()
    }

    private func isSelected(_ method: UserPaymentMethod) -> Bool {
        selectedMethods.contains(method)
    }
}

struct PaymentSettingsMethodRow: View {
    var method: UserPaymentMethod
    var description: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.72), lineWidth: 2.2)
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Circle()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 18, height: 18)
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(iconTint.opacity(0.13))
                    Image(systemName: iconName)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(iconTint)
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(description)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(method.displayName)、\(isSelected ? "選択中" : "未選択")")
    }

    private var iconName: String {
        switch method {
        case .bankTransfer:
            "building.columns"
        case .paypay:
            "p.square.fill"
        case .cashExchange:
            "banknote"
        case .other:
            "ellipsis.message"
        }
    }

    private var iconTint: Color {
        switch method {
        case .bankTransfer:
            MegrumTheme.sky
        case .paypay:
            MegrumTheme.conditionExact
        case .cashExchange:
            MegrumTheme.ok
        case .other:
            MegrumTheme.pink
        }
    }
}

struct PaymentSettingsOtherInlineField: View {
    @Binding var otherNote: String
    var focusedField: FocusState<PaymentSettingsField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("その他")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 88, alignment: .leading)

                TextField("8文字まで", text: $otherNote)
                    .focused(focusedField, equals: .otherNote)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                    }
            }

            HStack {
                Spacer()
                Text("\(otherNote.count)/\(PaymentSettingsDraft.otherNoteMaxLength)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
