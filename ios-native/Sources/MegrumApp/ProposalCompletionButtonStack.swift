import MegrumDesign
import SwiftUI

struct ProposalCompletionButtonStack: View {
    var onAction: (ProposalCompletionAction) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(ProposalCompletionButtonCopy.buttons) { button in
                Button(action: { onAction(button.action) }) {
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
}
