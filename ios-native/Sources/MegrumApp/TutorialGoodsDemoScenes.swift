import MegrumCore
import MegrumDesign
import SwiftUI

/// 第4章 マイグッズ登録デモ。実物の作成ウィザード（GoodsInventoryCreateFlowView）を
/// ビートごとのスクリプト状態で描画し、指アイコンの実演を重ねる。
struct TutorialGoodsDemoSceneView: View {
    let beat: TutorialGoodsDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    @StateObject private var pointer = TutorialPointerChoreographer()
    @State private var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
    @State private var createMetas: [GoodsCreateMetaDraft] = []
    @State private var cropProgress: CGFloat = 0

    private var twiceGroup: OshiGroup? {
        demoAppState.oshiGroups.first { $0.name.localizedCaseInsensitiveContains("TWICE") }
    }

    private var tradingCardType: GoodsType? {
        demoAppState.goodsTypes.first { $0.name.contains("トレカ") }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                stageContent(size: proxy.size)
                TutorialPointerLayer(choreo: pointer)
            }
            .task(id: beat) {
                configureDraft()
                await runChoreo(size: proxy.size)
            }
        }
    }

    // MARK: シーン本体

    @ViewBuilder
    private func stageContent(size: CGSize) -> some View {
        switch beat {
        case .openEditor, .pickOshi, .pickType:
            wizard(step: .common, photos: [], statusMessage: nil)
        case .pickPhotos:
            wizard(step: .shoot, photos: gridPhotoDrafts, statusMessage: nil)
        case .bulkDetect:
            wizard(
                step: .shoot,
                photos: cardPhotoDrafts(count: 7),
                statusMessage: "7枚を切り抜きました（右下の2枚は読み取れませんでした）"
            )
        case .manualCrop:
            manualCropStage(size: size)
        case .assignMembers, .assignSeries:
            wizard(step: .meta, photos: cardPhotoDrafts(count: 9), statusMessage: nil)
                .overlay(alignment: .bottomTrailing) {
                    if beat == .assignSeries {
                        lensResultCard
                            .padding(.trailing, 20)
                            .padding(.bottom, 140)
                    }
                }
        case .saved:
            savedStage
        }
    }

    /// 実物のウィザードをスクリプト状態で描画する（シート風の白背景＋タイトル付き）。
    private func wizard(step: GoodsCreateStep, photos: [GoodsCreatePhotoDraft], statusMessage: String?) -> some View {
        VStack(spacing: 0) {
            demoSheetHeader(title: "マイグッズに追加")
            ScrollView {
                GoodsInventoryCreateFlowView(
                    draft: $draft,
                    createMetas: $createMetas,
                    createStep: step,
                    createPhotos: photos,
                    selectedCreateMetaIDs: selectedMetaIDs,
                    groups: demoAppState.oshiGroups,
                    isLoadingOshiGroups: false,
                    goodsTypes: demoAppState.goodsTypes,
                    isLoadingGoodsTypes: false,
                    oshiCharacters: demoAppState.oshiCharacters,
                    allowsMemberSelection: true,
                    selectedGroupName: draft.groupID == nil ? nil : twiceGroup?.name,
                    createError: nil,
                    canAdvanceFromCommon: draft.groupID != nil && draft.goodsTypeID != nil,
                    isTradingCardType: draft.goodsTypeID != nil,
                    isProcessingTradingCardBulk: false,
                    tradingCardBulkStatusMessage: statusMessage,
                    isItemReadOnly: false,
                    isCreatingGoodsEntry: false,
                    onShowOshiPicker: {},
                    onCommonNext: {},
                    onPickCamera: {},
                    onPickPhotos: {},
                    onStartTradingCardBulk: {},
                    onRemovePhoto: { _ in },
                    onCropPhoto: { _ in },
                    onShootBack: {},
                    onShootNext: {},
                    onMetaBack: {},
                    onToggleMetaSelection: { _ in },
                    onSelectAllMetas: {},
                    onClearMetaSelection: {},
                    onRemoveMetaTag: { _, _ in }
                )
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .allowsHitTesting(false)
    }

    /// 手動切り抜きビート：元写真の上で切り抜き枠が右下のカードへ動く実演。
    private func manualCropStage(size: CGSize) -> some View {
        VStack(spacing: 0) {
            demoSheetHeader(title: "手動で切り抜き")
            Spacer(minLength: 0)
            if let image = TutorialDemoAssets.image(named: "twice_dive_grid", fileExtension: "jpg") {
                image
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        GeometryReader { photoProxy in
                            let frame = cropFrame(in: photoProxy.size)
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(MegrumTheme.lavender, lineWidth: 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(MegrumTheme.lavender.opacity(0.16))
                                )
                                .frame(width: frame.width, height: frame.height)
                                .position(x: frame.midX, y: frame.midY)
                                .animation(.easeInOut(duration: 0.6), value: cropProgress)
                        }
                    }
                    .padding(.horizontal, 24)
            }
            Spacer(minLength: 0)
            Text("読み取れなかったカードに枠を合わせよう")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .padding(.bottom, 130)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .allowsHitTesting(false)
    }

    /// 登録完了ビート：マイグッズ一覧に9枚並んだ状態の再現＋完了トースト。
    private var savedStage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("マイグッズ")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.top, 70)

            Text("譲る候補 9")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(MegrumTheme.lavender, in: Capsule(style: .continuous))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(TutorialDemoAssets.diveCardNames, id: \.self) { name in
                    if let image = TutorialDemoAssets.image(named: name) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 128)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                Text("# TWICE # DIVE")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.black.opacity(0.55), in: Capsule(style: .continuous))
                                    .padding(5)
                            }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            Label("9件登録しました", systemImage: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(MegrumTheme.ok, in: Capsule(style: .continuous))
                .padding(.bottom, 140)
        }
        .allowsHitTesting(false)
    }

    // MARK: 部品

    private func demoSheetHeader(title: String) -> some View {
        HStack {
            Text("キャンセル")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MegrumTheme.muted)
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            Text("キャンセル")
                .font(.system(size: 15, weight: .semibold))
                .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 70)
        .padding(.bottom, 12)
        .background(MegrumTheme.canvas)
    }

    private var lensResultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Google Lens", systemImage: "camera.viewfinder")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Text("TWICE『DIVE』トレカ")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("シリーズ：#DIVE")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(14)
        .frame(width: 230, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
    }

    // MARK: スクリプト状態

    private var selectedMetaIDs: Set<UUID> {
        switch beat {
        case .assignMembers, .assignSeries:
            return Set(createMetas.prefix(2).map(\.id))
        default:
            return []
        }
    }

    private var gridPhotoDrafts: [GoodsCreatePhotoDraft] {
        guard let data = TutorialDemoAssets.diveGridData else { return [] }
        return [GoodsCreatePhotoDraft(upload: GoodsPhotoUpload(data: data, contentType: "image/jpeg"))]
    }

    private func cardPhotoDrafts(count: Int) -> [GoodsCreatePhotoDraft] {
        TutorialDemoAssets.diveCardNames.prefix(count).compactMap { name in
            TutorialDemoAssets.imageData(named: name).map {
                GoodsCreatePhotoDraft(upload: GoodsPhotoUpload(data: $0, contentType: "image/png"))
            }
        }
    }

    private func configureDraft() {
        draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        switch beat {
        case .openEditor:
            break
        case .pickOshi:
            draft.groupID = twiceGroup?.id
        default:
            draft.groupID = twiceGroup?.id
            draft.goodsTypeID = tradingCardType?.id
        }
        if beat == .assignMembers || beat == .assignSeries {
            createMetas = cardPhotoDrafts(count: 9).map { photo in
                GoodsCreateMetaDraft(
                    photoID: photo.id,
                    title: "",
                    tagNames: beat == .assignSeries ? ["DIVE"] : []
                )
            }
        } else {
            createMetas = []
        }
    }

    // MARK: 指の演技

    private func runChoreo(size: CGSize) async {
        cropProgress = 0
        try? await Task.sleep(nanoseconds: 300_000_000)
        switch beat {
        case .openEditor:
            pointer.appear(at: CGPoint(x: size.width * 0.18, y: size.height * 0.86))
            await pointer.tap()
            pointer.hide()
        case .pickOshi:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.30))
            await pointer.tap()
        case .pickType:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.45))
            await pointer.tap()
            await pointer.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.62), duration: 0.4)
            await pointer.tap()
        case .pickPhotos:
            pointer.appear(at: CGPoint(x: size.width * 0.68, y: size.height * 0.33))
            await pointer.tap()
        case .bulkDetect:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.36))
            await pointer.tap()
        case .manualCrop:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.5))
            await pointer.tap()
            await pointer.move(to: CGPoint(x: size.width * 0.68, y: size.height * 0.62), duration: 0.4)
            cropProgress = 1
            await pointer.drag(to: CGPoint(x: size.width * 0.80, y: size.height * 0.72), duration: 0.7)
        case .assignMembers:
            pointer.appear(at: CGPoint(x: size.width * 0.25, y: size.height * 0.35))
            await pointer.tap()
            await pointer.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.35), duration: 0.35)
            await pointer.tap()
        case .assignSeries:
            pointer.appear(at: CGPoint(x: size.width * 0.3, y: size.height * 0.5))
            await pointer.tap()
        case .saved:
            break
        }
    }

    /// 手動切り抜き枠：開始位置（中央小さめ）→右下カードへフィット。
    private func cropFrame(in photoSize: CGSize) -> CGRect {
        let cell = CGSize(width: photoSize.width / 3, height: photoSize.height / 3)
        if cropProgress < 0.5 {
            return CGRect(
                x: photoSize.width * 0.30, y: photoSize.height * 0.36,
                width: cell.width * 1.3, height: cell.height * 1.3
            )
        }
        // 右下（3行目・2列目＝読み取れなかったカード）へフィット。
        return CGRect(
            x: cell.width * 1.06, y: cell.height * 2.04,
            width: cell.width * 0.88, height: cell.height * 0.92
        )
    }
}
