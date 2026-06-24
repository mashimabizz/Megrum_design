import MegrumDesign
import SwiftUI

enum AccountSetupFocusedField: Hashable {
    case displayName
    case prefecture
    case groupSearch
}

struct AccountSetupHeader: View {
    var mode: AccountSetupMode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mode.headerTitle)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(mode.headerSubtitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AccountSetupProfileForm: View {
    @Binding var displayName: String
    @Binding var prefecture: String
    @Binding var setupInputErrorMessage: String?
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var appErrorMessage: String?
    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            TextField("表示名", text: $displayName)
                .focused($focusedField, equals: .displayName)
                .textContentType(.name)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .prefecture
                }
                .megrumTextFieldStyle()
                .accessibilityLabel("表示名")
                .accessibilityHint("アプリ内で相手に表示する名前を入力します")
                .onChange(of: displayName) { _, _ in
                    setupInputErrorMessage = nil
                }

            TextField("都道府県", text: $prefecture)
                .focused($focusedField, equals: .prefecture)
                .textContentType(.addressState)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                .megrumTextFieldStyle()
                .accessibilityLabel("活動エリア")
                .accessibilityHint("主に交換する都道府県を入力します")
                .onChange(of: prefecture) { _, _ in
                    setupInputErrorMessage = nil
                }

            if let message = setupInputErrorMessage ?? appErrorMessage {
                AccountSetupErrorBanner(message: message)
            }
        }
    }
}

struct AccountSetupSaveSection: View {
    var mode: AccountSetupMode
    var isSaving: Bool
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onSave) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(mode.saveTitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .tint(MegrumTheme.lavender)
            .disabled(isSaving)
            .accessibilityHint(mode.completionFootnote)

            Text(mode.completionFootnote)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
        }
    }
}

private struct AccountSetupErrorBanner: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .accessibilityLabel(message)
    }
}
