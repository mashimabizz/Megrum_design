import MegrumCore
import MegrumDesign
import SwiftUI
#if os(iOS)
import UIKit
#endif

enum PaymentSettingsField: Hashable {
    case bankName
    case bankBranchName
    case bankAccountType
    case bankAccountNumber
    case bankAccountHolder
    case otherNote
}

struct PaymentSettingsFormContent: View {
    var draft: PaymentSettingsDraft
    @Binding var otherNote: String
    @Binding var bankName: String
    @Binding var bankBranchName: String
    @Binding var bankAccountType: String
    @Binding var bankAccountNumber: String
    @Binding var bankAccountHolder: String
    var focusedField: FocusState<PaymentSettingsField?>.Binding
    var validationMessage: String?
    var appErrorMessage: String?
    var onToggleMethod: (UserPaymentMethod) -> Void

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
                PaymentSettingsSectionTitle("銀行振込の受け取り口座")
                PaymentSettingsBankCard(
                    bankName: $bankName,
                    bankBranchName: $bankBranchName,
                    bankAccountType: $bankAccountType,
                    bankAccountNumber: $bankAccountNumber,
                    bankAccountHolder: $bankAccountHolder,
                    focusedField: focusedField
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
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 2)
    }
}

struct PaymentSettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 104)
    }
}

struct PaymentSettingsBankCard: View {
    @Binding var bankName: String
    @Binding var bankBranchName: String
    @Binding var bankAccountType: String
    @Binding var bankAccountNumber: String
    @Binding var bankAccountHolder: String
    var focusedField: FocusState<PaymentSettingsField?>.Binding

    var body: some View {
        VStack(spacing: 0) {
            PaymentSettingsTextFieldRow(
                title: "銀行名",
                placeholder: "みずほ銀行",
                text: $bankName,
                focusedField: focusedField,
                field: .bankName
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "支店名",
                placeholder: "渋谷支店",
                text: $bankBranchName,
                focusedField: focusedField,
                field: .bankBranchName
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "口座種別",
                placeholder: "普通",
                text: $bankAccountType,
                focusedField: focusedField,
                field: .bankAccountType
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "口座番号",
                placeholder: "1234567",
                text: $bankAccountNumber,
                keyboard: .numberPad,
                focusedField: focusedField,
                field: .bankAccountNumber
            )
            PaymentSettingsDivider()
            PaymentSettingsTextFieldRow(
                title: "口座名義",
                placeholder: "ヤマダ ハナコ",
                text: $bankAccountHolder,
                focusedField: focusedField,
                field: .bankAccountHolder
            )
        }
        .paymentSettingsCardStyle()
    }
}

struct PaymentSettingsValidationErrorView: View {
    var validationMessage: String?
    var appErrorMessage: String?

    var body: some View {
        if let message = validationMessage ?? appErrorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                .padding(.top, 4)
        }
    }
}

struct PaymentSettingsBottomBar: View {
    var isSaving: Bool
    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button("キャンセル", action: onCancel)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 52)

            Button(action: onSave) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text("保存する")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.sky],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.white.opacity(0.96))
    }
}

struct PaymentSettingsTextFieldRow: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboard: PaymentSettingsKeyboard = .default
    var focusedField: FocusState<PaymentSettingsField?>.Binding
    var field: PaymentSettingsField

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 88, alignment: .leading)

            TextField(placeholder, text: $text)
                .focused(focusedField, equals: field)
                #if os(iOS)
                .keyboardType(keyboard.uiKeyboardType)
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
        padding(.horizontal, 20)
            .padding(.vertical, 0)
            .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 18, y: 10)
    }
}
