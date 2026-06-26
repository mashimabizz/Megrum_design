import Foundation
import MegrumCore

struct TradePaymentResponseOption: Equatable, Identifiable, Sendable {
    var id: String
    var method: UserPaymentMethod
    var title: String
}

struct TradeProposalResponsePresentation: Equatable {
    var proposal: TradeProposal
    var viewerID: UUID?
    var proposedPaymentMethods: [UserPaymentMethod]
    var proposedPaymentOtherNote: String?
    var availablePaymentMethods: [UserPaymentMethod]
    var availablePaymentOtherNote: String?
    var viewerHasCounterProposal: Bool = false

    var isInitialSenderWaitingForPartner: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.status == .sent && proposal.isSender(viewerID)
    }

    var canRespond: Bool {
        guard
            let viewerID,
            proposal.isParticipant(viewerID),
            !isInitialSenderWaitingForPartner
        else {
            return false
        }
        return !proposal.agreementBy(viewerID)
    }

    var canAgree: Bool {
        canRespond && !viewerHasCounterProposal
    }

    var canCounterProposal: Bool {
        canRespond
    }

    var canReject: Bool {
        canRespond
    }

    var showsResponseControls: Bool {
        proposal.isProposalResponsePending && !isInitialSenderWaitingForPartner
    }

    var needsExchangeMethodSelection: Bool {
        proposal.exchangeMethod == .both && canAgree
    }

    var showsResponseInstruction: Bool {
        !viewerHasCounterProposal && (needsExchangeMethodSelection || showsPaymentSelector)
    }

    var responseHeaderText: String? {
        if viewerHasCounterProposal {
            return "現在出品中です。相手からの返信待ちです。"
        }
        return showsResponseInstruction ? "応じる条件を選んでください" : nil
    }

    var showsPrimaryAgreeAction: Bool {
        canAgree
    }

    var selectableExchangeMethods: [ExchangeMethod] {
        switch proposal.exchangeMethod {
        case .hand:
            [.hand]
        case .mail:
            [.mail]
        case .both:
            [.hand, .mail]
        }
    }

    var defaultSelectedExchangeMethod: ExchangeMethod? {
        switch proposal.exchangeMethod {
        case .hand:
            .hand
        case .mail:
            .mail
        case .both:
            .mail
        }
    }

    var responseSubtitle: String {
        "相手は「\(proposal.exchangeMethod.displayName)」で打診しています"
    }

    var showsPaymentSelector: Bool {
        proposal.cashOffer && canAgree
    }

    var paymentOptions: [UserPaymentMethod] {
        paymentMenuOptions.map(\.method).reduce(into: []) { result, method in
            guard !result.contains(method) else {
                return
            }
            result.append(method)
        }
    }

    var defaultPaymentMethod: UserPaymentMethod? {
        defaultPaymentOption?.method
    }

    var paymentMenuOptions: [TradePaymentResponseOption] {
        var options = Self.standardPaymentOptions
        let proposedOther = Self.otherOption(
            id: "partner-other",
            methodSource: proposedPaymentMethods,
            note: proposedPaymentOtherNote,
            fallbackTitle: "相手のその他"
        )
        let viewerOther = Self.otherOption(
            id: "viewer-other",
            methodSource: availablePaymentMethods,
            note: availablePaymentOtherNote,
            fallbackTitle: "あなたのその他"
        )
        if let proposedOther {
            options.append(proposedOther)
        }
        if let viewerOther, viewerOther.title != proposedOther?.title {
            options.append(viewerOther)
        }
        return options
    }

    var defaultPaymentOptionID: String? {
        defaultPaymentOption?.id
    }

    private var defaultPaymentOption: TradePaymentResponseOption? {
        let proposed = UserPaymentMethod.normalized(proposedPaymentMethods)
        let available = UserPaymentMethod.normalized(availablePaymentMethods)
        let preferredMethod = proposed.first { $0 != .other }
            ?? available.first { $0 != .other }
        if let preferredMethod,
           let option = paymentMenuOptions.first(where: { $0.method == preferredMethod }) {
            return option
        }
        if proposed.contains(.other),
           let option = paymentMenuOptions.first(where: { $0.id == "partner-other" }) {
            return option
        }
        if available.contains(.other),
           let option = paymentMenuOptions.first(where: { $0.id == "viewer-other" }) {
            return option
        }
        return paymentMenuOptions.first
    }

    func paymentTitle(for method: UserPaymentMethod?) -> String {
        guard let method else {
            return "未設定"
        }
        if method == .other {
            let note = proposedPaymentOtherNote?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? availablePaymentOtherNote?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? ""
            return note.isEmpty ? method.displayName : note
        }
        return method.displayName
    }

    func paymentOptionTitle(for optionID: String?) -> String {
        guard
            let optionID,
            let option = paymentMenuOptions.first(where: { $0.id == optionID })
        else {
            return "選択してください"
        }
        return option.title
    }

    func primaryActionTitle(selectedExchangeMethod: ExchangeMethod?) -> String {
        guard needsExchangeMethodSelection else {
            return "出品に応じる"
        }
        switch selectedExchangeMethod ?? defaultSelectedExchangeMethod {
        case .hand:
            return "現地交換で応じる"
        case .mail:
            return "郵送交換で応じる"
        case .both:
            return "出品に応じる"
        case nil:
            return "受け渡し方法を選択"
        }
    }

    var localExchangeDetailText: String {
        if let summary = listingExchangeSummary?.localDetailTextForProposalDisplay,
           !summary.isEmpty {
            return summary
        }
        guard let candidate = proposal.meetupCandidates?.first else {
            return "日程相談"
        }
        let place = candidate.normalizedPlaceName.isEmpty ? "場所相談" : candidate.normalizedPlaceName
        let date = candidate.startAt.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
        return "\(place) / \(date)"
    }

    var mailExchangeDetailText: String {
        listingExchangeSummary?.mailDetailText ?? "送料 要相談 / 発送目安相談"
    }

    private var listingExchangeSummary: IndividualListingExchangeSummary? {
        if let summary = conditionSummary(from: conditionTagsJoinedWithNewlines) {
            return summary
        }
        return conditionSummary(from: conditionTagsJoinedInline)
    }

    private var conditionTagsJoinedWithNewlines: String {
        proposal.conditionTags.joined(separator: "\n")
    }

    private var conditionTagsJoinedInline: String {
        proposal.conditionTags.joined(separator: " / ")
    }

    private func conditionSummary(from value: String) -> IndividualListingExchangeSummary? {
        IndividualListingExchangeSummary.extract(from: value).summary
    }

    private static var standardPaymentOptions: [TradePaymentResponseOption] {
        [
            TradePaymentResponseOption(id: "method:\(UserPaymentMethod.bankTransfer.rawValue)", method: .bankTransfer, title: UserPaymentMethod.bankTransfer.displayName),
            TradePaymentResponseOption(id: "method:\(UserPaymentMethod.paypay.rawValue)", method: .paypay, title: UserPaymentMethod.paypay.displayName),
            TradePaymentResponseOption(id: "method:\(UserPaymentMethod.cashExchange.rawValue)", method: .cashExchange, title: UserPaymentMethod.cashExchange.displayName)
        ]
    }

    private static func otherOption(
        id: String,
        methodSource: [UserPaymentMethod],
        note: String?,
        fallbackTitle: String
    ) -> TradePaymentResponseOption? {
        guard methodSource.contains(.other) else {
            return nil
        }
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return TradePaymentResponseOption(
            id: id,
            method: .other,
            title: trimmedNote.isEmpty ? fallbackTitle : trimmedNote
        )
    }
}
