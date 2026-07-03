import MegrumDesign
import SwiftUI

struct ProposalCompletionCard: View {
    var summary: ProposalSubmittedSummary

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(color: MegrumTheme.lavender.opacity(0.08), radius: 14, y: 8)

            ProposalCompletionDecorativeBackground()
            ProposalCompletionCelebrationView()

            VStack(spacing: 20) {
                ProposalCompletionCheckmarkBadge()

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
}

private struct ProposalCompletionCheckmarkBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presentationState = ProposalCompletionAnimationPresentationState()

    var body: some View {
        ZStack {
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.12))
                .frame(width: 78, height: 78)
                .scaleEffect(presentationState.haloScale(reduceMotion: reduceMotion))
                .opacity(presentationState.haloOpacity)

            Circle()
                .fill(MegrumTheme.lavender)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)
                }
                .shadow(color: MegrumTheme.lavender.opacity(0.26), radius: 16, y: 8)
                .scaleEffect(presentationState.badgeScale(reduceMotion: reduceMotion))
        }
        .frame(height: 82)
        .onAppear {
            guard !presentationState.isShown else {
                return
            }
            if reduceMotion {
                presentationState.show()
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.64)) {
                    presentationState.show()
                }
            }
        }
    }
}

private struct ProposalCompletionCelebrationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presentationState = ProposalCompletionAnimationPresentationState()

    private let sparkles: [ProposalCompletionSparkle] = [
        ProposalCompletionSparkle(id: 0, x: -104, y: -68, size: 13, color: MegrumTheme.pink, symbolName: "sparkle"),
        ProposalCompletionSparkle(id: 1, x: 94, y: -56, size: 15, color: MegrumTheme.sky, symbolName: "sparkles"),
        ProposalCompletionSparkle(id: 2, x: -126, y: 54, size: 9, color: MegrumTheme.lavender, symbolName: "circle.fill"),
        ProposalCompletionSparkle(id: 3, x: 122, y: 58, size: 10, color: MegrumTheme.pink, symbolName: "circle.fill"),
        ProposalCompletionSparkle(id: 4, x: 0, y: -104, size: 8, color: MegrumTheme.sky, symbolName: "circle.fill")
    ]

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: sparkle.symbolName)
                    .font(.system(size: sparkle.size, weight: .black))
                    .foregroundStyle(sparkle.color.opacity(0.82))
                    .offset(
                        x: presentationState.sparkleOffsetValue(sparkle.x, reduceMotion: reduceMotion),
                        y: presentationState.sparkleOffsetValue(sparkle.y, reduceMotion: reduceMotion)
                    )
                    .scaleEffect(presentationState.sparkleScale(reduceMotion: reduceMotion))
                    .opacity(presentationState.sparkleOpacity)
            }
        }
        .onAppear {
            guard !presentationState.isShown else {
                return
            }
            if reduceMotion {
                presentationState.show()
            } else {
                withAnimation(.spring(response: 0.54, dampingFraction: 0.72).delay(0.08)) {
                    presentationState.show()
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ProposalCompletionSparkle: Identifiable {
    var id: Int
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var symbolName: String
}

private struct ProposalCompletionDecorativeBackground: View {
    var body: some View {
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
