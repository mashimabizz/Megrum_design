import MegrumDesign
import SwiftUI

/// 初回ガイドツアーの最上位オーバーレイ（v3.1 章×ビート）。
/// - centerCard：全画面dim＋中央カード（ようこそ/完了）
/// - spotlight：dim＋対象切り抜き＋隣接吹き出し
/// - banner：dimなし・下部バナー（画面全体を見せる）
/// - tabBand：下部タブ帯だけ明るく残す（タブ移動の予告）
/// - demo：全画面デモステージ＋上部キャプション（指アイコン実演）
/// - meguriTapDemo：実マップ上で指が1km圏内をタップする実演＋下部バナー
/// 画面のどこをタップしても次へ。上部に全体プログレスバー、吹き出しに章内カウンタと「戻る」。
struct TutorialTourOverlay: View {
    let beat: TutorialBeat
    let overallProgress: Double
    let canRetreat: Bool
    let anchorFrames: [TutorialAnchorID: CGRect]
    let containerSize: CGSize
    var onAdvance: () -> Void
    var onRetreat: () -> Void
    var onEndTour: () -> Void
    /// meguriTapDemo：指がタップした瞬間に呼ばれる（実画面側で作成コールアウトを出す）。
    var onMeguriDemoTap: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var calloutSize: CGSize = CGSize(width: 300, height: 170)
    @StateObject private var meguriPointer = TutorialPointerChoreographer()
    @StateObject private var spotlightPointer = TutorialPointerChoreographer()
    /// 説明カードはユーザーが動かせる（FB⑩）。ビートが変わったらリセット。
    @State private var cardDragOffset: CGSize = .zero
    @State private var cardDragTranslation: CGSize = .zero

    private var spotlightRect: CGRect? {
        if case .spotlight(let anchor) = beat.presentation {
            return anchorFrames[anchor]
        }
        return nil
    }

    /// タブバー帯（下部）の近似矩形。タブアイテム個別の frame は取れないため幾何計算。
    private var tabBandRect: CGRect {
        let height: CGFloat = 96
        return CGRect(x: 8, y: containerSize.height - height - 6, width: containerSize.width - 16, height: height)
    }

    var body: some View {
        ZStack {
            content

            TutorialOverallProgressBar(progress: overallProgress)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 56)
                .position(x: containerSize.width / 2, y: 66)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            MegrumHaptics.buttonTap()
            onAdvance()
        }
        .transition(.opacity)
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: beat)
        .onChange(of: beat.id) { _, _ in
            cardDragOffset = .zero
            cardDragTranslation = .zero
        }
    }

    /// 説明カードのドラッグ移動（どの提示形式でも掴んで動かせる）。
    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                cardDragTranslation = value.translation
            }
            .onEnded { value in
                cardDragOffset = CGSize(
                    width: cardDragOffset.width + value.translation.width,
                    height: cardDragOffset.height + value.translation.height
                )
                cardDragTranslation = .zero
            }
    }

    private var currentCardOffset: CGSize {
        CGSize(
            width: cardDragOffset.width + cardDragTranslation.width,
            height: cardDragOffset.height + cardDragTranslation.height
        )
    }

    @ViewBuilder
    private var content: some View {
        switch beat.presentation {
        case .centerCard:
            TutorialCenterCard(
                beat: beat,
                onPrimary: onAdvance,
                onEndTour: onEndTour
            )

        case .spotlight:
            TutorialSpotlightDim(rect: clampedSpotlightRect)
            if let fraction = beat.pointerFraction {
                TutorialPointerLayer(choreo: spotlightPointer)
                    .task(id: beat.id) {
                        let target = CGPoint(
                            x: containerSize.width * fraction.x,
                            y: containerSize.height * fraction.y
                        )
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        spotlightPointer.appear(at: CGPoint(x: target.x + 60, y: target.y + 90))
                        await spotlightPointer.move(to: target, duration: 0.45)
                        await spotlightPointer.tap()
                    }
            }
            calloutCard
                .position(calloutCenter(around: clampedSpotlightRect))

        case .banner:
            bottomBanner

        case .tabBand:
            TutorialSpotlightDim(rect: tabBandRect, cornerRadius: 26)
            calloutCard
                .position(calloutCenter(around: tabBandRect))

        case .demo(let scene):
            TutorialDemoStageView(scene: scene, beatToken: beat.id)
                .allowsHitTesting(false)
            if demoCaptionPlacedAtBottom(for: scene) {
                bottomBanner
            } else {
                topCaption(topPadding: demoCaptionTopPadding(for: scene))
            }

        case .meguriTapDemo:
            TutorialPointerLayer(choreo: meguriPointer)
            bottomBanner
                .task(id: beat.id) {
                    await runMeguriTapChoreo()
                }
        }
    }

    // MARK: 吹き出し・キャプション

    private var calloutCard: some View {
        TutorialBeatCard(beat: beat, layoutWidth: 300, canRetreat: canRetreat, onAdvance: onAdvance, onRetreat: onRetreat, onEndTour: onEndTour)
            .background(TutorialCalloutSizeReader())
            .onPreferenceChange(TutorialCalloutSizePreferenceKey.self) { size in
                if size != .zero {
                    calloutSize = size
                }
            }
            .offset(currentCardOffset)
            .gesture(cardDragGesture)
    }

    private var bottomBanner: some View {
        VStack {
            Spacer()
            TutorialBeatCard(beat: beat, layoutWidth: nil, canRetreat: canRetreat, onAdvance: onAdvance, onRetreat: onRetreat, onEndTour: onEndTour)
                .padding(.horizontal, 20)
                .padding(.bottom, 108)
                .offset(currentCardOffset)
                .gesture(cardDragGesture)
        }
    }

    /// デモ用キャプション：コンパクト幅で右上寄せ（実画面のヘッダーを隠さない）。ドラッグで移動可。
    private func topCaption(topPadding: CGFloat = 116) -> some View {
        VStack {
            HStack {
                Spacer()
                TutorialBeatCard(beat: beat, layoutWidth: 316, canRetreat: canRetreat, onAdvance: onAdvance, onRetreat: onRetreat, onEndTour: onEndTour)
                    .padding(.trailing, 14)
            }
            .padding(.top, topPadding)
            Spacer()
        }
        .offset(currentCardOffset)
        .gesture(cardDragGesture)
    }

    // MARK: 配置計算

    private var clampedSpotlightRect: CGRect? {
        guard let rect = spotlightRect else { return nil }
        let visible = CGRect(origin: .zero, size: containerSize).insetBy(dx: 0, dy: 8)
        let clamped = rect.intersection(visible)
        guard !clamped.isNull, clamped.height > 24 else { return rect }
        return clamped
    }

    private func calloutCenter(around rect: CGRect?) -> CGPoint {
        let margin: CGFloat = 20
        let gap: CGFloat = 18
        guard let rect else {
            return CGPoint(x: containerSize.width / 2, y: containerSize.height * 0.5)
        }
        let spaceAbove = rect.minY
        let spaceBelow = containerSize.height - rect.maxY
        let placeAbove = spaceAbove >= spaceBelow
        let halfHeight = calloutSize.height / 2
        let y = placeAbove
            ? rect.minY - gap - halfHeight
            : rect.maxY + gap + halfHeight
        let clampedY = min(max(y, margin + halfHeight + 48), containerSize.height - margin - halfHeight)
        let halfWidth = calloutSize.width / 2
        let x = min(max(rect.midX, margin + halfWidth), containerSize.width - margin - halfWidth)
        return CGPoint(x: x, y: clampedY)
    }

    /// デモシーンの見せ場（サムネイル群・下部の設定ボタン等）を隠さない側にキャプションを置く。
    private func demoCaptionPlacedAtBottom(for scene: TutorialDemoScene) -> Bool {
        switch scene {
        case .goods(.openEditor), .goods(.pickOshi), .goods(.pickType),
             .goods(.pickPhotos), .goods(.bulkDetect), .goods(.manualCrop),
             .goods(.lensOpened), .goods(.lensCopy):
            return true
        case .goods:
            // 詳細ステップ（下部にメンバー/シリーズボタン）や完了一覧は上に置く。
            return false
        case .proposal(.preview), .proposal(.confirmTap), .proposal(.pickMore), .proposal(.pickFromWanted):
            // 下部CTA・下部候補・下段の希望レールが見せ場なので上に置く。
            return false
        case .proposal:
            return true
        case .listing, .trades:
            // エディタの下部バー／取引チャット入力欄が下にあるため上に置く。
            return false
        case .meguri:
            return true
        }
    }

    /// 上置きキャプションの基準位置（実画面のヘッダーを避ける）。
    private func demoCaptionTopPadding(for scene: TutorialDemoScene) -> CGFloat {
        switch scene {
        case .listing:
            return 214
        default:
            return 116
        }
    }

    // MARK: めぐりタップ実演

    private func runMeguriTapChoreo() async {
        let target = CGPoint(x: containerSize.width * 0.5, y: containerSize.height * 0.33)
        meguriPointer.appear(at: CGPoint(x: containerSize.width * 0.72, y: containerSize.height * 0.62))
        try? await Task.sleep(nanoseconds: 350_000_000)
        await meguriPointer.move(to: target, duration: 0.55)
        await meguriPointer.tap()
        onMeguriDemoTap()
    }
}

// MARK: - dim＋切り抜き

private struct TutorialSpotlightDim: View {
    let rect: CGRect?
    var cornerRadius: CGFloat? = nil

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.5))
            .overlay {
                if let rect {
                    RoundedRectangle(cornerRadius: cornerRadius ?? adaptiveRadius(for: rect), style: .continuous)
                        .frame(width: rect.width + 26, height: rect.height + 26)
                        .position(x: rect.midX, y: rect.midY)
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
    }

    private func adaptiveRadius(for rect: CGRect) -> CGFloat {
        min(44, (min(rect.width, rect.height) + 26) / 2)
    }
}

// MARK: - ビート共通カード（吹き出し／バナー／キャプション兼用）

private struct TutorialBeatCard: View {
    let beat: TutorialBeat
    /// nil なら横幅いっぱい（バナー/キャプション）。数値なら固定幅の吹き出し。
    let layoutWidth: CGFloat?
    let canRetreat: Bool
    var onAdvance: () -> Void
    var onRetreat: () -> Void
    var onEndTour: () -> Void

    private var chapterLabel: String {
        let progress = TutorialScript.chapterProgress(of: beat)
        return "\(beat.chapter.title) \(progress.index)/\(progress.count)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(beat.title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 8)
                Text(chapterLabel)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(MegrumTheme.lavender.opacity(0.14), in: Capsule(style: .continuous))
            }

            Text(beat.body)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(2.5)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Button {
                    MegrumHaptics.performButtonTap(onEndTour)
                } label: {
                    Text("終了")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .buttonStyle(.plain)

                if canRetreat {
                    Button {
                        MegrumHaptics.performButtonTap(onRetreat)
                    } label: {
                        Text("戻る")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    MegrumHaptics.performButtonTap(onAdvance)
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
        .frame(width: layoutWidth)
        .frame(maxWidth: layoutWidth == nil ? .infinity : nil)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
    }
}

// MARK: - ようこそ/完了の中央カード

private struct TutorialCenterCard: View {
    let beat: TutorialBeat
    var onPrimary: () -> Void
    var onEndTour: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)

            VStack(alignment: .leading, spacing: 16) {
                Text(beat.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text(beat.body)
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

                if beat.chapter == .welcome {
                    Text("画面のどこでもタップで進めます")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.85))
                        .frame(maxWidth: .infinity)

                    Button {
                        MegrumHaptics.performButtonTap(onEndTour)
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

// MARK: - 上部プログレスバー

private struct TutorialOverallProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.55))
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MegrumTheme.sky, MegrumTheme.lavender],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, proxy.size.width * progress))
            }
        }
        .frame(height: 5)
        .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
        .animation(.snappy(duration: 0.25), value: progress)
        .allowsHitTesting(false)
    }
}

// MARK: - 吹き出しサイズ計測

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
