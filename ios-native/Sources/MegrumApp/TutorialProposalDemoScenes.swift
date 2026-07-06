import MegrumCore
import MegrumDesign
import SwiftUI

/// 第7章 打診デモ（激求の例）。実物の候補詳細シート・相手プロフィール・打診確認画面を
/// プレビューデータで描画し、指アイコンの実演を重ねる。
struct TutorialProposalDemoSceneView: View {
    let beat: TutorialProposalDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    @StateObject private var pointer = TutorialPointerChoreographer()

    /// 激求ヒット（PreviewMegrumRepository が個別募集ヒットを付けている相手グッズ）。
    private var targetItem: GoodsItem? {
        let partnerItems = demoAppState.homeMatchedItems.filter { $0.ownerID != demoAppState.viewer?.id }
        return partnerItems.first { demoAppState.homeCandidateConditionSignals[$0.id]?.individualListingSelection != nil }
            ?? partnerItems.first
    }

    private var sheetPayload: HomeDiscoverySheetPayload? {
        guard let item = targetItem else { return nil }
        let goods = HomeMockGoods.from(item: item, index: 0, goodsTypes: demoAppState.goodsTypes)
        let signals = demoAppState.homeCandidateConditionSignals[item.id]
            ?? HomeCandidateConditionSignalDefaults.previewSignals(matchedItems: [item], possibleItems: [])[item.id]
        guard let signals else { return nil }
        return HomeDiscoverySheetPayload(goods: goods, signals: signals)
    }

    private var viewerOfferGoods: [HomeMockGoods] {
        demoAppState.inventory
            .filter { $0.marketAvailableQuantity > 0 }
            .prefix(8)
            .enumerated()
            .map { index, item in
                HomeMockGoods.from(item: item, index: index, goodsTypes: demoAppState.goodsTypes)
            }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                stage
                TutorialPointerLayer(choreo: pointer)
            }
            .task(id: beat) {
                await runChoreo(size: proxy.size)
            }
        }
    }

    // MARK: シーン本体

    @ViewBuilder
    private var stage: some View {
        switch beat {
        case .profile:
            PublicUserProfileScreen(
                appState: demoAppState,
                userID: targetItem?.ownerID ?? NativePreviewData.partnerID,
                presentationContext: .standalone
            )
            .allowsHitTesting(false)

        case .confirm, .send:
            if let item = targetItem {
                NavigationStack {
                    ProposalCreateFlow(
                        appState: demoAppState,
                        targetItem: item,
                        receiverGoodsIDs: [item.id],
                        initialStep: .confirm
                    )
                }
                .allowsHitTesting(false)
            } else {
                MegrumTheme.canvas.ignoresSafeArea()
            }

        default:
            // 候補詳細シート（激求ヒット）。openDetail〜pickMore はこの画面上で指が案内する。
            if let payload = sheetPayload {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(MegrumTheme.ink.opacity(0.16))
                        .frame(width: 44, height: 5)
                        .padding(.top, 66)
                        .padding(.bottom, 6)
                    HomeDiscoverySheetView(
                        sheet: .goodsHit(payload),
                        appState: demoAppState,
                        viewerOfferGoods: viewerOfferGoods
                    )
                }
                .background(MegrumTheme.canvas.ignoresSafeArea())
                .allowsHitTesting(false)
            } else {
                MegrumTheme.canvas.ignoresSafeArea()
            }
        }
    }

    // MARK: 指の演技

    private func runChoreo(size: CGSize) async {
        try? await Task.sleep(nanoseconds: 350_000_000)
        switch beat {
        case .openDetail:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.5))
            await pointer.tap()
            pointer.hide()
        case .profile:
            break
        case .exchangeTerms:
            pointer.appear(at: CGPoint(x: size.width * 0.72, y: size.height * 0.30))
            await pointer.tap()
        case .listingDetail:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.38))
            await pointer.tap()
        case .pickFromWanted:
            pointer.appear(at: CGPoint(x: size.width * 0.28, y: size.height * 0.56))
            await pointer.tap()
        case .pickFromMine:
            pointer.appear(at: CGPoint(x: size.width * 0.55, y: size.height * 0.62))
            await pointer.tap()
        case .pickMore:
            pointer.appear(at: CGPoint(x: size.width * 0.78, y: size.height * 0.62))
            await pointer.tap()
        case .confirm:
            break
        case .send:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.84))
            await pointer.tap()
        }
    }
}

/// 第8章 やりとりデモ。実物のやりとり一覧／取引チャットをプレビューデータで描画する。
struct TutorialTradesDemoSceneView: View {
    let beat: TutorialTradesDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    private var sampleProposal: TradeProposal? {
        demoAppState.proposals.first { $0.status == .agreed } ?? demoAppState.proposals.first
    }

    var body: some View {
        switch beat {
        case .overview:
            TradesScreen(
                appState: demoAppState,
                requestedStage: .constant(nil),
                detailRoute: .constant(nil),
                // デモに広告バナーを写り込ませない（プレミアム扱いで抑制）。
                adDisplayContext: AdDisplayContext(isPremiumSubscriber: true)
            )
            .allowsHitTesting(false)

        case .chatFlow:
            if let proposal = sampleProposal {
                NavigationStack {
                    TradeDetailScreen(appState: demoAppState, proposal: proposal)
                }
                .allowsHitTesting(false)
            } else {
                MegrumTheme.canvas.ignoresSafeArea()
            }
        }
    }
}
