import MegrumDesign
import SwiftUI

struct AuthVisualFeedbackRow: View {
    var feedback: AuthVisualFeedback

    var body: some View {
        Text(feedback.message)
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(foreground.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var foreground: Color {
        switch feedback.style {
        case .error:
            Color(red: 0.851, green: 0.35, blue: 0.42)
        case .success:
            MegrumTheme.ok
        case .info:
            MegrumTheme.muted
        }
    }
}
