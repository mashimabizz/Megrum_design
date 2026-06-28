import MegrumDesign
import SwiftUI

struct AccountDeletionStepHeader: View {
    var step: AccountDeletionStep

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(step.stepText)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(step.title)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text(step.subtitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(3)
        }
    }
}

struct AccountDeletionBottomBar: View {
    var step: AccountDeletionStep
    var isRequesting: Bool
    var ongoingTradeCount: Int
    var onBack: () -> Void
    var onPrimaryAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if step == .reasons {
                Button("戻る", action: onBack)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }

            Button(action: onPrimaryAction) {
                HStack(spacing: 10) {
                    if isRequesting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(step.primaryButtonTitle)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(primaryButtonBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isPrimaryButtonDisabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.white.opacity(0.96))
    }

    private var primaryButtonBackground: Color {
        if isPrimaryButtonDisabled {
            return MegrumTheme.muted.opacity(0.34)
        }
        return step == .warning ? MegrumTheme.lavender : Color(red: 0.86, green: 0.29, blue: 0.38)
    }

    private var isPrimaryButtonDisabled: Bool {
        if isRequesting {
            return true
        }
        return step == .warning && ongoingTradeCount > 0
    }
}

enum AccountDeletionStep: Equatable {
    case warning
    case reasons

    var stepText: String {
        switch self {
        case .warning:
            "1/2"
        case .reasons:
            "2/2"
        }
    }

    var title: String {
        switch self {
        case .warning:
            "退会前に確認してください"
        case .reasons:
            "退会理由を教えてください"
        }
    }

    var subtitle: String {
        switch self {
        case .warning:
            "退会するとMegrumの通常利用ができなくなります。大事な取引が残っていないか確認してください。"
        case .reasons:
            "今後の改善のため、当てはまる理由を選んでください。メモは任意です。"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .warning:
            "理由入力へ進む"
        case .reasons:
            "退会する"
        }
    }
}
