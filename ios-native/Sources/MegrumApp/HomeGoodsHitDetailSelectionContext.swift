import Foundation
import MegrumCore

struct HomeGoodsHitDetailSelectionContext {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var selectionState: HomeListingSheetSelectionState
    var focusedWantedOptionID: UUID?

    var wantedGoods: [HomeMockGoods] {
        HomeDiscoveryFixtures.wantedGoods
    }

    var wantedOptions: [HomeIndividualListingWantedOption] {
        if let focusedWantedOption {
            return [focusedWantedOption]
        }
        return prioritizedWantedOptions(selectableWantedOptions)
    }

    var receiveGoods: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.receiveGoods(selection: selection)
    }

    var usesListingWantedOptions: Bool {
        !availableWantedOptions.isEmpty
    }

    var showsWantedOptionPicker: Bool {
        availableWantedOptions.count > 1
    }

    var selectedWantedOptionID: UUID? {
        selectedWantedOptions.first?.id ?? focusedWantedOptionID ?? wantedOptions.first?.id
    }

    var wantedOptionPreviewGoods: [HomeMockGoods] {
        HomeGoodsHitWantedOptionSeriesResolver.orderedPreviewGoods(
            for: displayedWantedOption,
            usesListingWantedOptions: usesListingWantedOptions,
            previewGoodsPool: wantedOptionPreviewGoodsPool,
            allOfferGoods: allOfferGoods
        )
    }

    var wantedOptionPreviewBadgeTextByGoodsID: [UUID: String] {
        HomeGoodsHitWantedOptionSeriesResolver.badgeTextByGoodsID(
            option: displayedWantedOption,
            previewGoods: wantedOptionPreviewGoods,
            allOfferGoods: allOfferGoods
        )
    }

    var selectedWantedOptionPreviewIndices: Set<Int> {
        guard usesListingWantedOptions,
              displayedWantedOption != nil,
              !selectionState.selectedWantedIndices.isEmpty
        else {
            return []
        }
        return Set(wantedOptionPreviewGoods.indices)
    }

    var displayedWantedOptionIndex: Int? {
        guard let option = displayedWantedOption else {
            return nil
        }
        return wantedOptions.firstIndex { $0.id == option.id }
    }

    /// 相手の個別募集の求めるものが1件だけのとき、選ぶカードではなく1行の文脈で見せる。iter1226.372。
    /// 2件以上のときは nil（従来どおり選択カード＋「他の選択肢」）。
    var singleWantedOptionSummary: HomeWantedSingleOptionSummary? {
        guard usesListingWantedOptions,
              !showsWantedOptionPicker,
              let option = displayedWantedOption
        else {
            return nil
        }
        switch option.kind {
        case .cash:
            return HomeWantedSingleOptionSummary(
                kind: .cash,
                text: TradeAmountFormatter.fixedPrice(amount: option.cashAmount),
                imageURL: nil,
                isTentative: false
            )
        case .condition:
            return HomeWantedSingleOptionSummary(
                kind: .condition,
                text: option.conditionSummary?.nilIfBlank ?? option.title,
                imageURL: nil,
                isTentative: !option.tentativeGoodsIDs.isEmpty
            )
        case .goods:
            return HomeWantedSingleOptionSummary(
                kind: .goods,
                text: option.title,
                imageURL: option.previewItems.first?.imageURL,
                isTentative: !option.tentativeGoodsIDs.isEmpty
            )
        }
    }

    /// 表示中の相手希望が「条件指定」ならマッチ済みグッズ列ではなく条件カードを1枚出す。iter1226.371。
    var displayedWantedConditionCard: HomeWantedConditionCardModel? {
        guard usesListingWantedOptions,
              let option = displayedWantedOption,
              option.kind == .condition
        else {
            return nil
        }
        return HomeWantedConditionCardModel(
            tokens: HomeWantedConditionCardModel.tokens(from: option),
            isTentative: !option.tentativeGoodsIDs.isEmpty,
            isSelected: !selectionState.selectedWantedIndices.isEmpty
        )
    }

    var allOfferGoods: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.allOfferGoods(
            viewerOfferGoods: viewerOfferGoods,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
    }

    var offerGoods: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.offerGoods(
            usesListingWantedOptions: usesListingWantedOptions,
            allOfferGoods: allOfferGoods,
            selectedWantedOptions: selectedWantedOptions
        )
    }

    var wantedLogic: ListingLogic {
        selection.individualListingSelection.wantedLogic
    }

    var wantedMinimumCount: Int {
        selection.individualListingSelection.wantedMinimumCount
    }

    var receiveLogic: ListingLogic {
        selection.individualListingSelection.detail?.offeredLogic ?? selection.individualListingSelection.offeredLogic
    }

    var receiveMinimumCount: Int {
        selection.individualListingSelection.detail?.offeredMinimumCount ?? selection.individualListingSelection.offeredMinimumCount
    }

    var showsReceiveSelection: Bool {
        receiveLogic == .atLeast && receiveGoods.count > 1
    }

    var wantedItemCount: Int {
        usesListingWantedOptions ? wantedOptions.count : wantedGoods.count
    }

    var receiveItemCount: Int {
        receiveGoods.count
    }

    var selectedWantedOptions: [HomeIndividualListingWantedOption] {
        guard usesListingWantedOptions else {
            return []
        }
        return selectionState.selectedWantedIndices
            .sorted()
            .compactMap { wantedOptions.indices.contains($0) ? wantedOptions[$0] : nil }
    }

    var selectedCashOption: HomeIndividualListingWantedOption? {
        selectedWantedOptions.first { $0.isCashOffer }
    }

    var selectedReceiveGoods: [HomeMockGoods] {
        selectionState.selectedReceiveIndices
            .sorted()
            .compactMap { receiveGoods.indices.contains($0) ? receiveGoods[$0] : nil }
    }

    var cashAmountValue: Int? {
        TradeAmountFormatter.cashInputValue(from: selectionState.cashAmountText)
    }

    var wantedRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: wantedLogic, minimumCount: wantedMinimumCount)
    }

    var receiveRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: receiveLogic, minimumCount: receiveMinimumCount)
    }

    var offerLogic: ListingLogic {
        guard selectedWantedOptions.count == 1, let option = selectedWantedOptions.first else {
            return wantedLogic
        }
        return option.logic
    }

    var offerMinimumCount: Int {
        guard selectedWantedOptions.count == 1, let option = selectedWantedOptions.first else {
            return wantedMinimumCount
        }
        return option.minimumCount
    }

    var offerRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: offerLogic, minimumCount: offerMinimumCount)
    }

    var canStartProposal: Bool {
        guard receiveSelectionIsSatisfied, wantedSelectionIsSatisfied else {
            return false
        }
        if selectedCashOption != nil {
            return cashAmountValue != nil
        }
        return offerSelectionIsSatisfied
    }

    var previewGoodsByWantedOptionID: [UUID: HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.previewGoodsByOptionID(
            options: wantedOptions,
            goodsPool: wantedOptionPreviewGoodsPool
        )
    }

    var preferredOfferIndex: Int? {
        guard let preferredOfferGoodsID = selection.preferredOfferGoodsID else {
            return nil
        }
        return offerGoods.firstIndex { $0.id == preferredOfferGoodsID }
    }

    var initialReceiveIndices: Set<Int> {
        guard !showsReceiveSelection else {
            return []
        }
        switch receiveLogic {
        case .all:
            return Set(receiveGoods.indices)
        case .one:
            return preferredReceiveIndex.map { [$0] } ?? [0]
        case .atLeast:
            if receiveGoods.count <= receiveMinimumCount {
                return Set(receiveGoods.indices)
            }
            return []
        }
    }

    private var receiveSelectionIsSatisfied: Bool {
        HomeListingSelectionPolicy.isSatisfied(
            selectedCount: selectedReceiveGoods.count,
            itemCount: receiveItemCount,
            logic: receiveLogic,
            minimumCount: receiveMinimumCount
        )
    }

    private var wantedSelectionIsSatisfied: Bool {
        HomeListingSelectionPolicy.isSatisfied(
            selectedCount: selectionState.selectedWantedIndices.count,
            itemCount: wantedItemCount,
            logic: wantedLogic,
            minimumCount: wantedMinimumCount
        )
    }

    /// 相手の選択肢が要求する譲るグッズの数（手持ち数でクランプしない）。
    var offerRequiredCount: Int {
        HomeListingSelectionPolicy.requiredOfferCount(
            logic: offerLogic,
            designatedCount: offerDesignatedCount,
            minimumCount: offerMinimumCount
        )
    }

    private var offerDesignatedCount: Int {
        if selectedWantedOptions.count == 1, let option = selectedWantedOptions.first {
            return option.goodsIDs.isEmpty ? offerGoods.count : option.goodsIDs.count
        }
        return wantedGoods.count
    }

    private var offerSelectionIsSatisfied: Bool {
        guard offerGoods.count >= offerRequiredCount else {
            // 条件（グループ・メンバー・種別・シリーズ）に合う手持ちが
            // 必要数に満たない場合は打診不可。
            return false
        }
        return selectionState.selectedOfferIndices.count >= offerRequiredCount
    }

    func proposalSelection() -> HomeDiscoveryProposalSelection? {
        HomeGoodsHitProposalSelectionBuilder.proposalSelection(
            selection: selection,
            selectedReceiveGoods: selectedReceiveGoods,
            selectedOfferIndices: selectionState.selectedOfferIndices,
            offerGoods: offerGoods,
            cashAmountValue: cashAmountValue
        )
    }

    private var wantedOptionPreviewGoodsPool: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.wantedOptionPreviewGoodsPool(
            allOfferGoods: allOfferGoods,
            wantedGoods: wantedGoods,
            selectedGoods: selection.goods
        )
    }

    private var preferredReceiveIndex: Int? {
        receiveGoods.firstIndex { $0.id == selection.goods.id }
    }

    private var selectableWantedOptions: [HomeIndividualListingWantedOption] {
        selection.individualListingSelection.wantedOptions
    }

    private var availableWantedOptions: [HomeIndividualListingWantedOption] {
        let detailOptions = selection.individualListingSelection.detail?.wantedOptions ?? []
        return detailOptions.isEmpty ? selectableWantedOptions : detailOptions
    }

    private var focusedWantedOption: HomeIndividualListingWantedOption? {
        guard let focusedWantedOptionID else {
            return nil
        }
        return availableWantedOptions.first { $0.id == focusedWantedOptionID }
    }

    private var displayedWantedOption: HomeIndividualListingWantedOption? {
        selectedWantedOptions.first ?? focusedWantedOption ?? wantedOptions.first
    }

    private func prioritizedWantedOptions(_ options: [HomeIndividualListingWantedOption]) -> [HomeIndividualListingWantedOption] {
        HomeGoodsHitWantedOptionSeriesResolver.prioritizedWantedOptions(
            options,
            usesListingWantedOptions: usesListingWantedOptions,
            previewGoodsPool: wantedOptionPreviewGoodsPool,
            allOfferGoods: allOfferGoods
        )
    }
}

// MARK: - 取引ブロック（3列）モデル（notes/19 候補シート再設計）

extension HomeGoodsHitDetailSelectionContext {
    /// 選択肢ピルに並べる相手希望オプション（優先順ソート済み・全件）。notes/19 の常時表示ピル用。iter1226.374。
    var pillWantedOptions: [HomeIndividualListingWantedOption] {
        prioritizedWantedOptions(availableWantedOptions)
    }

    /// 選択肢ピルで選ばれた ID からオプションを引く。
    func wantedOption(withID id: UUID) -> HomeIndividualListingWantedOption? {
        availableWantedOptions.first { $0.id == id }
    }

    /// 取引ブロック（受け取る｜相手希望｜譲る）の描画モデル。
    /// 現金選択時・個別募集の選択肢が無い時は nil（それぞれ金額入力／旧フォールバックへ）。iter1226.374。
    func dealBlockModel() -> HomeDealBlockModel? {
        guard usesListingWantedOptions,
              let option = displayedWantedOption,
              option.kind != .cash
        else {
            return nil
        }
        return HomeDealBlockModel(
            receive: receiveColumnModel(),
            partner: partnerColumnModel(option: option),
            offer: offerColumnModel(option: option),
            achievement: achievementModel(option: option)
        )
    }

    private func receiveColumnModel() -> HomeDealReceiveColumn {
        let all = receiveGoods
        let qty = all.count > 1 ? receiveRequirementLabel : nil
        if showsReceiveSelection {
            let cells = all.enumerated().map { index, goods in
                HomeDealGoodsCell(
                    id: goods.id,
                    index: index,
                    imageURL: goods.imageURL,
                    title: goods.title,
                    selected: selectionState.selectedReceiveIndices.contains(index),
                    selectable: true,
                    tentative: false
                )
            }
            return HomeDealReceiveColumn(qtyLabel: qty, selectable: true, cells: cells)
        }
        // 自動確定：受け取り確定分（未確定なら全件）を固定表示。
        let selected = selectionState.selectedReceiveIndices
        let cells = all.enumerated()
            .filter { selected.isEmpty || selected.contains($0.offset) }
            .map { index, goods in
                HomeDealGoodsCell(
                    id: goods.id,
                    index: index,
                    imageURL: goods.imageURL,
                    title: goods.title,
                    selected: true,
                    selectable: false,
                    tentative: false
                )
            }
        return HomeDealReceiveColumn(qtyLabel: cells.count > 1 ? qty : nil, selectable: false, cells: cells)
    }

    private func partnerColumnModel(option: HomeIndividualListingWantedOption) -> HomeDealPartnerColumn {
        switch option.kind {
        case .goods:
            let named = option.namedPairings.map { pairing in
                HomeDealWishCell(id: pairing.id, imageURL: pairing.imageURL, title: pairing.title)
            }
            // namedPairings が空（相手ほしいもの行が取れない）ときはプレビュー画像で代替。
            let items = named.isEmpty
                ? option.previewItems.map { HomeDealWishCell(id: $0.id, imageURL: $0.imageURL, title: $0.title) }
                : named
            return HomeDealPartnerColumn(kind: .goods, namedItems: items, conditionTile: nil)
        case .condition:
            let tile = HomeDealConditionTile(
                tokens: HomeWantedConditionCardModel.tokens(from: option),
                tentative: !option.tentativeGoodsIDs.isEmpty,
                selected: !selectionState.selectedWantedIndices.isEmpty,
                wantedOptionIndex: displayedWantedOptionIndex
            )
            return HomeDealPartnerColumn(kind: .condition, namedItems: [], conditionTile: tile)
        case .cash:
            return HomeDealPartnerColumn(kind: .cash, namedItems: [], conditionTile: nil)
        }
    }

    private func offerColumnModel(option: HomeIndividualListingWantedOption) -> HomeDealOfferColumn {
        let goods = offerGoods
        let indexByID = Dictionary(goods.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
        let tentative = Set(option.tentativeGoodsIDs)
        let qty = (offerRequiredCount > 1 || goods.count > 1) ? offerRequirementLabel : nil

        func cell(_ index: Int) -> HomeDealGoodsCell {
            let item = goods[index]
            return HomeDealGoodsCell(
                id: item.id,
                index: index,
                imageURL: item.imageURL,
                title: item.title,
                selected: selectionState.selectedOfferIndices.contains(index),
                selectable: true,
                tentative: tentative.contains(item.id)
            )
        }

        if option.kind == .goods, !option.namedPairings.isEmpty {
            let rows = option.namedPairings.map { pairing -> HomeDealOfferRow in
                let indices = pairing.candidateGoodsIDs.compactMap { indexByID[$0] }.sorted()
                return HomeDealOfferRow(id: pairing.id, cells: indices.map(cell))
            }
            return HomeDealOfferColumn(qtyLabel: qty, isNamed: true, rows: rows)
        }
        return HomeDealOfferColumn(
            qtyLabel: qty,
            isNamed: false,
            rows: [HomeDealOfferRow(id: option.id, cells: goods.indices.map(cell))]
        )
    }

    /// 選択中の譲るグッズ。
    var selectedOfferGoods: [HomeMockGoods] {
        selectionState.selectedOfferIndices
            .sorted()
            .compactMap { offerGoods.indices.contains($0) ? offerGoods[$0] : nil }
    }

    /// 条件パターンの「条件のグッズを確認！」モデル。表示中が条件指定のときのみ。iter1226.375。
    func conditionSeriesCheckModel() -> HomeConditionSeriesCheckModel? {
        guard usesListingWantedOptions,
              let option = displayedWantedOption,
              option.kind == .condition
        else {
            return nil
        }
        // 参考画像は「自分の手持ちではない」プレビュー（＝シリーズの参考画像）に限る。
        // 実データの条件プレビューはマッチした自分グッズなので除外され、②検索フォールバックになる。
        let ownIDs = Set(allOfferGoods.map(\.id))
        let referenceImages = Array(
            option.previewItems
                .filter { !ownIDs.contains($0.id) }
                .compactMap(\.imageURL)
                .prefix(2)
        )
        let query = conditionSearchQuery(option: option)
        let searchURL = query.isEmpty
            ? nil
            : URL(string: "https://www.google.com/search?tbm=isch&q=" +
                (query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""))
        return HomeConditionSeriesCheckModel(
            referenceImageURLs: referenceImages,
            searchQuery: query,
            searchURL: searchURL
        )
    }

    /// 「グループ メンバー #シリーズ」の画像検索クエリ。メンバーは選択中の自分グッズ優先。
    private func conditionSearchQuery(option: HomeIndividualListingWantedOption) -> String {
        let summaryParts = (option.conditionSummary ?? "")
            .components(separatedBy: " / ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let seriesTokens = summaryParts.filter { $0.hasPrefix("#") }
        let firstOffer = selectedOfferGoods.first ?? offerGoods.first
        let group = firstOffer?.groupName?.nilIfBlank
            ?? summaryParts.first { !$0.hasPrefix("#") }
        let member = firstOffer?.memberName?.nilIfBlank
        var tokens: [String] = []
        if let group { tokens.append(group) }
        if let member { tokens.append(member) }
        tokens.append(contentsOf: seriesTokens)
        return tokens.joined(separator: " ")
    }

    private func achievementModel(option: HomeIndividualListingWantedOption) -> HomeDealAchievement? {
        let required = offerRequiredCount
        guard required > 1 else {
            return nil
        }
        let goods = offerGoods
        guard goods.count >= required else {
            return HomeDealAchievement(text: "条件に合う手持ちが \(goods.count)/\(required) 点", satisfied: false)
        }
        let selectedCount = selectionState.selectedOfferIndices.count
        let satisfied = selectedCount >= required
        let prefix: String
        switch offerLogic {
        case .all:
            prefix = "すべて"
        case .atLeast:
            prefix = "\(required)個以上"
        case .one:
            prefix = ""
        }
        let base = "\(prefix)：\(min(selectedCount, required))/\(required) 選択済み"
        let suffix = satisfied ? "・成立OK" : "・あと\(max(0, required - selectedCount))つで成立"
        return HomeDealAchievement(text: base + suffix, satisfied: satisfied)
    }
}
