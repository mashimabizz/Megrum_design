import Foundation

/// めぐりメッセージの保持ポリシー（iter1226.462）。
/// - テキストのやりとり：保持し続ける（端末側キャッシュ＝`MeguriMessageLocalStore`でも保持）
/// - 画像：**送信から14日で有効期限切れ**。サーバー側でストレージ実体を削除し、
///   クライアントは写真アイコンのプレースホルダに差し替える。
public enum MeguriMessageMediaPolicy {
    /// 画像の保持日数。サーバー側の削除ジョブ（expire_meguri_message_media）と揃える。
    public static let imageRetentionDays = 14

    public static var imageRetentionInterval: TimeInterval {
        TimeInterval(imageRetentionDays) * 24 * 60 * 60
    }

    /// 送信日時から見て画像が期限切れか。
    public static func isImageExpired(sentAt: Date, now: Date = .now) -> Bool {
        now.timeIntervalSince(sentAt) >= imageRetentionInterval
    }
}
