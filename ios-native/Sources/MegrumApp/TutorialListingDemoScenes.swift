import MegrumCore
import MegrumDesign
import SwiftUI

/// 第6章 個別募集作成デモ。実物のステップView（Haves/Options/Exchange）を
/// ビートごとのスクリプト状態で描画し、指アイコンの実演を重ねる。
struct TutorialListingDemoSceneView: View {
    let beat: TutorialListingDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    @StateObject private var pointer = TutorialPointerChoreographer()

    // Haves（譲るもの）
    @State private var havesTab: IndividualListingHavesStep.Tab = .goods
    @State private var havesFilter = IndividualListingSelectionFilter()
    @State private var havesCashPricingMode: IndividualListingCashPricingMode = .listPrice
    @State private var havesCashAmount = 0
    // Options（欲しいもの）
    @State private var optionKind: IndividualListingOptionKind = .wish
    @State private var wishFilter = IndividualListingSelectionFilter()
    @State private var selectedWishLogic: ListingLogic = .one
    @State private var conditionGroupID: UUID?
    @State private var conditionMemberIDs: Set<UUID> = []
    @State private var excludesConditionMembers = false
    @State private var conditionGoodsTypeID: UUID?
    @State private var conditionTagNames: [String] = []
    @State private var conditionQuantity = 1
    @State private var optionsCashPricingMode: IndividualListingCashPricingMode = .listPrice
    @State private var optionsCashAmount = 0
    // Exchange（交換条件）
    @State private var handoffMethod: IndividualListingHandoffDraft = .both
    @State private var localPrefecture = "東京都"
    @State private var localPlaceMemo = "会場周辺（例：東京ドーム）"
    @State private var localSchedule = "土日ならOK"
    @State private var shippingFee: IndividualListingShippingFeeDraft = .negotiate
    @State private var shippingDays: IndividualListingShippingDaysDraft = .twoToFourDays
    @State private var acceptsOutsideCondition = true
    @State private var note = "スリーブに入れて持っていきます"

    private var twiceGroup: OshiGroup? {
        demoAppState.oshiGroups.first { $0.name.localizedCaseInsensitiveContains("TWICE") }
    }

    private var tradingCardType: GoodsType? {
        demoAppState.goodsTypes.first { $0.name.contains("トレカ") }
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
        case .openEditor:
            listingListStage
        case .havesOverview, .havesCashTab, .havesCashAmount:
            editorStage(stepIndex: 1, title: "譲るものを選ぶ") {
                IndividualListingHavesStep(
                    inventory: demoAppState.inventory,
                    selectedIDs: [],
                    filter: $havesFilter,
                    groups: demoAppState.oshiGroups,
                    goodsTypes: demoAppState.goodsTypes,
                    selectedTab: $havesTab,
                    cashPricingMode: $havesCashPricingMode,
                    cashAmount: $havesCashAmount,
                    onToggle: { _ in }
                )
            }
        case .wishOverview, .wishConditionTab, .wishCashTab:
            editorStage(stepIndex: 2, title: "欲しいものを登録") {
                IndividualListingOptionsStep(
                    optionKind: $optionKind,
                    inventory: demoAppState.inventory,
                    wishes: demoAppState.wishes,
                    selectedWishIDs: [],
                    selectedWishLogic: $selectedWishLogic,
                    wishFilter: $wishFilter,
                    genres: demoAppState.oshiGenres,
                    groups: demoAppState.oshiGroups,
                    myOshiGroupIDs: [],
                    characters: demoAppState.oshiCharacters,
                    goodsTypes: demoAppState.goodsTypes,
                    selectedConditionGroupID: $conditionGroupID,
                    selectedConditionMemberIDs: $conditionMemberIDs,
                    excludesSelectedConditionMembers: $excludesConditionMembers,
                    selectedConditionGoodsTypeID: $conditionGoodsTypeID,
                    selectedConditionTagNames: $conditionTagNames,
                    conditionQuantity: $conditionQuantity,
                    cashPricingMode: $optionsCashPricingMode,
                    cashAmount: $optionsCashAmount,
                    onToggleWish: { _ in },
                    onToggleConditionMember: { _ in },
                    onLoadCharacters: { _ in },
                    onCreateOshiRequest: { _ in }
                )
            }
        case .exchangeMethod, .exchangeLocal, .exchangeMail, .exchangeOffSpec, .exchangeNote, .save:
            editorStage(stepIndex: 3, title: "交換条件を設定する") {
                IndividualListingExchangeStep(
                    handoffMethod: $handoffMethod,
                    localPrefecture: $localPrefecture,
                    localPlaceMemo: $localPlaceMemo,
                    localSchedule: $localSchedule,
                    shippingFee: $shippingFee,
                    shippingDays: $shippingDays,
                    acceptsOutsideCondition: $acceptsOutsideCondition,
                    note: $note
                )
            }
        case .afterSave:
            afterSaveStage
        }
    }

    /// 一覧（デモ起点）：右下の「募集を追加」を指がタップする。
    private var listingListStage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("個別募集")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.top, 70)
            Spacer()
            Text("個別募集はまだありません")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity)
            Text("マイグッズとほしいものを選んで、ピンポイントの交換条件を作れます。")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) {
            Label("募集を追加", systemImage: "plus")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.sky, MegrumTheme.lavender],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule(style: .continuous)
                )
                .padding(.trailing, 20)
                .padding(.bottom, 130)
        }
        .allowsHitTesting(false)
    }

    /// 実ステップViewをエディタ風のクローム（ヘッダー＋ステップドット）で包む。
    private func editorStage<Content: View>(
        stepIndex: Int,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MegrumTheme.muted)
                    Spacer()
                    Text("個別募集を作成")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Text("\(stepIndex)/3")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                Text(title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 70)
            .padding(.bottom, 8)

            ScrollView {
                content()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }

            demoBottomBar
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .allowsHitTesting(false)
    }

    private var demoBottomBar: some View {
        HStack {
            Text("戻る")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Spacer()
            Text(beat == .save ? "保存する" : "次へ")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 26)
                .frame(height: 46)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.sky, MegrumTheme.lavender],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 120)
        .background(.white.opacity(0.94))
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
        switch beat {
        case .havesOverview:
            havesTab = .goods
        case .havesCashTab:
            havesTab = .cash
            havesCashPricingMode = .listPrice
        case .havesCashAmount:
            havesTab = .cash
            havesCashPricingMode = .specifiedAmount
            havesCashAmount = 1500
        case .wishOverview:
            optionKind = .wish
        case .wishConditionTab:
            optionKind = .condition
            conditionGroupID = twiceGroup?.id
            conditionGoodsTypeID = tradingCardType?.id
        case .wishCashTab:
            optionKind = .cash
            optionsCashPricingMode = .listPrice
        default:
            break
        }
    }

    // MARK: 指の演技

    private func runChoreo(size: CGSize) async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        switch beat {
        case .openEditor:
            pointer.appear(at: CGPoint(x: size.width * 0.78, y: size.height * 0.84))
            await pointer.tap()
        case .havesCashTab:
            pointer.appear(at: CGPoint(x: size.width * 0.72, y: size.height * 0.24))
            await pointer.tap()
        case .havesCashAmount:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.42))
            await pointer.tap()
        case .wishConditionTab:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.24))
            await pointer.tap()
        case .wishCashTab:
            pointer.appear(at: CGPoint(x: size.width * 0.8, y: size.height * 0.24))
            await pointer.tap()
        case .exchangeMethod:
            pointer.appear(at: CGPoint(x: size.width * 0.8, y: size.height * 0.28))
            await pointer.tap()
        case .exchangeLocal:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.45))
            await pointer.tap()
        case .exchangeMail:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.62))
            await pointer.tap()
        case .exchangeOffSpec:
            pointer.appear(at: CGPoint(x: size.width * 0.82, y: size.height * 0.74))
            await pointer.tap()
        case .exchangeNote:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.82))
            await pointer.tap()
        case .save:
            pointer.appear(at: CGPoint(x: size.width * 0.78, y: size.height * 0.87))
            await pointer.tap()
        case .havesOverview, .wishOverview, .afterSave:
            break
        }
    }
}
