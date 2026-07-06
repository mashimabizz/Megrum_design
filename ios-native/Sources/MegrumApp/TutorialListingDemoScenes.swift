import MegrumCore
import MegrumDesign
import SwiftUI

/// 第6章 個別募集作成デモ。実物のエディタ本体（IndividualListingEditorContent＝ヘッダー1/3ドット込み）と
/// 実物の下部バー（IndividualListingEditorBottomBar）を、スクリプト済み draft で駆動する（FB⑩）。
struct TutorialListingDemoSceneView: View {
    let beat: TutorialListingDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    @StateObject private var pointer = TutorialPointerChoreographer()
    @State private var draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
    @State private var havesTab: IndividualListingHavesStep.Tab = .goods
    @State private var haveFilter = IndividualListingSelectionFilter()
    @State private var wishFilter = IndividualListingSelectionFilter()

    private var step: IndividualListingEditorStep {
        switch beat {
        case .havesOverview, .havesCashTab, .havesCashAmount:
            return .haves
        case .wishOverview, .wishConditionTab, .wishCashTab:
            return .options
        default:
            return .exchange
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                stage
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
    private var stage: some View {
        switch beat {
        case .afterSave:
            // 実物の個別募集一覧（プレビューデータの募集カードが載った状態）。
            IndividualListingsScreen(appState: demoAppState)
                .allowsHitTesting(false)
        default:
            editorStage
        }
    }

    /// 実物のエディタ画面（ヘッダー＋ステップ本体＋下部バー）。
    /// 下部セクションを見せるビートは、本体を「画面高＋lift」の背高フレームで描画してから
    /// 上へオフセットする（単純なoffsetではScrollViewの初期ビューポート外が描画されないため）。
    private var editorStage: some View {
        VStack(spacing: 0) {
            GeometryReader { inner in
                IndividualListingEditorContent(
                draft: $draft,
                havesTab: $havesTab,
                haveSelectionFilter: $haveFilter,
                wishSelectionFilter: $wishFilter,
                step: step,
                inventory: demoAppState.inventory,
                wishes: demoAppState.wishes,
                genres: demoAppState.oshiGenres,
                myOshiGroupIDs: [TutorialSampleMasterData.twiceGroupID],
                groups: demoAppState.oshiGroups.isEmpty ? TutorialSampleMasterData.groups : demoAppState.oshiGroups,
                characters: demoAppState.oshiCharacters.isEmpty ? TutorialSampleMasterData.characters : demoAppState.oshiCharacters,
                goodsTypes: demoAppState.goodsTypes.isEmpty ? TutorialSampleMasterData.goodsTypes : demoAppState.goodsTypes,
                stepValidationMessage: nil,
                optionReviewCount: stagedOptionCount,
                onBack: {},
                onSelectStep: { _ in },
                onShowOptionReview: {},
                onToggleHave: { _ in },
                onToggleWish: { _ in },
                onLoadCharacters: { _ in },
                onCreateOshiRequest: { _ in }
                )
                .padding(.top, 58)
                .frame(width: inner.size.width, height: inner.size.height + contentLift)
                // 下部セクション（郵送/条件外/メモ）を見せるビートは「スクロール後」の位置まで持ち上げる。
                .offset(y: -contentLift)
            }
            .clipped()

            IndividualListingEditorBottomBar(
                step: step,
                havesTab: havesTab,
                optionKind: draft.optionKind,
                selectedHaveCount: draft.selectedHaveIDs.count,
                selectedWishCount: draft.selectedWishIDs.count,
                stagedOptionCount: stagedOptionCount,
                haveLogic: $draft.haveLogic,
                haveMinimumCount: $draft.haveMinimumCount,
                wishLogic: $draft.wishLogic,
                wishMinimumCount: $draft.wishMinimumCount,
                usesConditionLogicChoice: false,
                showsSelectAllVisibleButton: false,
                selectAllVisibleButtonTitle: "",
                canSelectAllVisible: false,
                isDisabled: false,
                isSaving: false,
                onBack: {},
                onSelectAllVisible: {},
                onAddOption: {},
                onPrimary: {}
            )
            .padding(.bottom, 84)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .allowsHitTesting(false)
    }

    /// 該当セクションが見える位置までコンテンツを持ち上げる量（FB12）。
    private var contentLift: CGFloat {
        switch beat {
        case .exchangeMail:
            return 320
        case .exchangeOffSpec:
            return 470
        case .exchangeNote:
            return 590
        case .save:
            return 590
        default:
            return 0
        }
    }

    private var stagedOptionCount: Int {
        switch beat {
        case .wishCashTab, .exchangeMethod, .exchangeLocal, .exchangeMail, .exchangeOffSpec, .exchangeNote, .save:
            return 2
        case .wishConditionTab:
            return 1
        default:
            return 0
        }
    }

    // MARK: スクリプト状態

    private func configureState() {
        draft = IndividualListingDraft(mode: .create(preselectedWishID: nil))
        havesTab = .goods
        switch beat {
        case .havesOverview:
            break
        case .havesCashTab:
            havesTab = .cash
            draft.haveCashPricingMode = .listPrice
        case .havesCashAmount:
            havesTab = .cash
            draft.haveCashPricingMode = .specifiedAmount
            draft.haveCashAmount = 1500
        case .wishOverview:
            draft.optionKind = .wish
        case .wishConditionTab:
            draft.optionKind = .condition
            draft.conditionGroupID = TutorialSampleMasterData.twiceGroupID
            draft.conditionGoodsTypeID = TutorialSampleMasterData.tradingCardTypeID
        case .wishCashTab:
            draft.optionKind = .cash
            draft.cashPricingMode = .listPrice
        case .exchangeMethod, .exchangeLocal, .exchangeMail, .exchangeOffSpec, .exchangeNote, .save, .afterSave:
            draft.haveCashPricingMode = .specifiedAmount
            draft.haveCashAmount = 1500
            draft.handoffMethod = .both
            draft.localPrefecture = "東京都"
            draft.localPlaceMemo = "会場周辺（例：東京ドーム）"
            // カレンダー展開で縦に伸びないよう日程は「相談して決める」のまま。
            draft.localSchedule = ""
            draft.shippingFee = .negotiate
            draft.shippingDays = .twoToFourDays
            draft.acceptsOutsideCondition = true
            draft.note = "スリーブに入れて持っていきます"
        }
    }

    // MARK: 指の演技

    private func runChoreo(size: CGSize) async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        switch beat {
        case .havesCashTab:
            pointer.appear(at: CGPoint(x: size.width * 0.72, y: size.height * 0.20))
            await pointer.tap()
        case .havesCashAmount:
            pointer.appear(at: CGPoint(x: size.width * 0.72, y: size.height * 0.30))
            await pointer.tap()
        case .wishConditionTab:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.20))
            await pointer.tap()
        case .wishCashTab:
            pointer.appear(at: CGPoint(x: size.width * 0.8, y: size.height * 0.20))
            await pointer.tap()
        case .exchangeMethod:
            pointer.appear(at: CGPoint(x: size.width * 0.8, y: size.height * 0.24))
            await pointer.tap()
        case .exchangeLocal:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.42))
            await pointer.tap()
        case .exchangeMail:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.45))
            await pointer.tap()
        case .exchangeOffSpec:
            pointer.appear(at: CGPoint(x: size.width * 0.82, y: size.height * 0.52))
            await pointer.tap()
        case .exchangeNote:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.62))
            await pointer.tap()
        case .save:
            pointer.appear(at: CGPoint(x: size.width * 0.78, y: size.height * 0.88))
            await pointer.tap()
        case .havesOverview, .wishOverview, .afterSave:
            break
        }
    }
}
