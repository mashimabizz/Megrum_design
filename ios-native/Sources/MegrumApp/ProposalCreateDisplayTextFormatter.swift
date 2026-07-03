import Foundation
import MegrumCore

enum ProposalCreateDisplayTextFormatter {
    static func methodTitle(_ method: ExchangeMethod) -> String {
        switch method {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地 / 郵送"
        }
    }

    static func dateText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
        )
    }
}
