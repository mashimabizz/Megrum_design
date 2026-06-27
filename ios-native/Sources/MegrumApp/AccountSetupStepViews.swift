import MegrumCore
import MegrumDesign
import SwiftUI

struct AccountSetupWelcomeStep: View {
    var body: some View {
        VStack(spacing: 26) {
            AccountSetupFeatureRow(
                systemImage: "arrow.left.arrow.right.circle",
                title: "グッズ交換",
                highlights: [
                    .init(text: "AIでグッズ登録"),
                    .init(text: "交換相手を自動で見つける"),
                    .init(text: "「探す」から「めぐりあう」へ", style: .accent)
                ]
            )

            Divider()
                .padding(.leading, 86)

            AccountSetupFeatureRow(
                systemImage: "heart.circle",
                title: "めぐり",
                highlights: [
                    .init(text: "近くの人とゆるくつながれる"),
                    .init(text: "気軽な交流から、深いつながりまで", style: .accent)
                ]
            )
        }
        .padding(.top, 22)
    }
}

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
            DatePicker(
                "生年月日",
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(12)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
            .onChange(of: birthDate) { _, _ in
                onClearError()
            }

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
            ForEach(UserGender.allCases) { option in
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

struct AccountSetupCompletionStep: View {
    var displayName: String
    var handle: String
    var prefecture: String
    var birthDate: Date
    var gender: UserGender?
    var selectedOshiDrafts: [OnboardingOshiDraft]
    var isSaving: Bool
    var errorMessage: String?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                AccountSetupSummaryRow(title: "推し", value: selectedOshiDrafts.map(\.displayName).joined(separator: "、"))
                Divider()
                AccountSetupSummaryRow(title: "活動エリア", value: prefecture)
                Divider()
                AccountSetupSummaryRow(title: "名前", value: displayName)
                Divider()
                AccountSetupSummaryRow(title: "ユーザーID", value: "@\(MegrumAppStateInputNormalizer.profileHandle(handle) ?? handle)")
                Divider()
                AccountSetupSummaryRow(title: "生年月日", value: ProfileBirthDateCodec.string(from: birthDate) ?? "")
                Divider()
                AccountSetupSummaryRow(title: "性別", value: gender?.displayName ?? "")
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }

            if isSaving {
                ProgressView("保存しています")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tint(MegrumTheme.lavender)
            }

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 22)
    }
}

private struct AccountSetupFeatureRow: View {
    var systemImage: String
    var title: String
    var highlights: [AccountSetupFeatureHighlight]

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 68, height: 68)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(highlights) { highlight in
                        AccountSetupFeatureHighlightLabel(highlight: highlight)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AccountSetupFeatureHighlight: Identifiable, Equatable {
    enum Style: Equatable {
        case primary
        case accent
    }

    let id = UUID()
    var text: String
    var style: Style = .primary
}

private struct AccountSetupFeatureHighlightLabel: View {
    var highlight: AccountSetupFeatureHighlight

    var body: some View {
        Text(highlight.text)
            .font(.system(size: highlight.style == .accent ? 15 : 14, weight: .black, design: .rounded))
            .foregroundStyle(highlight.style == .accent ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.86))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
    }

    private var backgroundColor: Color {
        switch highlight.style {
        case .primary:
            Color.white.opacity(0.78)
        case .accent:
            MegrumTheme.lavender.opacity(0.11)
        }
    }

    private var borderColor: Color {
        switch highlight.style {
        case .primary:
            Color.black.opacity(0.05)
        case .accent:
            MegrumTheme.lavender.opacity(0.22)
        }
    }
}

private struct AccountSetupSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 82, alignment: .leading)
            Text(value.isEmpty ? "未設定" : value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
