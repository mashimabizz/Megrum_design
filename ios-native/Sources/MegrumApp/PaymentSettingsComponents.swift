import MegrumCore
import MegrumDesign
import SwiftUI
#if os(iOS)
import UIKit
#endif

enum PaymentSettingsField: Hashable {
    case otherNote
}

struct PaymentSettingsFormContent: View {
    var draft: PaymentSettingsDraft
    @Binding var otherNote: String
    var focusedField: FocusState<PaymentSettingsField?>.Binding
    var validationMessage: String?
    var appErrorMessage: String?
    var onToggleMethod: (UserPaymentMethod) -> Void
    var onAddAccount: () -> Void
    var onEditAccount: (BankReceivingAccount) -> Void
    var onDeleteAccount: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PaymentSettingsSectionTitle("対応できる方法")
            PaymentSettingsMethodsCard(
                selectedMethods: draft.methods,
                otherNote: $otherNote,
                focusedField: focusedField,
                onToggleMethod: onToggleMethod
            )

            if draft.requiresBankAccountDetails {
                VStack(alignment: .leading, spacing: 8) {
                    PaymentSettingsSectionTitle("銀行振込の受け取り口座")
                    Text("最大\(BankReceivingAccount.maxCount)件まで登録できます。銀行名は相手にも表示されます（支店・口座番号・名義はあなただけが確認できます）。")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 2)
                }
                PaymentSettingsBankAccountsCard(
                    accounts: draft.accounts,
                    canAddAccount: draft.canAddAccount,
                    onAdd: onAddAccount,
                    onEdit: onEditAccount,
                    onDelete: onDeleteAccount
                )
            }

            PaymentSettingsValidationErrorView(
                validationMessage: validationMessage,
                appErrorMessage: appErrorMessage
            )
        }
    }
}

struct PaymentSettingsSectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 2)
    }
}

struct PaymentSettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 52)
    }
}

struct PaymentSettingsValidationErrorView: View {
    var validationMessage: String?
    var appErrorMessage: String?

    var body: some View {
        if let message = validationMessage ?? appErrorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.conditionExact)
                .padding(.top, 4)
        }
    }
}

struct PaymentSettingsBottomBar: View {
    var isSaving: Bool
    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("キャンセル", action: onCancel)
                .buttonStyle(.megrumSecondary)
                .frame(maxWidth: 132)

            Button(action: onSave) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text("保存する")
                }
            }
            .buttonStyle(.megrumPrimary)
            .disabled(isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.white.opacity(0.96))
    }
}

struct PaymentSettingsTextFieldRow<Field: Hashable>: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboard: PaymentSettingsKeyboard = .default
    var focusedField: FocusState<Field?>.Binding
    var field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            TextField(placeholder, text: $text)
                .focused(focusedField, equals: field)
                #if os(iOS)
                .keyboardType(keyboard.uiKeyboardType)
                .textInputAutocapitalization(.never)
                #endif
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(MegrumTheme.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.vertical, 5)
    }
}

enum PaymentSettingsKeyboard {
    case `default`
    case numberPad

    #if os(iOS)
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default:
            .default
        case .numberPad:
            .numberPad
        }
    }
    #endif
}

extension View {
    func paymentSettingsCardStyle(strokeColor: Color = MegrumTheme.ink.opacity(0.08)) -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 0)
            .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.03), radius: 14, y: 7)
    }
}
