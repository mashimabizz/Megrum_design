import Foundation
import MegrumCore

extension MegrumAppState {
    public func loadMailingAddress() async {
        guard !isLoadingMailingAddress else {
            return
        }

        isLoadingMailingAddress = true
        errorMessage = nil
        do {
            mailingAddress = try await repository.loadMailingAddress()
        } catch {
            errorMessage = "住所を読み込めませんでした"
        }
        isLoadingMailingAddress = false
    }

    public func saveMailingAddress(_ address: MailingAddress) async -> Bool {
        guard !isSavingMailingAddress else {
            return false
        }
        guard address.isReady else {
            errorMessage = "宛名・郵便番号・都道府県・市区町村・番地を入力してください"
            return false
        }

        isSavingMailingAddress = true
        errorMessage = nil
        do {
            mailingAddress = try await repository.saveMailingAddress(address)
            isSavingMailingAddress = false
            return true
        } catch {
            errorMessage = "住所を保存できませんでした"
            isSavingMailingAddress = false
            return false
        }
    }

    public func loadPaymentSettings(reportsFailure: Bool = true) async {
        guard !isLoadingPaymentSettings else {
            return
        }

        isLoadingPaymentSettings = true
        if reportsFailure {
            errorMessage = nil
        }
        do {
            paymentSettings = try await repository.loadPaymentSettings()
            hasLoadedPaymentSettings = true
        } catch {
            if reportsFailure {
                errorMessage = "支払い方法を読み込めませんでした"
            }
        }
        isLoadingPaymentSettings = false
    }

    public func savePaymentSettings(_ settings: UserPaymentSettings) async -> Bool {
        guard !isSavingPaymentSettings else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを読み込めませんでした"
            return false
        }

        isSavingPaymentSettings = true
        errorMessage = nil
        do {
            let saved = try await repository.savePaymentSettings(settings.normalized(for: viewer.id))
            self.viewer = saved.profile
            self.paymentSettings = saved.settings
            hasLoadedPaymentSettings = true
            isSavingPaymentSettings = false
            return true
        } catch {
            errorMessage = "支払い方法を保存できませんでした"
            isSavingPaymentSettings = false
            return false
        }
    }

    public func loadExchangeSettings() async {
        guard !isLoadingExchangeSettings else {
            return
        }
        guard let viewer else {
            return
        }

        isLoadingExchangeSettings = true
        errorMessage = nil
        do {
            exchangeSettings = try await repository.loadExchangeSettings(userID: viewer.id)
        } catch {
            errorMessage = "交換条件を読み込めませんでした"
        }
        isLoadingExchangeSettings = false
    }

    public func loadPublicExchangeSettings(userID: UUID, reportsFailure: Bool = false) async {
        await loadBlockedContentUserIDsIfNeeded(reportsFailure: false)
        guard !blockedContentUserIDs.contains(userID) else {
            removeBlockedContent(userID: userID)
            return
        }
        do {
            if let settings = try await repository.loadExchangeSettings(userID: userID) {
                publicExchangeSettingsByUserID[userID] = settings
            }
        } catch {
            if reportsFailure {
                errorMessage = "相手の交換条件を読み込めませんでした"
            }
        }
    }

    public func saveExchangeSettings(_ settings: HomeDefaultExchangeSettings) async -> Bool {
        guard !isSavingExchangeSettings else {
            return false
        }
        guard viewer != nil else {
            errorMessage = "プロフィールを読み込めませんでした"
            return false
        }

        isSavingExchangeSettings = true
        errorMessage = nil
        do {
            let saved = try await repository.saveExchangeSettings(settings)
            exchangeSettings = saved
            isSavingExchangeSettings = false
            return true
        } catch {
            errorMessage = "交換条件を保存できませんでした"
            isSavingExchangeSettings = false
            return false
        }
    }

    public func lookupPostalCode(_ postalCode: String) async -> PostalCodeAddress? {
        let normalizedPostalCode = MegrumAppStateInputNormalizer.postalCode(postalCode)
        guard normalizedPostalCode.count == 7 else {
            return nil
        }
        guard !isLookingUpPostalCode else {
            return nil
        }

        isLookingUpPostalCode = true
        errorMessage = nil
        defer {
            isLookingUpPostalCode = false
        }

        do {
            let address = try await repository.lookupAddress(postalCode: normalizedPostalCode)
            if address == nil {
                errorMessage = "郵便番号に一致する住所が見つかりませんでした"
            }
            return address
        } catch {
            errorMessage = "郵便番号から住所を取得できませんでした"
            return nil
        }
    }

    public func loadBlockedUsers() async {
        guard !isLoadingBlockedUsers else {
            return
        }

        isLoadingBlockedUsers = true
        errorMessage = nil
        do {
            blockedUsers = try await repository.loadBlockedUsers()
            await loadBlockedContentUserIDs(reportsFailure: false)
        } catch {
            errorMessage = "ブロックした人を読み込めませんでした"
        }
        isLoadingBlockedUsers = false
    }

    public func loadBlockedContentUserIDs(reportsFailure: Bool = true) async {
        do {
            blockedContentUserIDs = try await repository.loadBlockedUserIDs()
            hasLoadedBlockedContentUserIDs = true
            removeBlockedContentFromVisibleSurfaces()
        } catch {
            if reportsFailure {
                errorMessage = "ブロック情報を読み込めませんでした"
            }
        }
    }

    func loadBlockedContentUserIDsIfNeeded(reportsFailure: Bool = true) async {
        guard !hasLoadedBlockedContentUserIDs else {
            return
        }
        await loadBlockedContentUserIDs(reportsFailure: reportsFailure)
    }

    public func reportUser(
        targetUserID: UUID,
        reason: UserReportReason,
        note: String
    ) async -> Bool {
        guard reportingUserID != targetUserID else {
            return false
        }
        guard viewer?.id != targetUserID else {
            errorMessage = "自分のプロフィールは通報できません"
            return false
        }

        reportingUserID = targetUserID
        errorMessage = nil
        do {
            _ = try await repository.reportUser(
                UserReportCreateInput(
                    targetUserID: targetUserID,
                    reason: reason,
                    note: MegrumAppStateInputNormalizer.optionalText(note)
                )
            )
            reportingUserID = nil
            return true
        } catch {
            errorMessage = "通報を送信できませんでした"
            reportingUserID = nil
            return false
        }
    }

    public func blockUser(_ userID: UUID) async -> Bool {
        guard blockingUserID != userID else {
            return false
        }
        guard viewer?.id != userID else {
            errorMessage = "自分はブロックできません"
            return false
        }

        blockingUserID = userID
        errorMessage = nil
        do {
            let blockedUser = try await repository.blockUser(userID)
            blockedUsers = BlockedUserStateReducer.upserting(
                blockedUser,
                into: blockedUsers
            )
            blockedContentUserIDs.insert(userID)
            hasLoadedBlockedContentUserIDs = true
            removeBlockedContent(userID: userID)
            blockingUserID = nil
            return true
        } catch {
            errorMessage = "ブロックできませんでした"
            blockingUserID = nil
            return false
        }
    }

    public func unblockUser(_ userID: UUID) async -> Bool {
        guard unblockingUserID == nil else {
            return false
        }

        unblockingUserID = userID
        errorMessage = nil
        do {
            try await repository.unblockUser(userID)
            blockedUsers = BlockedUserStateReducer.removing(
                userID: userID,
                from: blockedUsers
            )
            blockedContentUserIDs.remove(userID)
            await loadBlockedContentUserIDs(reportsFailure: false)
            unblockingUserID = nil
            return true
        } catch {
            errorMessage = "ブロックを解除できませんでした"
            unblockingUserID = nil
            return false
        }
    }

    func removeBlockedContent(userID: UUID) {
        searchResults.removeAll { $0.ownerUserID == userID }
        homeMatchedItems.removeAll { $0.ownerID == userID }
        homePossibleItems.removeAll { $0.ownerID == userID }
        let visibleHomeItemIDs = Set((homeMatchedItems + homePossibleItems).map(\.id))
        homeCandidateConditionSignals = homeCandidateConditionSignals.filter { visibleHomeItemIDs.contains($0.key) }
        homeMutualMatchCandidates = BlockedUserContentFilter.mutualMatchCandidates(
            homeMutualMatchCandidates,
            blockedUserIDs: [userID]
        )
        publicProfilesByUserID.removeValue(forKey: userID)
        publicTradeGoodsByUserID.removeValue(forKey: userID)
        publicListingsByUserID.removeValue(forKey: userID)
        publicExchangeSettingsByUserID.removeValue(forKey: userID)
        userEvaluationsByUserID.removeValue(forKey: userID)
    }

    func removeBlockedContentFromVisibleSurfaces() {
        let blockedUserIDs = blockedContentUserIDs
        searchResults = BlockedUserContentFilter.searchResults(
            searchResults,
            blockedUserIDs: blockedUserIDs
        )
        let filteredSections = BlockedUserContentFilter.homeSections(
            HomeCandidateSections(
                matchedItems: homeMatchedItems,
                possibleItems: homePossibleItems,
                conditionSignalsByItemID: homeCandidateConditionSignals,
                mutualMatchCandidates: homeMutualMatchCandidates
            ),
            blockedUserIDs: blockedUserIDs
        )
        homeMatchedItems = filteredSections.matchedItems
        homePossibleItems = filteredSections.possibleItems
        homeCandidateConditionSignals = filteredSections.conditionSignalsByItemID
        homeMutualMatchCandidates = filteredSections.mutualMatchCandidates
        for userID in blockedUserIDs {
            publicProfilesByUserID.removeValue(forKey: userID)
            publicTradeGoodsByUserID.removeValue(forKey: userID)
            publicListingsByUserID.removeValue(forKey: userID)
            publicExchangeSettingsByUserID.removeValue(forKey: userID)
            userEvaluationsByUserID.removeValue(forKey: userID)
        }
    }
}
