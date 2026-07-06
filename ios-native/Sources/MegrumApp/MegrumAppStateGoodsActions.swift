import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    public func loadGoodsTypes() async {
        guard !isLoadingGoodsTypes else {
            return
        }

        isLoadingGoodsTypes = true
        errorMessage = nil
        do {
            goodsTypes = try await repository.loadGoodsTypes(limit: 100)
        } catch {
            errorMessage = "グッズ種別を読み込めませんでした"
        }
        isLoadingGoodsTypes = false
    }

    public func createGoodsEntry(_ input: GoodsEntryInput) async -> Bool {
        await createGoodsEntryRecord(input) != nil
    }

    public func createGoodsEntryRecord(_ input: GoodsEntryInput) async -> GoodsItem? {
        guard !isCreatingGoodsEntry else {
            return nil
        }

        let trimmedTitle = MegrumAppStateInputNormalizer.trimmedText(input.title)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "グッズ名を入力してください"
            return nil
        }
        let normalizedInput = GoodsEntryInput(
            kind: input.kind,
            title: trimmedTitle,
            groupID: input.groupID,
            memberID: input.memberID,
            goodsTypeID: input.goodsTypeID,
            quantity: MegrumAppStateInputNormalizer.goodsQuantity(input.quantity),
            status: input.status,
            tagNames: MegrumAppStateInputNormalizer.tagNames(input.tagNames),
            photoURLs: MegrumAppStateInputNormalizer.photoURLs(input.photoURLs),
            photoUpload: input.photoUpload
        )

        isCreatingGoodsEntry = true
        errorMessage = nil
        do {
            let created = try await repository.createGoodsEntry(normalizedInput)
            upsertGoodsItemLocally(created, kind: normalizedInput.kind)
            isCreatingGoodsEntry = false
            return created
        } catch {
            errorMessage = "グッズを保存できませんでした"
            isCreatingGoodsEntry = false
            return nil
        }
    }

    public func updateGoodsEntry(itemID: UUID, kind: GoodsEntryKind, input: GoodsEntryUpdateInput) async -> Bool {
        guard mutatingGoodsItemID != itemID else {
            return false
        }

        let trimmedTitle = MegrumAppStateInputNormalizer.trimmedText(input.title)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "グッズ名を入力してください"
            return false
        }

        let normalizedInput = GoodsEntryUpdateInput(
            title: trimmedTitle,
            groupID: input.groupID,
            memberID: input.memberID,
            clearsMemberID: input.clearsMemberID,
            goodsTypeID: input.goodsTypeID,
            quantity: MegrumAppStateInputNormalizer.goodsQuantity(input.quantity),
            status: input.status,
            photoURLs: input.photoURLs,
            tagNames: input.tagNames.map(MegrumAppStateInputNormalizer.tagNames),
            photoUpload: input.photoUpload
        )

        mutatingGoodsItemID = itemID
        errorMessage = nil
        do {
            let updated = try await repository.updateGoodsEntry(itemID: itemID, kind: kind, input: normalizedInput)
            upsertGoodsItemLocally(updated, kind: kind)
            mutatingGoodsItemID = nil
            return true
        } catch {
            errorMessage = "グッズを更新できませんでした"
            mutatingGoodsItemID = nil
            return false
        }
    }

    public func suggestGoodsSeriesNamesFromImage(_ input: GoodsSeriesSuggestionInput) async throws -> [String] {
        try await repository.suggestGoodsSeriesNamesFromImage(input)
    }

    public func uploadGoodsGoogleLensSearchPhoto(_ upload: GoodsPhotoUpload) async throws -> URL {
        try await repository.uploadGoodsGoogleLensSearchPhoto(upload)
    }

    public func searchGoods(
        query: String,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil
    ) async {
        await searchGoods(
            query: query,
            groupIDs: groupID.map { [$0] } ?? [],
            memberIDs: memberID.map { [$0] } ?? [],
            goodsTypeIDs: goodsTypeID.map { [$0] } ?? []
        )
    }

    public func searchGoods(
        query: String,
        groupIDs: [UUID],
        memberIDs: [UUID] = [],
        goodsTypeIDs: [UUID] = []
    ) async {
        let requestID = UUID()
        activeSearchRequestID = requestID
        isSearchingGoods = true
        errorMessage = nil
        do {
            await loadBlockedContentUserIDsIfNeeded(reportsFailure: false)
            let items = try await repository.searchGoods(
                GoodsSearchInput(
                    query: query,
                    groupIDs: groupIDs,
                    memberIDs: memberIDs,
                    goodsTypeIDs: goodsTypeIDs
                )
            )
            let results = items.map { item in
                SearchResultItem(
                    item: item,
                    ownerUserID: item.ownerID,
                    bucket: GoodsLocalStateReducer.searchBucket(for: item, wishes: wishes)
                )
            }
            guard activeSearchRequestID == requestID else {
                return
            }
            searchResults = BlockedUserContentFilter.searchResults(
                results,
                blockedUserIDs: blockedContentUserIDs
            )
        } catch {
            if activeSearchRequestID == requestID {
                errorMessage = "検索結果を読み込めませんでした"
            }
        }
        if activeSearchRequestID == requestID {
            activeSearchRequestID = nil
            isSearchingGoods = false
        }
    }

    public func archiveGoodsItem(_ itemID: UUID) async -> Bool {
        guard mutatingGoodsItemID != itemID else {
            return false
        }

        mutatingGoodsItemID = itemID
        errorMessage = nil
        do {
            try await repository.archiveGoodsItem(itemID: itemID)
            removeGoodsItemLocally(itemID)
            mutatingGoodsItemID = nil
            return true
        } catch {
            errorMessage = "グッズを非表示にできませんでした"
            mutatingGoodsItemID = nil
            return false
        }
    }

    public func deleteGoodsItem(_ itemID: UUID) async -> Bool {
        guard mutatingGoodsItemID != itemID else {
            return false
        }

        mutatingGoodsItemID = itemID
        errorMessage = nil
        do {
            try await repository.deleteGoodsItem(itemID: itemID)
            removeGoodsItemLocally(itemID)
            mutatingGoodsItemID = nil
            return true
        } catch {
            errorMessage = "グッズを削除できませんでした"
            mutatingGoodsItemID = nil
            return false
        }
    }

    public func reportGoods(
        itemID: UUID,
        reportedUserID: UUID,
        reason: GoodsReportReason,
        note: String
    ) async -> Bool {
        guard reportingGoodsItemID != itemID else {
            return false
        }
        guard viewer?.id != reportedUserID else {
            errorMessage = "自分のグッズは通報できません"
            return false
        }

        reportingGoodsItemID = itemID
        errorMessage = nil
        do {
            _ = try await repository.reportGoods(
                GoodsReportCreateInput(
                    goodsItemID: itemID,
                    reportedUserID: reportedUserID,
                    reason: reason,
                    note: MegrumAppStateInputNormalizer.optionalText(note)
                )
            )
            reportingGoodsItemID = nil
            return true
        } catch {
            errorMessage = "通報を送信できませんでした"
            reportingGoodsItemID = nil
            return false
        }
    }

    private func removeGoodsItemLocally(_ itemID: UUID) {
        applyGoodsLocalState(
            GoodsLocalStateReducer.removing(
                itemID: itemID,
                from: currentGoodsLocalState
            )
        )
    }

    private func upsertGoodsItemLocally(_ item: GoodsItem, kind: GoodsEntryKind) {
        applyGoodsLocalState(
            GoodsLocalStateReducer.upserting(
                item,
                kind: kind,
                in: currentGoodsLocalState
            )
        )
    }

    var currentGoodsLocalState: GoodsLocalState {
        GoodsLocalState(
            inventory: inventory,
            wishes: wishes,
            homeMatchedItems: homeMatchedItems,
            homePossibleItems: homePossibleItems,
            homeCandidateConditionSignals: homeCandidateConditionSignals,
            searchResults: searchResults,
            listings: listings
        )
    }

    func applyGoodsLocalState(_ state: GoodsLocalState) {
        inventory = state.inventory
        wishes = state.wishes
        homeMatchedItems = state.homeMatchedItems
        homePossibleItems = state.homePossibleItems
        homeCandidateConditionSignals = state.homeCandidateConditionSignals
        searchResults = state.searchResults
        listings = state.listings
    }
}
