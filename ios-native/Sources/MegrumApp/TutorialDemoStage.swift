import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// デモビートの全画面ステージ。実UI部品をスクリプト状態で描画し、指アイコンの実演を重ねる。
/// 実データには一切書き込まない：分離した PreviewMegrumRepository ベースの AppState を使う。
struct TutorialDemoStageView: View {
    let scene: TutorialDemoScene
    /// ビートが切り替わった時にシーン側の演技をリスタートさせるためのトークン。
    let beatToken: String

    @StateObject private var demoAppState = MegrumAppState(repository: PreviewMegrumRepository())
    @State private var didLoad = false

    var body: some View {
        ZStack {
            MegrumTheme.canvas.ignoresSafeArea()

            switch scene {
            case .goods(let beat):
                TutorialGoodsDemoSceneView(beat: beat, demoAppState: demoAppState)
                    .id(beatToken)
            case .listing(let beat):
                TutorialListingDemoSceneView(beat: beat, demoAppState: demoAppState)
                    .id(beatToken)
            case .proposal(let beat):
                TutorialProposalDemoSceneView(beat: beat, demoAppState: demoAppState)
                    .id(beatToken)
            case .trades(let beat):
                TutorialTradesDemoSceneView(beat: beat, demoAppState: demoAppState)
                    .id(beatToken)
            }
        }
        .task {
            guard !didLoad else { return }
            didLoad = true
            await demoAppState.refresh()
        }
    }
}

/// デモ用のバンドル画像アセット。
enum TutorialDemoAssets {
    static func imageData(named name: String, fileExtension: String = "png") -> Data? {
        // SPMのリソース処理でサブディレクトリがフラット化される環境があるため、
        // NativePreviewData.testGoodsImageURL と同じくフォールバック付きで引く。
        let url = Bundle.module.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: "TestGoodsImages"
        ) ?? Bundle.module.url(forResource: name, withExtension: fileExtension)
        guard let url else { return nil }
        return try? Data(contentsOf: url)
    }

    /// SwiftUI Image として読み込む（macOSビルドでも通るようプラットフォーム分岐）。
    static func image(named name: String, fileExtension: String = "png") -> Image? {
        guard let data = imageData(named: name, fileExtension: fileExtension) else { return nil }
        #if canImport(UIKit)
        return UIImage(data: data).map { Image(uiImage: $0) }
        #elseif canImport(AppKit)
        return NSImage(data: data).map { Image(nsImage: $0) }
        #else
        return nil
        #endif
    }

    /// TWICE DIVE トレカ9枚（3×3グリッドの元写真から分割済み）。
    static var diveCardNames: [String] {
        (1...9).map { "twice_dive_card_\($0)" }
    }

    static var diveGridData: Data? {
        imageData(named: "twice_dive_grid", fileExtension: "jpg")
    }
}
