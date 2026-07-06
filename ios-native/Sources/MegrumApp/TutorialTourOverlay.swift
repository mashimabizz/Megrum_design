import MegrumDesign
import SwiftUI

/// 初回ガイドツアーの最上位オーバーレイ。
/// - centerCard（ようこそ/完了）：全画面dim＋中央カード
/// - spotlight：dim＋対象の切り抜き＋対象に隣接する矢印付き吹き出し（対象を隠さない）
/// - banner（めぐり）：dimなし・下部バナー（画面全体を見せる）
/// 画面のどこをタップしても次へ進む。座標系は呼び出し側の full-screen GeometryReader に統一する。
struct TutorialTourOverlay: View {
    let step: TutorialTourStep
    let anchorFrames: [TutorialAnchorID: CGRect]
    let containerSize: CGSize
    var onAdvance: () -> Void
    var onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var calloutSize: CGSize = CGSize(width: 290, height: 150)

    private var spotlightRect: CGRect? {
        step.spotlightAnchor.flatMap { anchorFrames[$0] }
    }

    var body: some View {
        ZStack {
            switch step.presentation {
            case .centerCard:
                TutorialCenterCard(
                    step: step,
                    showsSkip: step == .welcome,
                    onPrimary: onAdvance,
                    onSkip: onSkip
                )
            case .banner:
                TutorialBottomBanner(
                    step: step,
                    containerSize: containerSize,
                    onNext: onAdvance,
                    onSkip: onSkip
                )
            case .spotlight:
                TutorialSpotlightDim(rect: clampedSpotlightRect)
                TutorialCalloutCard(
                    step: step,
                    onNext: onAdvance,
                    onSkip: onSkip
                )
                .background(TutorialCalloutSizeReader())
                .onPreferenceChange(TutorialCalloutSizePreferenceKey.self) { size in
                    if size != .zero {
                        calloutSize = size
                    }
                }
                .position(calloutCenter)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            MegrumHaptics.buttonTap()
            onAdvance()
        }
        .transition(.opacity)
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: step)
    }

    /// 対象が画面外へはみ出す場合（スクロール途中など）は表示領域内へクランプする。
    private var clampedSpotlightRect: CGRect? {
        guard let rect = spotlightRect else { return nil }
        let visible = CGRect(origin: .zero, size: containerSize).insetBy(dx: 0, dy: 8)
        let clamped = rect.intersection(visible)
        guard !clamped.isNull, clamped.height > 24 else { return rect }
        return clamped
    }

    /// 吹き出しは対象を隠さない側（上下の広い方）に、対象の中心寄りへ配置する。
    private var calloutCenter: CGPoint {
        let margin: CGFloat = 20
        let gap: CGFloat = 18
        guard let rect = clampedSpotlightRect else {
            return CGPoint(x: containerSize.width / 2, y: containerSize.height * 0.5)
        }
        let spaceAbove = rect.minY
        let spaceBelow = containerSize.height - rect.maxY
        let placeAbove = spaceAbove >= spaceBelow
        let halfHeight = calloutSize.height / 2
        let y = placeAbove
            ? rect.minY - gap - halfHeight
            : rect.maxY + gap + halfHeight
        let clampedY = min(max(y, margin + halfHeight + 40), containerSize.height - margin - halfHeight)
        let halfWidth = calloutSize.width / 2
        let x = min(max(rect.midX, margin + halfWidth), containerSize.width - margin - halfWidth)
        return CGPoint(x: x, y: clampedY)
    }
}

// MARK: - スポットライト（dim＋切り抜き）

private struct TutorialSpotlightDim: View {
    let rect: CGRect?

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.5))
            .overlay {
                if let rect {
                    RoundedRectangle(cornerRadius: cutoutCornerRadius(for: rect), style: .continuous)
                        .frame(width: rect.width + 14, height: rect.height + 14)
                        .position(x: rect.midX, y: rect.midY)
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
    }

    /// ＋ボタンのような正円に近い対象は丸く、セクションのような大きい対象は角丸で切り抜く。
    private func cutoutCornerRadius(for rect: CGRect) -> CGFloat {
        min(40, (min(rect.width, rect.height) + 14) / 2)
    }
}

// MARK: - 吹き出し（対象に隣接・矢印なしのコンパクトカード）

private struct TutorialCalloutCard: View {
    let step: TutorialTourStep
    var onNext: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(step.calloutTitle)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 8)
                TutorialStepCounter(step: step)
            }

            Text(step.calloutBody)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(2.5)
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

                TutorialNextButton(onNext: onNext)
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
    }
}

// MARK: - 下部バナー（めぐり：画面全体を見せる）

private struct TutorialBottomBanner: View {
    let step: TutorialTourStep
    let containerSize: CGSize
    var onNext: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(step.calloutTitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer(minLength: 8)
                    TutorialStepCounter(step: step)
                }

                Text(step.calloutBody)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineSpacing(2.5)
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

                    TutorialNextButton(onNext: onNext)
                }
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            // タブバー＋ホームインジケータの上に載せる。
            .padding(.bottom, 108)
        }
    }
}

// MARK: - ウェルカム/完了の中央カード

private struct TutorialCenterCard: View {
    let step: TutorialTourStep
    let showsSkip: Bool
    var onPrimary: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(step.calloutTitle)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer(minLength: 8)
                    TutorialStepCounter(step: step)
                }

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
                    Text("画面のどこでもタップで進めます")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.85))
                        .frame(maxWidth: .infinity)

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

// MARK: - 共通部品

/// 「3/10」形式のステップカウンタ。ドット列よりも現在地が明確（iter1226.337 オーナーFB反映）。
private struct TutorialStepCounter: View {
    let step: TutorialTourStep

    var body: some View {
        Text("\(step.rawValue + 1)/\(TutorialTourStep.allCases.count)")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(MegrumTheme.lavender.opacity(0.14), in: Capsule(style: .continuous))
    }
}

private struct TutorialNextButton: View {
    var onNext: () -> Void

    var body: some View {
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

// MARK: - 吹き出しサイズ計測（隣接配置の重なり防止に実寸を使う）

private struct TutorialCalloutSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private struct TutorialCalloutSizeReader: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: TutorialCalloutSizePreferenceKey.self, value: proxy.size)
        }
    }
}
