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

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, step == .welcome ? 0 : 10)

                content
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 112)
        }
        .scrollDisabled(step == .birthDate)
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
                    MegrumWordmark(width: 150)
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
        .background(MegrumTheme.canvas.opacity(0.96))
    }
}

struct AccountSetupListChoiceRow: View {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
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
