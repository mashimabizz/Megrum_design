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
        padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 18, y: 10)
    }
}
