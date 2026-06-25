import MegrumDesign
import SwiftUI

struct AuthBrandLockup: View {
    var compact = false
    var showIconTile = false

    var body: some View {
        VStack(spacing: showIconTile ? 66 : 0) {
            if compact {
                HStack(spacing: 15) {
                    AuthRibbonMark()
                        .frame(width: 36, height: 34)
                    Text("Megrum")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            } else {
                Text("Megrum")
                    .font(.system(size: 45, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if showIconTile {
                ZStack {
                    AuthSparkleDecor()
                    Text("Mg")
                        .font(.system(size: 29, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(
                            LinearGradient(
                                colors: [
                                    MegrumTheme.lavender,
                                    MegrumTheme.sky.opacity(0.62),
                                    MegrumTheme.pink.opacity(0.74)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 21, style: .continuous)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            if !compact && !showIconTile {
                AuthRibbonMark()
                    .frame(width: 74, height: 70)
                    .offset(y: -70)
            }
        }
    }
}

private struct AuthRibbonMark: View {
    var body: some View {
        HStack(spacing: -6) {
            Capsule()
                .fill(AuthVisualStyle.primaryGradient)
                .rotationEffect(.degrees(27))
            Capsule()
                .fill(AuthVisualStyle.primaryGradient)
                .rotationEffect(.degrees(-27))
        }
    }
}

private struct AuthSparkleDecor: View {
    var body: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.38))
                .offset(x: -108, y: -7)
            Circle()
                .fill(MegrumTheme.pink.opacity(0.38))
                .frame(width: 8, height: 8)
                .offset(x: -48, y: 60)
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.34))
                .frame(width: 8, height: 8)
                .offset(x: 112, y: -51)
            Image(systemName: "sparkle")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.32))
                .offset(x: 122, y: 48)
        }
    }
}
