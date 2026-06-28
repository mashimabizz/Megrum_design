import MegrumCore

enum SettingsStatusTextResolver {
    static func notificationStatusText(hasNotifications: Bool, unreadCount: Int) -> String {
        guard hasNotifications else {
            return "未読なし"
        }
        if unreadCount > 0 {
            return "未読 \(unreadCount)件"
        }
        return "すべて既読"
    }

    static func pushNotificationStatusText(isEnabled: Bool) -> String {
        isEnabled ? "端末に通知を届ける" : "端末通知はOFF"
    }

    static func groomNotificationStatusText(isEnabled: Bool) -> String {
        isEnabled ? "いいね・メッセージ" : "グルーム通知はOFF"
    }

    static func chatroomNotificationStatusText(isEnabled: Bool) -> String {
        isEnabled ? "投稿・返信" : "チャットルーム通知はOFF"
    }

    static func profileStatusText(viewer: UserProfile?) -> String {
        guard let viewer else {
            return "未読み込み"
        }
        if let prefecture = viewer.prefecture, !prefecture.isEmpty {
            return "\(viewer.displayName) / \(prefecture)"
        }
        return viewer.displayName
    }

    static func addressStatusText(address: MailingAddress?) -> String {
        guard let address, address.isReady else {
            return "未登録"
        }
        return address.summary
    }

    static func subscriptionStatusText(isActive: Bool) -> String {
        isActive ? "有効" : "未加入"
    }
}
