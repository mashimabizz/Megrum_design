import MegrumDesign
import SwiftUI

struct HomeConditionTagSet: Equatable, Sendable {
    var goods: HomeGoodsCondition
    var exchange: HomeExchangeCondition
    var payment: HomePaymentCondition

    init(
        goods: HomeGoodsCondition,
        exchange: HomeExchangeCondition,
        payment: HomePaymentCondition
    ) {
        self.goods = goods
        self.exchange = exchange
        self.payment = payment
    }

    init(signals: HomeCandidateConditionSignals) {
        self.init(
            goods: HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods),
            exchange: HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange),
            payment: HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment)
        )
    }

    var accessibilityText: String {
        [
            goods.floatingTagTitle,
            exchange.floatingTagTitle,
            payment.floatingTagTitle
        ].joined(separator: "、")
    }

    var homeCandidateShowsExchangeTag: Bool {
        goods != .wish
    }

    var homeCandidateAccessibilityText: String {
        var titles = [goods.floatingTagTitle]
        if homeCandidateShowsExchangeTag {
            titles.append(exchange.floatingTagTitle)
        }
        titles.append(payment.floatingTagTitle)
        return titles.joined(separator: "、")
    }
}

enum HomeGoodsCondition: String, Sendable {
    case direct = "◎"
    case wish = "○"
    case none = "▲"

    var tagTitle: String { "グッズ\(rawValue)" }
    var floatingTagTitle: String { "グッズ\(rawValue)" }
    var shortTitle: String { "条件\(rawValue)" }

    var accent: Color {
        switch self {
        case .direct:
            MegrumTheme.conditionExact
        case .wish:
            MegrumTheme.conditionPossible
        case .none:
            MegrumTheme.conditionWarning
        }
    }
}

enum HomeExchangeCondition: String, Sendable {
    case exact = "◎"
    case possible = "○"
    case warning = "▲"

    var tagTitle: String { "交換\(rawValue)" }
    var floatingTagTitle: String { "交換\(rawValue)" }

    var accent: Color {
        switch self {
        case .exact:
            MegrumTheme.conditionExact
        case .possible:
            MegrumTheme.conditionPossible
        case .warning:
            MegrumTheme.conditionWarning
        }
    }
}

enum HomePaymentCondition: String, Sendable {
    case compatible = "○"
    case unknown = "?"
    case warning = "▲"

    var tagTitle: String { "支払\(rawValue)" }
    var floatingTagTitle: String { "支払\(rawValue)" }

    var accent: Color {
        switch self {
        case .compatible:
            MegrumTheme.conditionPossible
        case .unknown:
            MegrumTheme.muted
        case .warning:
            MegrumTheme.conditionWarning
        }
    }
}
