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
            afterSaveStage
        default:
            editorStage
        }
    }

    /// 実物のエディタ画面（ヘッダー＋ステップ本体＋下部バー）。
    private var editorStage: some View {
        VStack(spacing: 0) {
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

    /// 保存後：一覧に1枚目のカードが載った状態の再現＋完了トースト。
    private var afterSaveStage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("個別募集")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.top, 70)

            Text("個別募集 1 / 1")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(MegrumTheme.lavender, in: Capsule(style: .continuous))

            HStack(alignment: .top, spacing: 12) {
                summaryPanel(title: "求めるもの", lines: ["選択肢1：TWICE × トレカ", "選択肢2：定価もOK"])
                summaryPanel(title: "譲るもの", lines: ["金額指定 ¥1,500"])
            }

            summaryPanel(title: "交換条件", lines: ["現地交換・郵送OK", "現地：東京都 / 土日", "郵送：送料 要相談・2〜4日"])

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            Label("個別募集を作成しました", systemImage: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(MegrumTheme.ok, in: Capsule(style: .continuous))
                .padding(.bottom, 140)
        }
        .allowsHitTesting(false)
    }

    private func summaryPanel(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
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
            draft.localSchedule = "土日ならOK"
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
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.60))
            await pointer.tap()
        case .exchangeOffSpec:
            pointer.appear(at: CGPoint(x: size.width * 0.82, y: size.height * 0.72))
            await pointer.tap()
        case .exchangeNote:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.80))
            await pointer.tap()
        case .save:
            pointer.appear(at: CGPoint(x: size.width * 0.78, y: size.height * 0.88))
            await pointer.tap()
        case .havesOverview, .wishOverview, .afterSave:
            break
        }
    }
}
