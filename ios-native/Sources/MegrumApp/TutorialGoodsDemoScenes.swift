import MegrumCore
import MegrumDesign
import SwiftUI

/// 第4章 マイグッズ登録デモ。実物の作成ウィザード（GoodsInventoryCreateFlowView）と
/// 一括設定フッター（GoodsInventoryCreateMetaFooterView）をスクリプト状態で描画し、
/// 指アイコンの実演を重ねる。マスタは TutorialSampleMasterData（TWICE×トレカ）で確実に選択済み表示にする。
struct TutorialGoodsDemoSceneView: View {
    let beat: TutorialGoodsDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    @StateObject private var pointer = TutorialPointerChoreographer()
    @State private var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
    @State private var createMetas: [GoodsCreateMetaDraft] = []
    /// ビート内で写真IDが揺れないよう、一度だけ生成してキャッシュする（FB⑤：リンク切れ対策）。
    @State private var photoCache: [GoodsCreatePhotoDraft] = []
    /// 4-7：一括読み取りの2段階（0=元写真＋ボタン、1=切り抜き結果7枚）。
    @State private var bulkPhase = 0
    /// 4-8：左上→右下ドラッグに追従する切り抜き進捗（0=開始点、1=カードにフィット）。
    @State private var cropProgress: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                stageContent(size: proxy.size)
                TutorialPointerLayer(choreo: pointer)
            }
            .task(id: beat) {
                configureState()
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
            wizard(step: .shoot, photos: photoCache, statusMessage: nil)

        case .bulkDetect:
            wizard(
                step: .shoot,
                photos: bulkPhase == 0 ? gridPhotoOnly : photoCache,
                statusMessage: bulkPhase == 0 ? nil : "7枚を切り抜きました（右下の2枚は読み取れませんでした）"
            )

        case .manualCrop:
            manualCropStage

        case .assignMembers, .seriesButton:
            metaStage

        case .seriesSheetLens, .seriesPaste:
            ZStack {
                metaStage.blur(radius: 2)
                Color.black.opacity(0.25).ignoresSafeArea()
                seriesSheetCard(showsPastedTag: beat == .seriesPaste)
            }

        case .lensOpened, .lensCopy:
            lensStage(showsCopyBubble: beat == .lensCopy)

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
                    groups: TutorialSampleMasterData.groups,
                    isLoadingOshiGroups: false,
                    goodsTypes: TutorialSampleMasterData.goodsTypes,
                    isLoadingGoodsTypes: false,
                    oshiCharacters: TutorialSampleMasterData.characters,
                    allowsMemberSelection: true,
                    selectedGroupName: draft.groupID == nil ? nil : TutorialSampleMasterData.twiceGroup.name,
                    createError: nil,
                    canAdvanceFromCommon: draft.groupID != nil && draft.goodsTypeID != nil,
                    isTradingCardType: draft.goodsTypeID != nil,
                    isProcessingTradingCardBulk: false,
                    tradingCardBulkStatusMessage: statusMessage,
                    isItemReadOnly: false,
                    isCreatingGoodsEntry: false,
                    onShowOshiPicker: {},
                    onCommonNext: {},
                    onAddPhoto: {},
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

    /// 詳細ステップ＋実物の一括設定フッター（メンバー／シリーズボタンが見える状態）。
    private var metaStage: some View {
        VStack(spacing: 0) {
            demoSheetHeader(title: "マイグッズに追加")
            ScrollView {
                GoodsInventoryCreateFlowView(
                    draft: $draft,
                    createMetas: $createMetas,
                    createStep: .meta,
                    createPhotos: photoCache,
                    selectedCreateMetaIDs: selectedMetaIDs,
                    groups: TutorialSampleMasterData.groups,
                    isLoadingOshiGroups: false,
                    goodsTypes: TutorialSampleMasterData.goodsTypes,
                    isLoadingGoodsTypes: false,
                    oshiCharacters: TutorialSampleMasterData.characters,
                    allowsMemberSelection: true,
                    selectedGroupName: TutorialSampleMasterData.twiceGroup.name,
                    createError: nil,
                    canAdvanceFromCommon: true,
                    isTradingCardType: true,
                    isProcessingTradingCardBulk: false,
                    tradingCardBulkStatusMessage: nil,
                    isItemReadOnly: false,
                    isCreatingGoodsEntry: false,
                    onShowOshiPicker: {},
                    onCommonNext: {},
                    onAddPhoto: {},
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
                .padding(.bottom, 16)
            }
            GoodsInventoryCreateMetaFooterView(
                selectedCount: selectedMetaIDs.count,
                totalCount: createMetas.count,
                memberOptions: TutorialSampleMasterData.characters,
                allowsMemberSelection: true,
                canSaveMetas: true,
                isCreatingGoodsEntry: false,
                onAssignMember: { _ in },
                onShowTagAssignment: {},
                onBack: {},
                onSave: {}
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .allowsHitTesting(false)
    }

    /// 手動切り抜き（FB④）：黄色枠が指の左上→右下ドラッグに追従してカードにフィットする。
    private var manualCropStage: some View {
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
                            Rectangle()
                                .fill(Color.yellow.opacity(0.12))
                                .overlay {
                                    Rectangle().stroke(Color.yellow, lineWidth: 3)
                                }
                                .frame(width: frame.width, height: frame.height)
                                .position(x: frame.midX, y: frame.midY)
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

    /// シリーズ一括設定シート（実物のシート構成に合わせた再現）。
    private func seriesSheetCard(showsPastedTag: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("シリーズをまとめて設定")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack {
                Text(showsPastedTag ? "DIVE" : "シリーズ名を入力")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(showsPastedTag ? MegrumTheme.ink : MegrumTheme.muted.opacity(0.7))
                Spacer()
                if showsPastedTag {
                    Text("ペースト")
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(MegrumTheme.lavender.opacity(0.14), in: Capsule(style: .continuous))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            Label("Google Lensで調べる", systemImage: "camera.viewfinder")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(MegrumTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            Text(showsPastedTag ? "選択中の9件に #DIVE を設定します" : "写真からシリーズ名を調べられます")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            // 実物のシリーズ一括設定シートのCTAに合わせる（途中で名前が変わって見えないように固定）。
            Text("登録")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(colors: [MegrumTheme.sky, MegrumTheme.lavender], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 26)
        .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
        .allowsHitTesting(false)
    }

    /// Google Lens 起動画面（外部アプリのためモック。カード写真＋検索結果）。
    private func lensStage(showsCopyBubble: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "xmark")
                Spacer()
                Label("Google Lens", systemImage: "camera.viewfinder")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Image(systemName: "square.and.arrow.up")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.top, 70)
            .padding(.bottom, 14)

            if let image = TutorialDemoAssets.image(named: "twice_dive_card_5") {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.9), lineWidth: 2)
                    }
                    .padding(.top, 8)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("検索結果")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 10) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .foregroundStyle(.white)
                    // 選択反転はコピー対象のシリーズ名「DIVE」だけに掛ける（4-13/4-14の物語と一致）。
                    HStack(spacing: 0) {
                        Text("TWICE『")
                        Text("DIVE")
                            .background {
                                if showsCopyBubble {
                                    Color.blue.opacity(0.45)
                                }
                            }
                        Text("』トレカ 特典")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    Spacer()
                }
                .padding(14)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if showsCopyBubble {
                        Text("コピー")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.white, in: Capsule(style: .continuous))
                            .offset(y: -40)
                    }
                }

                Text("TWICE 日本5thアルバム「DIVE」")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer()
        }
        .background(Color.black.opacity(0.92).ignoresSafeArea())
        .allowsHitTesting(false)
    }

    /// 登録完了：実物の GoodsTile（タグ右上・メンバー名右下）＋登録直後の緑チェック（左上）。
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

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(savedItems) { item in
                        GoodsTile(
                            item: item,
                            // マイグッズ一覧と同じ文脈（メタ行が「譲る候補」表記になる）。
                            context: .inventory,
                            onOpenDetail: {},
                            onAction: { _ in },
                            usesSystemContextMenu: false,
                            onLongPress: nil
                        )
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white, MegrumTheme.ok)
                                .padding(5)
                        }
                    }
                }
                .padding(.bottom, 140)
            }
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

    // MARK: スクリプト状態

    private var selectedMetaIDs: Set<UUID> {
        switch beat {
        case .assignMembers, .seriesButton, .seriesSheetLens, .seriesPaste:
            return Set(createMetas.map(\.id))
        default:
            return []
        }
    }

    private var gridPhotoOnly: [GoodsCreatePhotoDraft] {
        TutorialDemoAssets.diveGridData.map {
            [GoodsCreatePhotoDraft(upload: GoodsPhotoUpload(data: $0, contentType: "image/jpeg"))]
        } ?? []
    }

    private func makeCardPhotos(count: Int) -> [GoodsCreatePhotoDraft] {
        TutorialDemoAssets.diveCardNames.prefix(count).compactMap { name in
            TutorialDemoAssets.imageData(named: name).map {
                GoodsCreatePhotoDraft(upload: GoodsPhotoUpload(data: $0, contentType: "image/png"))
            }
        }
    }

    private var savedItems: [GoodsItem] {
        // デモで割り当てたのはサナ・モモの2枚だけ。残りはメンバー未設定のまま登録された状態を見せる
        //（4-9「あとからでもOK」と接続。全員に名前が付いていると途中経過と矛盾する）。
        let assignedMembers = ["サナ", "モモ"]
        return TutorialDemoAssets.diveCardNames.enumerated().compactMap { index, name in
            guard let url = NativePreviewData.testGoodsImageURL(name) else { return nil }
            let member = index < assignedMembers.count ? assignedMembers[index] : nil
            return GoodsItem(
                id: UUID(uuidString: "00000000-0000-0000-9997-00000000010\(index)") ?? UUID(),
                ownerID: TutorialSampleHomeData.placeholderViewerID,
                groupID: TutorialSampleMasterData.twiceGroupID,
                goodsTypeID: TutorialSampleMasterData.tradingCardTypeID,
                groupName: "TWICE",
                memberName: member,
                goodsTypeName: "トレカ",
                title: member.map { "\($0) DIVE トレカ" } ?? "DIVE トレカ",
                imageURL: url,
                tags: [GoodsTag(id: UUID(), name: "DIVE")],
                quantity: 1
            )
        }
    }

    private func configureState() {
        draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        bulkPhase = 0
        cropProgress = 0
        switch beat {
        case .openEditor:
            photoCache = []
            createMetas = []
        case .pickOshi:
            draft.groupID = TutorialSampleMasterData.twiceGroupID
            photoCache = []
            createMetas = []
        case .pickType:
            draft.groupID = TutorialSampleMasterData.twiceGroupID
            draft.goodsTypeID = TutorialSampleMasterData.tradingCardTypeID
            photoCache = []
            createMetas = []
        case .pickPhotos:
            draft.groupID = TutorialSampleMasterData.twiceGroupID
            draft.goodsTypeID = TutorialSampleMasterData.tradingCardTypeID
            photoCache = gridPhotoOnly
            createMetas = []
        case .bulkDetect:
            draft.groupID = TutorialSampleMasterData.twiceGroupID
            draft.goodsTypeID = TutorialSampleMasterData.tradingCardTypeID
            photoCache = makeCardPhotos(count: 7)
            createMetas = []
        case .manualCrop, .lensOpened, .lensCopy, .saved:
            break
        case .assignMembers, .seriesButton, .seriesSheetLens, .seriesPaste:
            draft.groupID = TutorialSampleMasterData.twiceGroupID
            draft.goodsTypeID = TutorialSampleMasterData.tradingCardTypeID
            // 写真→メタを同一キャッシュから作り、photoID のリンク切れを防ぐ（FB⑤）。
            photoCache = makeCardPhotos(count: 9)
            let members = TutorialSampleMasterData.characters
            createMetas = photoCache.enumerated().map { index, photo in
                GoodsCreateMetaDraft(
                    photoID: photo.id,
                    // 4-9で割り当てたメンバーは以降のビートでも保持する（巻き戻って見えないように）。
                    memberID: index < 2 ? members[index].id : nil,
                    title: "",
                    // タグの適用は「登録」ボタン押下後（実アプリ同様）。ペースト時点で背景の
                    // グリッドに先行反映すると1ビート早い状態ジャンプになる。
                    tagNames: []
                )
            }
        }
    }

    // MARK: 指の演技

    private func runChoreo(size: CGSize) async {
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
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.47))
            await pointer.tap()
        case .pickPhotos:
            pointer.appear(at: CGPoint(x: size.width * 0.68, y: size.height * 0.30))
            await pointer.tap()
        case .bulkDetect:
            // 元写真の下にある「まとめて登録」を押す→切り抜き結果へ切替（FB③）。
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.66))
            try? await Task.sleep(nanoseconds: 500_000_000)
            await pointer.tap()
            withAnimation(.easeInOut(duration: 0.3)) {
                bulkPhase = 1
            }
            pointer.hide()
        case .manualCrop:
            // 対象カード（右下エリアの未読み取り分）の左上→右下へドラッグ（FB④）。
            let start = CGPoint(x: size.width * 0.38, y: size.height * 0.545)
            let end = CGPoint(x: size.width * 0.62, y: size.height * 0.75)
            pointer.appear(at: start)
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.85)) {
                cropProgress = 1
            }
            await pointer.drag(to: end, duration: 0.85)
            // ドラッグ終点は下部キャプションの裏に入るため、演技後は指を消す。
            try? await Task.sleep(nanoseconds: 350_000_000)
            pointer.hide()
        case .assignMembers:
            pointer.appear(at: CGPoint(x: size.width * 0.30, y: size.height * 0.80))
            await pointer.tap()
        case .seriesButton:
            pointer.appear(at: CGPoint(x: size.width * 0.62, y: size.height * 0.80))
            await pointer.tap()
        case .seriesSheetLens:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.52))
            await pointer.tap()
        case .lensCopy:
            // 選択反転＋コピーボタンが出ている検索行の「DIVE」を指す。
            pointer.appear(at: CGPoint(x: size.width * 0.35, y: size.height * 0.585))
            await pointer.tap()
        case .lensOpened:
            break
        case .seriesPaste:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.42))
            await pointer.tap()
        case .saved:
            break
        }
    }

    /// 手動切り抜き枠：対象カード（3行目・中央=未読み取り分）の左上を起点に、右下へ広がる。
    private func cropFrame(in photoSize: CGSize) -> CGRect {
        let cell = CGSize(width: photoSize.width / 3, height: photoSize.height / 3)
        let origin = CGPoint(x: cell.width * 1.04, y: cell.height * 2.02)
        let fullSize = CGSize(width: cell.width * 0.92, height: cell.height * 0.94)
        let progress = max(0.12, cropProgress)
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: fullSize.width * progress,
            height: fullSize.height * progress
        )
    }
}
