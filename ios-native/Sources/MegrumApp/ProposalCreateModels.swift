import MegrumCore
import SwiftUI

enum ProposalCreateStep: String, CaseIterable, Identifiable, Equatable {
    case give
    case receive
    /// 3/3 交換条件（交換手段＋現地＋郵送＋支払をまとめた新ステップ）
    case conditions
    case meetup
    case shipping
    case payment
    case confirm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .give:
            "出すもの"
        case .receive:
            "受け取る"
        case .conditions:
            "交換条件"
        case .meetup:
            "待ち合わせ"
        case .shipping:
            "送料"
        case .payment:
            "支払方法"
        case .confirm:
            "確認"
        }
    }

    var shortTitle: String {
        switch self {
        case .give:
            "譲"
        case .receive:
            "受"
        case .conditions:
            "条件"
        case .meetup:
            "会う"
        case .shipping:
            "送料"
        case .payment:
            "支払"
        case .confirm:
            "送信"
        }
    }

    var symbolName: String {
        switch self {
        case .give:
            "shippingbox.fill"
        case .receive:
            "sparkles"
        case .conditions:
            "slider.horizontal.3"
        case .meetup:
            "mappin.and.ellipse"
        case .shipping:
            "envelope.fill"
        case .payment:
            "yensign.circle.fill"
        case .confirm:
            "checkmark.seal.fill"
        }
    }
}

enum ProposalSideSelectionMode: String, CaseIterable, Identifiable, Equatable {
    case goods
    case cash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goods:
            "譲から選ぶ"
        case .cash:
            "金額指定"
        }
    }
}

enum ProposalMeetupConditionMetrics {
    static let rowMinHeight: CGFloat = 48
    static let rowVerticalPadding: CGFloat = 10
}

struct ProposalSubmittedSummary: Equatable {
    var senderCount: Int
    var receiverCount: Int
    var partnerHandle: String
    var methodTitle: String
    var meetupSummary: String
    var conditionTags: [String]
    var exchangeMethod: ExchangeMethod
    var isRevision: Bool = false

    var detailText: String {
        let goodsText = "\(senderCount)件を提示 / \(receiverCount)件を受け取り候補"
        if conditionTags.isEmpty {
            return "\(goodsText)で送信しました。"
        }
        return "\(goodsText)・\(conditionTags.joined(separator: " / "))"
    }

    var completionTitle: String {
        "打診が完了しました"
    }

    var completionMessage: String {
        if isRevision {
            return "@\(partnerHandle) との条件を更新しました。ネゴ中として打診一覧に反映されます。"
        }
        switch exchangeMethod {
        case .mail:
            return "@\(partnerHandle) に郵送交換の打診を送りました。双方が合意すると住所が表示されます。"
        case .both:
            return "@\(partnerHandle) に現地・郵送どちらも可能な打診を送りました。返事が届いたら打診一覧で確認できます。"
        case .hand:
            return "@\(partnerHandle) に打診を送りました。返事が届いたら通知と打診一覧で確認できます。"
        }
    }
}
