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
                // 行為者が分かる通知はアバターファースト（Instagram型）。右下に種別ミニバッジ。
                // 行為者なし（運営・期限等）は従来の種別アイコン円にフォールバック。iter1226.413。
                if notification.actorUserID != nil {
                    NotificationActorAvatar(
                        url: notification.actorAvatarURL,
                        badgeSymbolName: notification.kind.centerSymbolName,
                        badgeTint: notification.kind.centerTint
                    )
                } else {
                    Image(systemName: notification.kind.centerSymbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(notification.kind.centerTint)
                        .frame(width: 38, height: 38)
                        .background(notification.kind.centerTint.opacity(0.12), in: Circle())
                }

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
        NotificationRelativeTimeFormatter.text(from: notification.createdAt)
    }
}

/// いいね集約行：「◯◯さん、他N人がいいねしました」＋重ねアバター（iter1226.413）。
struct NotificationCenterLikeGroupRow: View {
    var group: NotificationCenterDisplayItem.GroomLikeGroup
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                stackedAvatars

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(group.summaryText)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        if let newest = group.newest {
                            Text(NotificationRelativeTimeFormatter.text(from: newest.createdAt))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(group.summaryText)
    }

    private var stackedAvatars: some View {
        let urls = group.stackedAvatarURLs
        return ZStack(alignment: .topLeading) {
            ForEach(Array(urls.enumerated().reversed()), id: \.offset) { index, url in
                NotificationAvatarImage(url: url, side: 30)
                    .overlay {
                        Circle().strokeBorder(.white, lineWidth: 1.5)
                    }
                    .offset(x: CGFloat(index) * 12, y: CGFloat(index) * 6)
            }

            Image(systemName: "heart.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Color(red: 0.94, green: 0.35, blue: 0.55), in: Circle())
                .offset(x: 24, y: 24)
        }
        .frame(width: 38 + CGFloat(max(0, urls.count - 1)) * 12, height: 42, alignment: .topLeading)
    }
}

/// 行為者アバター＋種別ミニバッジ。
struct NotificationActorAvatar: View {
    var url: URL?
    var badgeSymbolName: String
    var badgeTint: Color

    var body: some View {
        NotificationAvatarImage(url: url, side: 38)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: badgeSymbolName)
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundStyle(badgeTint)
                    .frame(width: 16, height: 16)
                    .background(.white, in: Circle())
                    .overlay {
                        Circle().strokeBorder(badgeTint.opacity(0.25), lineWidth: 0.5)
                    }
                    .offset(x: 3, y: 3)
            }
    }
}

struct NotificationAvatarImage: View {
    var url: URL?
    var side: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        ZStack {
            MegrumTheme.lavender.opacity(0.16)
            Image(systemName: "person.fill")
                .font(.system(size: side * 0.42, weight: .semibold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.7))
        }
    }
}

enum NotificationRelativeTimeFormatter {
    static func text(from createdAt: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(createdAt)))
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
        return createdAt.formatted(.dateTime.month().day())
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
