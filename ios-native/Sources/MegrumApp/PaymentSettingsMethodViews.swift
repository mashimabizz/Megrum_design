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

    // iter1226.416 刷新：左の大型ラジオを廃止し、右端のチェックマーク円へ。
    // アイコンは68pt→40ptに縮小し、タイポも15.5/12.5pt semibold 基調に。
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconTint.opacity(0.13))
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconTint)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(description)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(MegrumTheme.lavender)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .strokeBorder(MegrumTheme.ink.opacity(0.16), lineWidth: 1.5)
                    }
                }
                .frame(width: 24, height: 24)
            }
            .padding(.vertical, 13)
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

    // iter1226.416 刷新：住所/認証と同じ「上ラベル＋淡い塗り」フィールドへ。
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("その他の方法（自由入力）")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Spacer()
                Text("\(otherNote.count)/\(PaymentSettingsDraft.otherNoteMaxLength)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            TextField("例：メルペイ", text: $otherNote)
                .focused(focusedField, equals: .otherNote)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(MegrumTheme.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.top, 12)
        .padding(.bottom, 14)
    }
}
