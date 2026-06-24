import Foundation
import MegrumCore

enum ProposalConfirmSectionCopy {
    static let meetupCandidatesTitle = "交換できる候補"
}

enum ProposalConfirmSectionKind: String, CaseIterable, Identifiable, Equatable {
    case exchangeContent
    case method
    case meetupCandidates
    case shipping
    case payment
    case message

    var id: String { rawValue }

    static func visibleOrder(
        requiresMeetupBeforeSubmit: Bool,
        requiresShippingBeforeSubmit: Bool = false,
        requiresPaymentSelection: Bool = false
    ) -> [ProposalConfirmSectionKind] {
        [
            .exchangeContent,
            .method,
            requiresMeetupBeforeSubmit ? .meetupCandidates : nil,
            requiresShippingBeforeSubmit ? .shipping : nil,
            requiresPaymentSelection ? .payment : nil,
            .message
        ]
        .compactMap(\.self)
    }
}

struct ProposalCashReferenceRow: Identifiable, Equatable {
    var label: String
    var value: String

    var id: String {
        "\(label):\(value)"
    }
}

enum ProposalCompletionAction: Equatable {
    case searchMore
    case openTrades
}

struct ProposalCompletionButtonSpec: Identifiable, Equatable {
    enum Role: Equatable {
        case secondary
        case primary
    }

    var action: ProposalCompletionAction
    var title: String
    var role: Role

    var id: ProposalCompletionAction { action }
}

enum ProposalCompletionButtonCopy {
    static let buttons: [ProposalCompletionButtonSpec] = [
        ProposalCompletionButtonSpec(action: .searchMore, title: "まだ他に探す", role: .secondary),
        ProposalCompletionButtonSpec(action: .openTrades, title: "打診一覧に飛ぶ", role: .primary)
    ]
}

struct ProposalCreateSubmissionDraft: Equatable {
    var receiverID: UUID
    var senderGoodsIDs: [UUID]
    var receiverGoodsIDs: [UUID]
    var exchangeMethod: ExchangeMethod
    var conditionTags: [String]
    var message: String
    var matchType: ProposalMatchType
    var status: ProposalStatus
    var meetupCandidates: [ProposalMeetupInput]
    var exposeCalendar: Bool
    var listingID: UUID?
    var cashAmount: Int? = nil
    var cashAmountSide: ProposalCashSide? = nil
    var senderCount: Int
    var receiverCount: Int
    var partnerHandle: String
    var methodTitle: String
    var meetupSummary: String

    var input: ProposalCreateInput {
        ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: senderGoodsIDs,
            receiverGoodsIDs: receiverGoodsIDs,
            exchangeMethod: exchangeMethod,
            conditionTags: conditionTags,
            message: normalizedMessage,
            matchType: matchType,
            status: status,
            meetup: meetupCandidates.first,
            meetupCandidates: meetupCandidates,
            exposeCalendar: exposeCalendar,
            listingID: listingID,
            cashOffer: cashAmount != nil,
            cashAmount: cashAmount,
            cashAmountSide: cashAmountSide
        )
    }

    var summary: ProposalSubmittedSummary {
        ProposalSubmittedSummary(
            senderCount: senderCount,
            receiverCount: receiverCount,
            partnerHandle: partnerHandle,
            methodTitle: methodTitle,
            meetupSummary: meetupSummary,
            conditionTags: conditionTags,
            exchangeMethod: exchangeMethod
        )
    }

    private var normalizedMessage: String? {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
