import MegrumCore
import MegrumDesign
import SwiftUI

enum AccountSetupFocusedField: Hashable {
    case groupSearch
    case areaSearch
    case displayName
    case handle
}

struct AccountSetupStepContainer<Content: View>: View {
    var step: AccountSetupStep
    var title: String
    var subtitle: String
    var showsBackButton: Bool
    var isPrimaryDisabled: Bool
    var primaryTitle: String
    var onBack: () -> Void
    var onPrimary: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                AccountSetupProgressHeader(
                    step: step,
                    showsBackButton: showsBackButton,
                    onBack: onBack
                )

                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, step == .welcome ? 0 : 10)

                content
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 112)
        }
        .safeAreaInset(edge: .bottom) {
            AccountSetupBottomActionBar(
                title: primaryTitle,
                isDisabled: isPrimaryDisabled,
                onPrimary: onPrimary
            )
        }
    }
}

private struct AccountSetupProgressHeader: View {
    var step: AccountSetupStep
    var showsBackButton: Bool
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if showsBackButton {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .frame(width: 48, height: 48)
                                .background(.white.opacity(0.84), in: Circle())
                                .overlay {
                                    Circle()
                                        .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                                }
                                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }

                if step == .welcome {
                    Text("Megrum")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            .frame(height: 50)

            AccountSetupProgressBars(step: step.progressIndex, total: AccountSetupStep.totalCount)

            Text("\(step.progressIndex)/\(AccountSetupStep.totalCount)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct AccountSetupProgressBars: View {
    var step: Int
    var total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...total, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? MegrumTheme.lavender : Color.black.opacity(0.08))
                    .frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(total)ステップ中\(step)ステップ目")
    }
}

private struct AccountSetupBottomActionBar: View {
    var title: String
    var isDisabled: Bool
    var onPrimary: () -> Void

    var body: some View {
        Button(action: onPrimary) {
            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender.opacity(isDisabled ? 0.45 : 0.94), MegrumTheme.lavender.opacity(isDisabled ? 0.36 : 0.76)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: MegrumTheme.lavender.opacity(isDisabled ? 0 : 0.24), radius: 14, x: 0, y: 9)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(MegrumTheme.canvas.opacity(0.96).ignoresSafeArea())
    }
}

struct AccountSetupWelcomeStep: View {
    var body: some View {
        VStack(spacing: 26) {
            AccountSetupFeatureRow(
                systemImage: "arrow.left.arrow.right.circle",
                title: "グッズ交換",
                message: "欲しいグッズを見つけて、安心して交換できます。"
            )

            Divider()
                .padding(.leading, 118)

            AccountSetupFeatureRow(
                systemImage: "heart.circle",
                title: "めぐり",
                message: "あなたのグッズが、誰かのもとへめぐります。"
            )
        }
        .padding(.top, 22)
    }
}

private struct AccountSetupFeatureRow: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 92, height: 92)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(message)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                    .autocorrectionDisabled()
                    #endif
                    .submitLabel(.next)
                    .onChange(of: text) { _, _ in
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

private struct AccountSetupListChoiceRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark" : "circle")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : Color.clear)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(isSelected ? MegrumTheme.lavender.opacity(0.10) : .clear)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct AccountSetupSearchField: View {
    var placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var focusCase: AccountSetupFocusedField

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            TextField(placeholder, text: $text)
                .focused($focusedField, equals: focusCase)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .autocorrectionDisabled()
                .submitLabel(.search)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.black.opacity(0.08), lineWidth: 1)
        }
    }
}

struct AccountSetupErrorText: View {
    var message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
    }
}
