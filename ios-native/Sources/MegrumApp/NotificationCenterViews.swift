import MegrumCore
import MegrumDesign
import SwiftUI

/// 通知フィルタ（iter1226.408 刷新）：未読はX/Instagram同様に行背景色で示すため、
/// フィルタは「すべて/取引/めぐり」のカテゴリ切替に変更。
enum NotificationCenterFilter: String, CaseIterable, Identifiable {
    case all
    case trades
    case meguri

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "すべて"
        case .trades:
            "取引"
        case .meguri:
            "めぐり"
        }
    }
}

/// 通知行（iter1226.408 刷新）：
/// 種別アイコン＋「タイトル・時刻インライン」＋本文の X/Instagram 風レイアウト。
/// 未読チップは廃止（行背景の淡いラベンダーで示す）。打診受信には「確認する」ピルを内蔵。
struct NotificationCenterRow: View {
    var notification: MegrumNotification
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.kind.centerSymbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(notification.kind.centerTint)
                    .frame(width: 38, height: 38)
                    .background(notification.kind.centerTint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(notification.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Text(relativeTimeText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    if let body = notification.body, !body.isEmpty {
                        Text(body)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    if let actionTitle = notification.kind.centerInlineActionTitle {
                        Text(actionTitle)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .padding(.horizontal, 14)
                            .frame(height: 30)
                            .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                            .padding(.top, 3)
                    }
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(notification.title)
    }

    private var relativeTimeText: String {
        let seconds = max(0, Int(Date().timeIntervalSince(notification.createdAt)))
        let minutes = seconds / 60
        if minutes < 1 {
            return "今"
        }
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        let days = hours / 24
        if days < 7 {
            return "\(days)日前"
        }
        return notification.createdAt.formatted(.dateTime.month().day())
    }
}

extension MegrumNotificationKind {
    var centerSymbolName: String {
        switch self {
        case .proposalReceived:
            "envelope.badge"
        case .proposalAccepted, .tradeCompleted:
            "checkmark.circle"
        case .proposalRejected:
            "xmark.circle"
        case .proposalRevised:
            "pencil.circle"
        case .messageReceived:
            "message"
        case .evidenceAdded:
            "camera"
        case .evaluationReceived:
            "star"
        case .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            "exclamationmark.triangle"
        case .expiresSoon:
            "clock"
        case .groomLiked:
            "heart"
        case .groomReply, .meguriMessage:
            "message"
        case .groomPosted:
            "sparkles"
        case .meguriBoardReply, .meguriBoardMention:
            "text.bubble"
        case .meguriBoardPosted:
            "text.bubble.badge.clock"
        case .adminAnnouncement:
            "megaphone"
        case .unknown:
            "bell"
        }
    }

    var centerTint: Color {
        switch self {
        case .proposalAccepted, .tradeCompleted:
            MegrumTheme.ok
        case .proposalRejected, .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            MegrumTheme.conditionPossible
        case .evaluationReceived, .groomLiked, .meguriBoardMention, .expiresSoon:
            Color(red: 0.94, green: 0.35, blue: 0.55)
        case .messageReceived:
            MegrumTheme.sky
        default:
            MegrumTheme.lavender
        }
    }

    /// 行内アクションピル（Xのフォローバック位置）。行タップと同じ遷移の視覚的アフォーダンス。
    var centerInlineActionTitle: String? {
        switch self {
        case .proposalReceived:
            "確認する"
        case .evidenceAdded:
            "証跡を確認"
        default:
            nil
        }
    }

    var isTradeRelatedForCenter: Bool {
        switch self {
        case .proposalReceived, .proposalAccepted, .proposalRejected, .proposalRevised,
             .messageReceived, .evidenceAdded, .tradeCompleted, .evaluationReceived,
             .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested,
             .expiresSoon:
            true
        case .groomLiked, .groomReply, .groomPosted, .meguriMessage,
             .meguriBoardReply, .meguriBoardMention, .meguriBoardPosted,
             .adminAnnouncement, .unknown:
            false
        }
    }

    /// めぐり（グルーム・チャットルーム・めぐりメッセージ）系か。フィルタ「めぐり」用。
    var isMeguriRelatedForCenter: Bool {
        switch self {
        case .groomLiked, .groomReply, .groomPosted, .meguriMessage,
             .meguriBoardReply, .meguriBoardMention, .meguriBoardPosted:
            true
        default:
            false
        }
    }
}
