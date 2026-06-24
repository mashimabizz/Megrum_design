import Foundation
import MegrumCore

extension MegrumAppState {
    @discardableResult
    public func loadHomeLocalModeSettings(
        fallback: HomeLocalActivitySettings? = nil,
        now: Date = .now
    ) async -> HomeLocalActivitySettings? {
        guard !isLoadingHomeLocalModeSettings else {
            return homeLocalModeSettings ?? fallback
        }

        isLoadingHomeLocalModeSettings = true
        errorMessage = nil
        defer {
            isLoadingHomeLocalModeSettings = false
        }

        do {
            if let loaded = try await repository.loadHomeLocalModeSettings(now: now) {
                let normalized = loaded.normalizedForPersistence(now: now)
                homeLocalModeSettings = normalized
                return normalized
            }
            if homeLocalModeSettings == nil {
                homeLocalModeSettings = fallback?.normalizedForPersistence(now: now)
            }
            return homeLocalModeSettings ?? fallback
        } catch {
            if homeLocalModeSettings == nil {
                homeLocalModeSettings = fallback?.normalizedForPersistence(now: now)
            }
            errorMessage = "現地交換モードを読み込めませんでした"
            return homeLocalModeSettings ?? fallback
        }
    }

    @discardableResult
    public func saveHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date = .now
    ) async -> HomeLocalActivitySettings? {
        guard !isSavingHomeLocalModeSettings else {
            return nil
        }

        let previous = homeLocalModeSettings
        let prepared = settings.normalizedForPersistence(
            now: now,
            fallbackActivityWindowID: previous?.activityWindowID
        )
        guard !prepared.isEnabled || !prepared.normalizedVenue.isEmpty else {
            errorMessage = "場所を入力してください"
            return nil
        }

        homeLocalModeSettings = prepared
        isSavingHomeLocalModeSettings = true
        errorMessage = nil
        do {
            let saved = try await repository.saveHomeLocalModeSettings(prepared, now: now)
            let normalized = saved.normalizedForPersistence(now: now, fallbackActivityWindowID: prepared.activityWindowID)
            homeLocalModeSettings = normalized
            isSavingHomeLocalModeSettings = false
            return normalized
        } catch {
            homeLocalModeSettings = previous
            errorMessage = "現地交換モードを保存できませんでした"
            isSavingHomeLocalModeSettings = false
            return nil
        }
    }

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

    public func loadPaymentSettings() async {
        guard !isLoadingPaymentSettings else {
            return
        }

        isLoadingPaymentSettings = true
        errorMessage = nil
        do {
            paymentSettings = try await repository.loadPaymentSettings()
        } catch {
            errorMessage = "支払い条件を読み込めませんでした"
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
            isSavingPaymentSettings = false
            return true
        } catch {
            errorMessage = "支払い条件を保存できませんでした"
            isSavingPaymentSettings = false
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
        } catch {
            errorMessage = "ブロックした人を読み込めませんでした"
        }
        isLoadingBlockedUsers = false
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
            unblockingUserID = nil
            return true
        } catch {
            errorMessage = "ブロックを解除できませんでした"
            unblockingUserID = nil
            return false
        }
    }

    public func loadNotifications() async {
        guard !isLoadingNotifications else {
            return
        }

        isLoadingNotifications = true
        errorMessage = nil
        do {
            notifications = try await repository.loadNotifications(limit: 100)
        } catch {
            errorMessage = "通知を読み込めませんでした"
        }
        isLoadingNotifications = false
    }

    public func markNotificationRead(_ notificationID: UUID) async {
        guard NotificationReadStateReducer.containsUnread(notifications, id: notificationID) else {
            return
        }

        let readAt = Date()
        notifications = NotificationReadStateReducer.markRead(
            notifications,
            id: notificationID,
            readAt: readAt
        )
        do {
            if let updated = try await repository.markNotificationRead(notificationID) {
                notifications = NotificationReadStateReducer.mergingUpdated(
                    notifications,
                    updated: [updated]
                )
            }
        } catch {
            notifications = NotificationReadStateReducer.markUnread(notifications, id: notificationID)
            errorMessage = "通知を既読にできませんでした"
        }
    }

    public func markAllNotificationsRead() async {
        guard !isMarkingNotificationsRead else {
            return
        }
        guard unreadNotificationCount > 0 else {
            return
        }

        isMarkingNotificationsRead = true
        errorMessage = nil
        let previous = notifications
        let readAt = Date()
        notifications = NotificationReadStateReducer.markAllRead(notifications, readAt: readAt)
        do {
            let updated = try await repository.markAllNotificationsRead()
            notifications = NotificationReadStateReducer.mergingUpdated(
                notifications,
                updated: updated
            )
        } catch {
            notifications = previous
            errorMessage = "通知を既読にできませんでした"
        }
        isMarkingNotificationsRead = false
    }

    public func loadPushNotificationSetting() async {
        guard !isLoadingPushNotificationSetting else {
            return
        }

        isLoadingPushNotificationSetting = true
        errorMessage = nil
        do {
            pushNotificationsEnabled = try await repository.loadPushNotificationsEnabled()
        } catch {
            errorMessage = "モバイル通知設定を読み込めませんでした"
        }
        isLoadingPushNotificationSetting = false
    }

    @discardableResult
    public func setPushNotificationsEnabled(_ enabled: Bool) async -> Bool {
        guard !isSavingPushNotificationSetting else {
            return false
        }

        let previous = pushNotificationsEnabled
        pushNotificationsEnabled = enabled
        isSavingPushNotificationSetting = true
        errorMessage = nil
        do {
            pushNotificationsEnabled = try await repository.setPushNotificationsEnabled(enabled)
            isSavingPushNotificationSetting = false
            return true
        } catch {
            pushNotificationsEnabled = previous
            errorMessage = "モバイル通知設定を保存できませんでした"
            isSavingPushNotificationSetting = false
            return false
        }
    }

    @discardableResult
    public func registerNativePushDeviceToken(_ token: String, appVersion: String? = nil) async -> Bool {
        let trimmedToken = MegrumAppStateInputNormalizer.trimmedText(token)
        guard !trimmedToken.isEmpty else {
            return false
        }
        guard !isRegisteringNativePushDevice else {
            return false
        }

        isRegisteringNativePushDevice = true
        errorMessage = nil
        do {
            try await repository.registerNativePushDeviceToken(trimmedToken, appVersion: appVersion)
            registeredNativePushDeviceToken = trimmedToken
            isRegisteringNativePushDevice = false
            return true
        } catch {
            errorMessage = "モバイル通知の端末登録に失敗しました"
            isRegisteringNativePushDevice = false
            return false
        }
    }

    @discardableResult
    public func revokeRegisteredNativePushDeviceToken(revokedAt: Date = .now) async -> Bool {
        guard let registeredNativePushDeviceToken, !registeredNativePushDeviceToken.isEmpty else {
            return false
        }
        guard !isRevokingNativePushDevice else {
            return false
        }

        isRevokingNativePushDevice = true
        errorMessage = nil
        do {
            try await repository.revokeNativePushDeviceToken(
                registeredNativePushDeviceToken,
                revokedAt: revokedAt
            )
            self.registeredNativePushDeviceToken = nil
            isRevokingNativePushDevice = false
            return true
        } catch {
            errorMessage = "モバイル通知の端末登録を解除できませんでした"
            isRevokingNativePushDevice = false
            return false
        }
    }

    public func completeAccountSetup(
        displayName: String,
        prefecture: String?,
        oshiSelections: [AccountSetupOshiInput] = []
    ) async -> Bool {
        guard !isSavingAccountSetup else {
            return false
        }
        let trimmedDisplayName = MegrumAppStateInputNormalizer.trimmedText(displayName)
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "表示名を入力してください"
            return false
        }
        guard !oshiSelections.isEmpty else {
            errorMessage = "推しを選択してください"
            return false
        }

        isSavingAccountSetup = true
        errorMessage = nil

        do {
            let savedViewer = try await repository.completeAccountSetup(
                AccountSetupInput(
                    displayName: trimmedDisplayName,
                    prefecture: MegrumAppStateInputNormalizer.prefecture(prefecture),
                    oshiSelections: oshiSelections
                )
            )
            viewer = savedViewer
            userOshiSelections = UserOshiSelectionPersistenceMapper.selections(
                from: oshiSelections,
                userID: savedViewer.id
            )
            isSavingAccountSetup = false
            return true
        } catch {
            errorMessage = "プロフィールを保存できませんでした"
            isSavingAccountSetup = false
            return false
        }
    }

    public func updateOwnProfile(_ input: OwnProfileUpdateInput) async -> Bool {
        guard !isSavingOwnProfile else {
            return false
        }

        let normalizedHandle = MegrumAppStateInputNormalizer.profileHandle(input.handle)
        let trimmedDisplayName = MegrumAppStateInputNormalizer.trimmedText(input.displayName)
        guard let normalizedHandle else {
            errorMessage = "ユーザーIDを入力してください"
            return false
        }
        guard MegrumAppStateInputNormalizer.isValidProfileHandle(normalizedHandle) else {
            errorMessage = "ユーザーIDは半角英数字・_ の3〜20文字で入力してください"
            return false
        }
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "表示名を入力してください"
            return false
        }

        isSavingOwnProfile = true
        errorMessage = nil

        do {
            let savedViewer = try await repository.updateOwnProfile(
                OwnProfileUpdateInput(
                    handle: normalizedHandle,
                    displayName: trimmedDisplayName,
                    gender: input.gender,
                    prefecture: MegrumAppStateInputNormalizer.prefecture(input.prefecture),
                    paymentMethods: input.paymentMethods,
                    avatarURL: input.avatarURL,
                    avatarUpload: input.avatarUpload,
                    clearsAvatar: input.clearsAvatar
                )
            )
            viewer = savedViewer
            isSavingOwnProfile = false
            return true
        } catch {
            errorMessage = "プロフィールを保存できませんでした"
            isSavingOwnProfile = false
            return false
        }
    }
}
