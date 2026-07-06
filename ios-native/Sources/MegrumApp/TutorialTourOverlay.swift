import MegrumDesign
import SwiftUI

/// 初回ガイドツアーの最上位オーバーレイ。
/// dim＋スポットライト＋吹き出し（通常ステップ）と、中央カード（ウェルカム/完了）を出し分ける。
/// 画面のどこをタップしても次へ進む（スポットライト部分の実タップは要求しない）。
struct TutorialTourOverlay: View {
    let step: TutorialTourStep
    let anchorFrames: [TutorialAnchorID: CGRect]
    let containerSize: CGSize
    var onAdvance: () -> Void
    var onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var spotlightRect: CGRect? {
        step.spotlightAnchor.flatMap { anchorFrames[$0] }
    }

    var body: some View {
        ZStack {
            if step.isCardStep {
                TutorialCenterCard(
                    step: step,
                    showsSkip: step == .welcome,
                    onPrimary: onAdvance,
                    onSkip: onSkip
                )
            } else {
                // 対象アンカーがあるステップだけ dim＋切り抜き。
                // homeSections / meguri はサンプル/マップを見せたいので dim しない。
                if step.spotlightAnchor != nil {
                    TutorialSpotlightDim(rect: spotlightRect)
                }
                TutorialCalloutCard(
                    step: step,
                    targetRect: spotlightRect,
                    containerSize: containerSize,
                    onNext: onAdvance,
                    onSkip: onSkip
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            MegrumHaptics.buttonTap()
            onAdvance()
        }
        .ignoresSafeArea()
        .transition(.opacity)
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: step)
    }
}

/// dim＋対象を切り抜くスポットライト。切り抜きは destinationOut + compositingGroup。
private struct TutorialSpotlightDim: View {
    let rect: CGRect?

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.5))
            .overlay {
                if let rect {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .frame(width: rect.width + 16, height: rect.height + 16)
                        .position(x: rect.midX, y: rect.midY)
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
            .ignoresSafeArea()
    }
}

/// スポットライト対象の近くに置く吹き出しカード。矢印は使わず切り抜き自体が指示になる。
private struct TutorialCalloutCard: View {
    let step: TutorialTourStep
    let targetRect: CGRect?
    let containerSize: CGSize
    var onNext: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TutorialStepDots(currentIndex: step.rawValue)

            Text(step.calloutTitle)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(step.calloutBody)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button {
                    MegrumHaptics.performButtonTap(onSkip)
                } label: {
                    Text("スキップ")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    MegrumHaptics.performButtonTap(onNext)
                } label: {
                    Text("次へ")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 40)
                        .background(
                            LinearGradient(
                                colors: [MegrumTheme.sky, MegrumTheme.lavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: 300)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
        .position(calloutCenter)
    }

    private var calloutCenter: CGPoint {
        let approxHalfHeight: CGFloat = 96
        let margin: CGFloat = 22
        guard let targetRect else {
            return CGPoint(x: containerSize.width / 2, y: containerSize.height * 0.52)
        }
        let placeAbove = targetRect.midY > containerSize.height / 2
        let y = placeAbove
            ? targetRect.minY - margin - approxHalfHeight
            : targetRect.maxY + margin + approxHalfHeight
        let clampedY = min(max(y, 150), containerSize.height - 160)
        return CGPoint(x: containerSize.width / 2, y: clampedY)
    }
}

/// ウェルカム/完了の中央カード。
private struct TutorialCenterCard: View {
    let step: TutorialTourStep
    let showsSkip: Bool
    var onPrimary: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                TutorialStepDots(currentIndex: step.rawValue)

                Text(step.calloutTitle)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text(step.calloutBody)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    MegrumHaptics.performButtonTap(onPrimary)
                } label: {
                    Text("はじめる")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [MegrumTheme.sky, MegrumTheme.lavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)

                if showsSkip {
                    Button {
                        MegrumHaptics.performButtonTap(onSkip)
                    } label: {
                        Text("スキップ")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 26)
            .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
        }
    }
}

/// ツアー進捗を示すカプセルドット（AccountSetupWelcomeStep と同トーン）。
private struct TutorialStepDots: View {
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TutorialTourStep.allCases) { step in
                Capsule()
                    .fill(step.rawValue == currentIndex ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.22))
                    .frame(width: step.rawValue == currentIndex ? 20 : 6, height: 6)
            }
        }
        .animation(.snappy(duration: 0.22), value: currentIndex)
    }
}
