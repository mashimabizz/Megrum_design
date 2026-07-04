import Foundation
import MegrumCore

extension MegrumAppState {
    public func loadNotifications(reportsFailure: Bool = true) async {
        guard !isLoadingNotifications else {
            return
        }

        isLoadingNotifications = true
        if reportsFailure {
            errorMessage = nil
        }
        do {
            notifications = try await repository.loadNotifications(limit: 100)
        } catch {
            if reportsFailure {
                errorMessage = "通知を読み込めませんでした"
            }
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
            applyNotificationSettings(try await repository.loadNotificationSettings())
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
    public func setGroomActivityPushNotificationsEnabled(_ enabled: Bool) async -> Bool {
        guard !isSavingPushNotificationSetting else {
            return false
        }

        let previous = groomActivityPushNotificationsEnabled
        groomActivityPushNotificationsEnabled = enabled
        isSavingPushNotificationSetting = true
        errorMessage = nil
        do {
            let settings = try await repository.setGroomActivityPushNotificationsEnabled(enabled)
            groomActivityPushNotificationsEnabled = settings.groomActivityPushEnabled
            isSavingPushNotificationSetting = false
            return true
        } catch {
            groomActivityPushNotificationsEnabled = previous
            errorMessage = "グルーム通知設定を保存できませんでした"
            isSavingPushNotificationSetting = false
            return false
        }
    }

    @discardableResult
    public func setChatroomActivityPushNotificationsEnabled(_ enabled: Bool) async -> Bool {
        guard !isSavingPushNotificationSetting else {
            return false
        }

        let previous = chatroomActivityPushNotificationsEnabled
        chatroomActivityPushNotificationsEnabled = enabled
        isSavingPushNotificationSetting = true
        errorMessage = nil
        do {
            let settings = try await repository.setChatroomActivityPushNotificationsEnabled(enabled)
            chatroomActivityPushNotificationsEnabled = settings.chatroomActivityPushEnabled
            isSavingPushNotificationSetting = false
            return true
        } catch {
            chatroomActivityPushNotificationsEnabled = previous
            errorMessage = "チャットルーム通知設定を保存できませんでした"
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

    /// めぐりの通知アイコンから変更する購読通知設定（推し一致・圏内の新着投稿）を保存する。
    @discardableResult
    public func setMeguriSubscriptionPushSettings(_ input: MeguriSubscriptionPushSettingsInput) async -> Bool {
        guard !isSavingPushNotificationSetting else {
            return false
        }

        let previous = MeguriSubscriptionPushSettingsInput(
            groomOshiPushEnabled: groomOshiPushNotificationsEnabled,
            groomNearbyPushEnabled: groomNearbyPushNotificationsEnabled,
            chatroomOshiPushEnabled: chatroomOshiPushNotificationsEnabled,
            chatroomNearbyPushEnabled: chatroomNearbyPushNotificationsEnabled
        )
        applyMeguriSubscriptionSettings(input)
        isSavingPushNotificationSetting = true
        errorMessage = nil
        do {
            let settings = try await repository.setMeguriSubscriptionPushSettings(input)
            applyMeguriSubscriptionSettings(
                MeguriSubscriptionPushSettingsInput(
                    groomOshiPushEnabled: settings.groomOshiPushEnabled,
                    groomNearbyPushEnabled: settings.groomNearbyPushEnabled,
                    chatroomOshiPushEnabled: settings.chatroomOshiPushEnabled,
                    chatroomNearbyPushEnabled: settings.chatroomNearbyPushEnabled
                )
            )
            isSavingPushNotificationSetting = false
            return true
        } catch {
            applyMeguriSubscriptionSettings(previous)
            errorMessage = "通知設定を保存できませんでした"
            isSavingPushNotificationSetting = false
            return false
        }
    }

    /// 圏内通知の基準位置を更新する。圏内通知が無効なら何もしない。
    public func updatePushNotificationLocationIfNeeded(latitude: Double, longitude: Double) async {
        guard groomNearbyPushNotificationsEnabled || chatroomNearbyPushNotificationsEnabled else {
            return
        }
        try? await repository.updatePushNotificationLocation(latitude: latitude, longitude: longitude)
    }

    private func applyMeguriSubscriptionSettings(_ input: MeguriSubscriptionPushSettingsInput) {
        groomOshiPushNotificationsEnabled = input.groomOshiPushEnabled
        groomNearbyPushNotificationsEnabled = input.groomNearbyPushEnabled
        chatroomOshiPushNotificationsEnabled = input.chatroomOshiPushEnabled
        chatroomNearbyPushNotificationsEnabled = input.chatroomNearbyPushEnabled
    }

    private func applyNotificationSettings(_ settings: UserNotificationSettings) {
        pushNotificationsEnabled = settings.pushEnabled
        groomActivityPushNotificationsEnabled = settings.groomActivityPushEnabled
        chatroomActivityPushNotificationsEnabled = settings.chatroomActivityPushEnabled
        groomOshiPushNotificationsEnabled = settings.groomOshiPushEnabled
        groomNearbyPushNotificationsEnabled = settings.groomNearbyPushEnabled
        chatroomOshiPushNotificationsEnabled = settings.chatroomOshiPushEnabled
        chatroomNearbyPushNotificationsEnabled = settings.chatroomNearbyPushEnabled
    }
}
