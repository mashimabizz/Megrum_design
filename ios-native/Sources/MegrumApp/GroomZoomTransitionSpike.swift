import SwiftUI

/// iter1226.448：グルームを開くトランジションの「開き終わりのガクつき」を根本解決するための
/// 最小実機スパイク。ネットワーク・実データ・本番の提示配線を完全に排除し、
/// 「タイル → 全画面ストーリー」の遷移だけを、以下2方式でA/B比較できる。
///
/// - iOS 18 標準 zoom：`.matchedTransitionSource(id:in:)` + `.fullScreenCover` +
///   `.navigationTransition(.zoom(sourceID:in:))`。タイルの実矩形から全画面へ
///   連続変形し、枠と中身が常に一枚として動く（枠だけ先に開かない）。
/// - 手組み scaleEffect：現行方式の縮小再現（点アンカー + 固定 0.08 スケール、
///   黒背景は別レイヤーでスケールしない）。何が違うかを体感で確認するための対照群。
///
/// 起動：`MEGRUM_VISUAL_QA_INITIAL_SCREEN=groom-zoom-spike`
struct GroomZoomTransitionSpike: View {
    /// スパイク用のダミーグルーム（ローカル固定画像のみ・ネットワーク不使用）。
    struct SpikeGroom: Identifiable, Equatable {
        let id = UUID()
        let authorName: String
        let symbol: String
        let topColor: Color
        let bottomColor: Color
    }

    private static let sampleGrooms: [SpikeGroom] = [
        SpikeGroom(authorName: "はな", symbol: "sparkles", topColor: .pink, bottomColor: .purple),
        SpikeGroom(authorName: "みちりおん", symbol: "star.fill", topColor: .blue, bottomColor: .teal),
        SpikeGroom(authorName: "ゆい", symbol: "heart.fill", topColor: .orange, bottomColor: .red),
        SpikeGroom(authorName: "さくら", symbol: "moon.stars.fill", topColor: .indigo, bottomColor: .black),
        SpikeGroom(authorName: "れい", symbol: "flame.fill", topColor: .yellow, bottomColor: .orange),
    ]

    enum TransitionMode: String, CaseIterable, Identifiable {
        case standardZoom = "標準zoom (iOS18)"
        case handBuiltScale = "手組み scale (現行相当)"
        var id: String { rawValue }
    }

    @State private var mode: TransitionMode = .standardZoom
    @State private var selectedGroom: SpikeGroom?
    @State private var handBuiltGroom: SpikeGroom?
    @Namespace private var zoomNamespace

    /// 検証用：起動後に1枚目を自動で開く（computer-use無しでsim録画・計測するため）。
    /// `MEGRUM_VISUAL_QA_SPIKE_AUTO_OPEN=standard|hand`
    private var autoOpenMode: TransitionMode? {
        switch ProcessInfo.processInfo.environment["MEGRUM_VISUAL_QA_SPIKE_AUTO_OPEN"] {
        case "standard": return .standardZoom
        case "hand": return .handBuiltScale
        default: return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Groom Open トランジション A/B スパイク")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Picker("方式", selection: $mode) {
                ForEach(TransitionMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            rail

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(spikeBackground)
        .task {
            guard let autoOpenMode else { return }
            mode = autoOpenMode
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            openGroom(Self.sampleGrooms[0])
        }
        .modifier(SpikePresentation(
            selectedGroom: $selectedGroom,
            handBuiltGroom: $handBuiltGroom,
            namespace: zoomNamespace,
            viewer: spikeViewer
        ))
    }

    private var spikeBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color.white
        #endif
    }

    private var explanation: String {
        switch mode {
        case .standardZoom:
            return "タイルの実矩形から全画面へ連続変形。枠と中身が常に一枚で動く。iOS17では通常fullScreenCoverへフォールバック。"
        case .handBuiltScale:
            return "現行方式の縮小：点アンカー＋固定0.08スケール、黒背景は別レイヤー。枠が先に開いて中身が後から見える現象の再現。"
        }
    }

    private var rail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(Self.sampleGrooms) { groom in
                    tile(for: groom)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func tile(for groom: SpikeGroom) -> some View {
        let label = VStack(spacing: 6) {
            thumbnail(for: groom)
                .frame(width: 84, height: 84)
                .clipShape(Circle())
                .overlay {
                    Circle().strokeBorder(
                        LinearGradient(colors: [groom.topColor, groom.bottomColor], startPoint: .top, endPoint: .bottom),
                        lineWidth: 3
                    )
                }
            Text(groom.authorName)
                .font(.caption2)
                .lineLimit(1)
        }

        Button {
            openGroom(groom)
        } label: {
            applyMatchedSource(to: label, groom: groom)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func applyMatchedSource(to label: some View, groom: SpikeGroom) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *), mode == .standardZoom {
            label.matchedTransitionSource(id: groom.id, in: zoomNamespace)
        } else {
            label
        }
        #else
        label
        #endif
    }

    private func thumbnail(for groom: SpikeGroom) -> some View {
        ZStack {
            LinearGradient(colors: [groom.topColor, groom.bottomColor], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: groom.symbol)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func openGroom(_ groom: SpikeGroom) {
        switch mode {
        case .standardZoom:
            selectedGroom = groom
        case .handBuiltScale:
            handBuiltGroom = groom
        }
    }

    /// 全画面ストーリー相当のビューア（両方式で共通）。9:16画像を aspect-fit で中央に置く。
    private func spikeViewer(_ groom: SpikeGroom, onClose: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 本番の GroomStoryExportRenderer と同じ 9:16 合成キャンバス相当（ローカル生成）。
            GeometryReader { proxy in
                let targetAspect: CGFloat = 9.0 / 16.0
                let w = min(proxy.size.width, proxy.size.height * targetAspect)
                let h = w / targetAspect
                storyCanvas(for: groom)
                    .frame(width: w, height: h)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    Text(groom.authorName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.black.opacity(0.35)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
        }
    }

    private func storyCanvas(for groom: SpikeGroom) -> some View {
        ZStack {
            LinearGradient(colors: [groom.topColor, groom.bottomColor], startPoint: .top, endPoint: .bottom)
            Image(systemName: groom.symbol)
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
    }
}

/// スパイクの提示（fullScreenCover / overlay）は iOS 専用。macOS テストビルドでは素通し。
private struct SpikePresentation<Viewer: View>: ViewModifier {
    @Binding var selectedGroom: GroomZoomTransitionSpike.SpikeGroom?
    @Binding var handBuiltGroom: GroomZoomTransitionSpike.SpikeGroom?
    var namespace: Namespace.ID
    var viewer: (GroomZoomTransitionSpike.SpikeGroom, @escaping () -> Void) -> Viewer

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .fullScreenCover(item: $selectedGroom) { groom in
                viewer(groom) { selectedGroom = nil }
                    .modifier(StandardZoomDestination(groom: groom, namespace: namespace))
            }
            .overlay {
                if let handBuiltGroom {
                    HandBuiltScaleOverlay(groom: handBuiltGroom) {
                        self.handBuiltGroom = nil
                    } content: { g in
                        viewer(g) { self.handBuiltGroom = nil }
                    }
                    .transition(.identity)
                }
            }
        #else
        content
        #endif
    }
}

/// iOS 18+ でのみ zoom を付ける宛先モディファイア（iOS17は通常提示へフォールバック）。
private struct StandardZoomDestination: ViewModifier {
    var groom: GroomZoomTransitionSpike.SpikeGroom
    var namespace: Namespace.ID

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: groom.id, in: namespace))
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// 手組み scaleEffect による現行方式の縮小再現（対照群）。
/// 黒背景はスケールせず、ビューアだけが点アンカーで拡大する＝「枠と中身が別レイヤー」を再現。
private struct HandBuiltScaleOverlay<Content: View>: View {
    var groom: GroomZoomTransitionSpike.SpikeGroom
    var onDismiss: () -> Void
    @ViewBuilder var content: (GroomZoomTransitionSpike.SpikeGroom) -> Content

    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            // 黒背景はスケールしない（現行と同じ）。
            Color.black.opacity(progress).ignoresSafeArea()

            content(groom)
                .scaleEffect(0.08 + 0.92 * progress, anchor: UnitPoint(x: 0.18, y: 0.16))
                .opacity(progress)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                progress = 1
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                progress = 0
            } completion: {
                onDismiss()
            }
        }
    }
}
