import MegrumCore
import MegrumDesign
import SwiftUI

struct AccountSetupAreaStep: View {
    @Binding var selectedPrefecture: String
    @Binding var searchText: String
    var errorMessage: String?
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var onClearError: () -> Void

    private var filteredPrefectures: [String] {
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return JapanesePrefectureCatalog.all
        }
        return JapanesePrefectureCatalog.all.filter { $0.localizedCaseInsensitiveContains(normalized) }
    }

    var body: some View {
        VStack(spacing: 18) {
            AccountSetupSearchField(
                placeholder: "都道府県を検索",
                text: $searchText,
                focusedField: $focusedField,
                focusCase: .areaSearch
            )

            VStack(spacing: 0) {
                ForEach(filteredPrefectures, id: \.self) { prefecture in
                    AccountSetupListChoiceRow(
                        title: prefecture,
                        isSelected: selectedPrefecture == prefecture
                    ) {
                        selectedPrefecture = prefecture
                        onClearError()
                    }

                    if prefecture != filteredPrefectures.last {
                        Divider()
                    }
                }
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }

            AccountSetupErrorText(message: errorMessage)
        }
    }
}

struct AccountSetupTextInputStep: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var focusCase: AccountSetupFocusedField
    var leadingText: String?
    var isHandleField = false
    var footnote: String
    var errorMessage: String?
    var onClearError: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 6) {
                if let leadingText {
                    Text(leadingText)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                TextField(placeholder, text: $text)
                    .focused($focusedField, equals: focusCase)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .textContentType(isHandleField ? .username : .name)
                    .keyboardType(isHandleField ? .asciiCapable : .default)
                    .textInputAutocapitalization(isHandleField ? .never : .words)
                    .autocorrectionDisabled()
                    #endif
                    .submitLabel(.next)
                    .onChange(of: text) { _, newValue in
                        if isHandleField {
                            let lowercased = newValue.lowercased()
                            if lowercased != newValue {
                                text = lowercased
                            }
                        }
                        onClearError()
                    }

                if !text.isEmpty {
                    Button {
                        text = ""
                        onClearError()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.36))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 64)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.55), lineWidth: 1.2)
            }

            Text(footnote)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(4)

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 28)
    }
}

struct AccountSetupBirthDateStep: View {
    @Binding var birthDate: Date
    var errorMessage: String?
    var onClearError: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            AccountSetupBirthDateCalendar(
                selection: $birthDate,
                onSelectionChange: onClearError
            )

            Text("生年月日は相手にそのまま公開されません。プロフィールでは年齢表示に使います。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(4)

            AccountSetupErrorText(message: errorMessage)
        }
    }
}

struct AccountSetupGenderStep: View {
    @Binding var gender: UserGender?
    var errorMessage: String?
    var onClearError: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(AccountSetupGenderOptions.all) { option in
                AccountSetupListChoiceRow(
                    title: option.displayName,
                    isSelected: gender == option
                ) {
                    gender = option
                    onClearError()
                }
            }

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 22)
    }
}
