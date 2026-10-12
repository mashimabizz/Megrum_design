import MegrumCore
import MegrumDesign
import SwiftUI

/// 第7章 打診デモ（激求の例）。実物の候補詳細シート・相手プロフィール・打診プレビューを
/// プレビューデータで描画し、指アイコンの実演を重ねる。
/// 下部セクションを見せるビートはシート全体を上へオフセットして「スクロール後」の状態を再現する。
struct TutorialProposalDemoSceneView: View {
    let beat: TutorialProposalDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    @StateObject private var pointer = TutorialPointerChoreographer()

    /// 激求ヒット（PreviewMegrumRepository が個別募集ヒットを付けている相手グッズ）。
    private var targetItem: GoodsItem? {
        let partnerItems = demoAppState.homeMatchedItems.filter { $0.ownerID != demoAppState.viewer?.id }
        let base = partnerItems.first { demoAppState.homeCandidateConditionSignals[$0.id]?.individualListingSelection != nil }
            ?? partnerItems.first
        guard var item = base else { return nil }
        // シート上部のオーナー表示を実プロフィール（michi）と一致させる
        //（fixtureにオーナー情報が無いと「ユーザー/評価なし」になり、7-4のプロフィールと食い違う）。
        let partner = NativePreviewData.partner
        item.ownerDisplayName = partner.displayName
        item.ownerHandle = partner.handle
        item.ownerGender = partner.gender
        item.ownerAge = partner.age
        item.ownerPrefecture = partner.prefecture
        item.ownerAverageStars = 4.5
        item.ownerEvaluationCount = 2
        return item
    }

    private var sheetPayload: HomeDiscoverySheetPayload? {
        guard let item = targetItem else { return nil }
        let goods = HomeMockGoods.from(item: item, index: 0, goodsTypes: demoAppState.goodsTypes)
        var signals = demoAppState.homeCandidateConditionSignals[item.id]
            ?? HomeCandidateConditionSignalDefaults.previewSignals(matchedItems: [item], possibleItems: [])[item.id]
        // 「相手の希望」の指名先をデモ在庫の実アイテムに揃える。これが一致しないと
        // 「譲るグッズを選ぶ」が空になり、確認ボタンが非活性のままになる（7-9〜7-11）。
        if var selection = signals?.individualListingSelection,
           var option = selection.wantedOptions.first,
           let mine = viewerOfferGoods.first {
            option.goodsIDs = [mine.id]
            option.matchingGoodsIDs = [mine.id]
            selection.wantedOptions[0] = option
            signals?.individualListingSelection = selection
        }
        guard let signals else { return nil }
        return HomeDiscoverySheetPayload(goods: goods, signals: signals)
    }

    /// 各ビートの「実際の選択状態」（受け取り2点は7-7で選択→以降保持、希望からの譲るは7-8で選択→以降保持）。
    private var scriptedSelectionState: HomeListingSheetSelectionState? {
        switch beat {
        case .receivePick, .pickFromWanted:
            return HomeListingSheetSelectionState(selectedReceiveIndices: [0, 1])
        case .pickFromMine, .pickMore, .confirmTap:
            // 譲るグッズまで選択済みにして「交換内容を確認する」が活性の実状態を見せる。
            return HomeListingSheetSelectionState(
                selectedWantedIndices: [0],
                selectedOfferIndices: [0],
                selectedReceiveIndices: [0, 1]
            )
        default:
            return nil
        }
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

    /// 下部セクションを見せるビートのシート持ち上げ量。
    /// 「交換内容を確認する」はシート下部に固定表示されるため confirmTap では持ち上げない。
    private func sheetLift(for size: CGSize) -> CGFloat {
        switch beat {
        case .pickMore:
            return size.height * 0.22
        default:
            return 0
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                stage(size: proxy.size)
                TutorialPointerLayer(choreo: pointer)
            }
            .task(id: beat) {
                await runChoreo(size: proxy.size)
            }
        }
    }

    // MARK: シーン本体

    @ViewBuilder
    private func stage(size: CGSize) -> some View {
        switch beat {
        case .profile:
            NavigationStack {
                PublicUserProfileScreen(
                    appState: demoAppState,
                    userID: targetItem?.ownerID ?? NativePreviewData.partnerID,
                    presentationContext: .standalone
                )
            }
            .allowsHitTesting(false)

        case .preview:
            if let item = targetItem {
                NavigationStack {
                    ProposalCreateFlow(
                        appState: demoAppState,
                        targetItem: item,
                        receiverGoodsIDs: [item.id],
                        initialSenderGoodsIDs: demoAppState.inventory.first.map { [$0.id] } ?? [],
                        initialStep: .confirm
                    )
                }
                .allowsHitTesting(false)
            } else {
                MegrumTheme.canvas.ignoresSafeArea()
            }

        default:
            // 候補詳細シート（激求ヒット）。下部ビートは「画面高＋lift」の背高フレームで描画してから
            // 上へオフセット（単純なoffsetではScrollViewの初期ビューポート外が描画されないため）。
            if let payload = sheetPayload {
                let lift = sheetLift(for: size)
                VStack(spacing: 0) {
                    Capsule()
                        .fill(MegrumTheme.ink.opacity(0.16))
                        .frame(width: 44, height: 5)
                        .padding(.top, 66)
                        .padding(.bottom, 6)
                    HomeDiscoverySheetView(
                        sheet: .goodsHit(payload),
                        appState: demoAppState,
                        viewerOfferGoods: viewerOfferGoods,
                        initialGoodsHitSelectionState: scriptedSelectionState
                    )
                }
                .frame(width: size.width, height: size.height + lift)
                .background(MegrumTheme.canvas.ignoresSafeArea())
                .offset(y: -lift)
                .frame(width: size.width, height: size.height, alignment: .top)
                .clipped()
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
        case .openDetail, .profile:
            break
        case .profileTap:
            pointer.appear(at: CGPoint(x: size.width * 0.24, y: size.height * 0.115))
            await pointer.tap()
        case .exchangeTerms:
            pointer.appear(at: CGPoint(x: size.width * 0.60, y: size.height * 0.175))
            await pointer.tap()
        case .listingDetail:
            pointer.appear(at: CGPoint(x: size.width * 0.68, y: size.height * 0.325))
            await pointer.tap()
        case .receivePick:
            pointer.appear(at: CGPoint(x: size.width * 0.12, y: size.height * 0.478))
            await pointer.tap()
            await pointer.move(to: CGPoint(x: size.width * 0.342, y: size.height * 0.478), duration: 0.35)
            await pointer.tap()
        case .pickFromWanted:
            pointer.appear(at: CGPoint(x: size.width * 0.13, y: size.height * 0.685))
            await pointer.tap()
        case .pickFromMine:
            pointer.appear(at: CGPoint(x: size.width * 0.80, y: size.height * 0.60))
            await pointer.tap()
        case .pickMore:
            // 候補が無い時は空パネルの説明だけ（タップ演技なし）。
            break
        case .confirmTap:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.93))
            await pointer.tap()
        case .preview:
            pointer.appear(at: CGPoint(x: size.width * 0.5, y: size.height * 0.915))
            await pointer.tap()
        }
    }
}

/// 第8章 やりとりデモ。取引チャット（実物）をプレビューデータで描画する。
struct TutorialTradesDemoSceneView: View {
    let beat: TutorialTradesDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    private var sampleProposal: TradeProposal? {
        demoAppState.proposals.first { $0.status == .agreed } ?? demoAppState.proposals.first
    }

    var body: some View {
        switch beat {
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

/// 第9章 めぐりのプレビューデモ（グルームビューア／チャットルーム紹介画面）。
struct TutorialMeguriDemoSceneView: View {
    let beat: TutorialMeguriDemoBeat
    @ObservedObject var demoAppState: MegrumAppState

    var body: some View {
        switch beat {
        case .groomPreview:
            if let groom = TutorialSampleMeguriData.grooms.first {
                GroomViewerScreen(
                    grooms: TutorialSampleMeguriData.grooms,
                    initialGroom: groom,
                    appState: demoAppState,
                    onDismiss: {},
                    onOpenMeguriUserProfile: { _ in }
                )
                .allowsHitTesting(false)
            } else {
                MegrumTheme.canvas.ignoresSafeArea()
            }

        case .boardPreview:
            if let thread = TutorialSampleMeguriData.threads.first {
                NavigationStack {
                    BoardThreadDetailScreen(
                        appState: demoAppState,
                        thread: thread,
                        selectedPrefecture: nil,
                        // 現在地ありの通常状態で見せる（nilだと「返信には現在地が必要です」の注意が出て
                        // ヘッダーと重なってしまう。実利用ではピンから入る時点で現在地がある）。
                        coordinate: TutorialSampleMeguriData.centerCoordinate,
                        onClose: {}
                    )
                }
                .allowsHitTesting(false)
            } else {
                MegrumTheme.canvas.ignoresSafeArea()
            }
        }
    }
}
