import MegrumDesign
import SwiftUI

enum AuthVisualStyle {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.lavender, Color(red: 0.50, green: 0.40, blue: 0.86)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func authVisualBackground() -> some View {
        self
            .background(
                ZStack {
                    MegrumTheme.canvas
                    RadialGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(0.15),
                            .clear
                        ],
                        center: .top,
                        startRadius: 40,
                        endRadius: 430
                    )
                }
                .ignoresSafeArea()
            )
    }
}
