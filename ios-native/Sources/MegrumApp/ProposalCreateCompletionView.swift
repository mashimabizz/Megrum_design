import MegrumDesign
import SwiftUI

struct ProposalCreateCompletionView: View {
    var summary: ProposalSubmittedSummary
    var onSearchMore: () -> Void
    var onOpenTrades: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            completionCard

            VStack(spacing: 10) {
                ForEach(ProposalCompletionButtonCopy.buttons) { button in
                    Button(action: { perform(button.action) }) {
                        Text(button.title)
                            .font(buttonFont(button.role))
                            .foregroundStyle(buttonForeground(button.role))
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight(button.role))
                            .background(
                                buttonBackgroundColor(button.role),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay {
                                if button.role == .secondary {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .padding(.bottom, 18)
    }

    private func perform(_ action: ProposalCompletionAction) {
        switch action {
        case .searchMore:
            onSearchMore()
        case .openTrades:
            onOpenTrades()
        }
    }

    private func buttonFont(_ role: ProposalCompletionButtonSpec.Role) -> Font {
        switch role {
        case .secondary:
            .system(size: 14, weight: .heavy, design: .rounded)
        case .primary:
            .system(size: 15, weight: .heavy, design: .rounded)
        }
    }

    private func buttonForeground(_ role: ProposalCompletionButtonSpec.Role) -> Color {
        switch role {
        case .secondary:
            MegrumTheme.lavender
        case .primary:
            .white
        }
    }

    private func buttonHeight(_ role: ProposalCompletionButtonSpec.Role) -> CGFloat {
        switch role {
        case .secondary:
            48
        case .primary:
            52
        }
    }

    private func buttonBackgroundColor(_ role: ProposalCompletionButtonSpec.Role) -> Color {
        switch role {
        case .secondary:
            .white
        case .primary:
            MegrumTheme.lavender
        }
    }

    private var completionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(color: MegrumTheme.lavender.opacity(0.08), radius: 14, y: 8)

            decorativeBackground

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(MegrumTheme.lavender.opacity(0.12))
                        .frame(width: 78, height: 78)

                    Circle()
                        .fill(MegrumTheme.lavender)
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: MegrumTheme.lavender.opacity(0.26), radius: 16, y: 8)
                }
                .frame(height: 82)

                VStack(spacing: 12) {
                    Text(summary.completionTitle)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .multilineTextAlignment(.center)

                    Text(summary.completionMessage)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 58)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 316)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var decorativeBackground: some View {
        ZStack {
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.14))
                .frame(width: 140, height: 140)
                .offset(x: -172, y: -150)
            Circle()
                .fill(MegrumTheme.pink.opacity(0.28))
                .frame(width: 78, height: 78)
                .offset(x: 112, y: -106)
            Circle()
                .fill(MegrumTheme.sky.opacity(0.28))
                .frame(width: 118, height: 118)
                .offset(x: 168, y: 150)
        }
    }
}
