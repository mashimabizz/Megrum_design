import Foundation
import MegrumCore

struct TradeChatTimestampFormatter: Equatable, Sendable {
    /// 日跨ぎセパレータ（今日/昨日/M/d(曜)）。チャット共通の表記に合わせる。
    static func dayDividerText(for date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        ChatTimestampFormatter.daySeparatorText(for: date, now: now, calendar: calendar)
    }
}

struct TradeMessageReadReceiptPolicy: Equatable, Sendable {
    static func isReadByPartner(_ message: TradeMessage, partnerLastReadAt: Date?) -> Bool {
        guard let partnerLastReadAt else {
            return false
        }
        switch message.messageType {
        case .system, .arrivalStatus:
            return false
        case .text, .photo, .outfitPhoto, .location:
            return partnerLastReadAt >= message.createdAt
        }
    }
}

struct TradeChatTimelineRow: Identifiable, Equatable {
    var message: TradeMessage
    var isMine: Bool
    var isReadByPartner: Bool
    var dayDividerText: String?

    var id: UUID { message.id }
}

struct TradeChatTimelineRows: Equatable, Sendable {
    static func make(
        messages: [TradeMessage],
        viewerID: UUID?,
        partnerLastReadAt: Date?,
        calendar: Calendar = .current
    ) -> [TradeChatTimelineRow] {
        messages.enumerated().map { index, message in
            let isMine = message.senderID == viewerID
            return TradeChatTimelineRow(
                message: message,
                isMine: isMine,
                isReadByPartner: isMine && TradeMessageReadReceiptPolicy.isReadByPartner(
                    message,
                    partnerLastReadAt: partnerLastReadAt
                ),
                dayDividerText: dayDividerText(for: message, at: index, in: messages, calendar: calendar)
            )
        }
    }

    private static func dayDividerText(
        for message: TradeMessage,
        at index: Int,
        in messages: [TradeMessage],
        calendar: Calendar
    ) -> String? {
        if index == 0 {
            return TradeChatTimestampFormatter.dayDividerText(for: message.createdAt, calendar: calendar)
        }
        guard messages.indices.contains(index - 1) else {
            return nil
        }
        let previous = messages[index - 1]
        guard !calendar.isDate(message.createdAt, inSameDayAs: previous.createdAt) else {
            return nil
        }
        return TradeChatTimestampFormatter.dayDividerText(for: message.createdAt, calendar: calendar)
    }
}
