import Foundation

/// グルーム返信の文脈カードを出すかどうかの判定。
/// グルームは公開から24時間で失効するため、メッセージ送信から24時間を
/// 過ぎていればグルームは確実に失効しており、カード自体を表示しない。
enum GroomContextCardPolicy {
    static let groomLifetime: TimeInterval = 24 * 60 * 60

    static func isCertainlyExpired(messageCreatedAt: Date, now: Date = .now) -> Bool {
        now.timeIntervalSince(messageCreatedAt) > groomLifetime
    }
}
