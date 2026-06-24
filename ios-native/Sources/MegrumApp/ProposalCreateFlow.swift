import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCreateFlow: View {
    static let messageLimit = 400

    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]?
    var initialSenderGoodsIDs: [UUID] = []
    var matchType: ProposalMatchType = .perfect
    var initialExchangeMethod: ExchangeMethod? = nil
    var initialCashAmount: Int? = nil
    var initialStep: ProposalCreateStep = .give
    var visualQAInitialScreen: VisualQAInitialScreen? = nil
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) var dismiss
    @State var selectedStep: ProposalCreateStep = .give
    @State var selectedSenderGoodsIDs: Set<UUID> = []
    @State var selectedReceiverGoodsIDs: Set<UUID> = []
    @State var senderSelectionMode: ProposalSideSelectionMode = .goods
    @State var receiverSelectionMode: ProposalSideSelectionMode = .goods
    @State var senderCashAmountText = ""
    @State var receiverCashAmountText = ""
    @State var selectedPaymentOptionID: String?
    @State var senderGroupFilterID: UUID?
    @State var senderGoodsTypeFilterID: UUID?
    @State var receiverGroupFilterID: UUID?
    @State var receiverGoodsTypeFilterID: UUID?
    @State var exchangeMethod: ExchangeMethod = .hand
    @State var shareSchedule = true
    @State var message = ""
    @State var meetupPrefecture = ""
    @State var meetupPlaceMemo = ""
    @State var meetupStartAt = Date()
    @State var meetupEndAt = Date().addingTimeInterval(30 * 60)
    @State var meetupPlaceName = ""
    @State var meetupLatitudeText = ""
    @State var meetupLongitudeText = ""
    @State var meetupCandidateDrafts: [ProposalMeetupCandidateDraft] = []
    @State var selectedMeetupCandidateIndex = 0
    @State var meetupCalendarAnchorDate = Date()
    @State var meetupPlaceSheetRoute: ProposalMeetupPlaceSheetRoute?
    @State var submittedSummary: ProposalSubmittedSummary?
    @State var didApplyInitialExchangeMethod = false
    @State var didApplyInitialStep = false
    @State var didApplyVisualQAState = false
    @State var showsAddressSettings = false
    @State var shippingFee: IndividualListingShippingFeeDraft = .negotiate
    @State var shippingDays: IndividualListingShippingDaysDraft = .twoToFourDays
    @StateObject var locationState = MegrumLocationState()

    var visibleSteps: [ProposalCreateStep] {
        var steps: [ProposalCreateStep] = [.give, .receive]
        if configuration.requiresMeetupBeforeSubmit {
            steps.append(.meetup)
        }
        if configuration.requiresShippingBeforeSubmit {
            steps.append(.shipping)
        }
        if configuration.requiresPaymentSelection {
            steps.append(.payment)
        }
        steps.append(.confirm)
        return steps
    }

    var selectableSenderGoods: [GoodsItem] {
        let senderGoods = MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
        guard let viewerID = appState.viewer?.id else {
            return senderGoods
        }
        return senderGoods.filter { $0.ownerID == viewerID }
    }

    var receiverChoiceGoods: [GoodsItem] {
        let loaded = appState.publicTradeGoodsByUserID[targetItem.ownerID] ?? []
        return MatchRelationComposer.deduplicatedGoods([targetItem] + loaded)
            .filter { $0.marketAvailableQuantity > 0 }
    }

    var orderedSenderGoodsIDs: [UUID] {
        return selectableSenderGoods.map(\.id).filter { selectedSenderGoodsIDs.contains($0) }
    }

    var orderedReceiverGoodsIDs: [UUID] {
        return receiverChoiceGoods.map(\.id).filter { selectedReceiverGoodsIDs.contains($0) }
    }

    var selectedSenderGoods: [GoodsItem] {
        return selectableSenderGoods.filter { selectedSenderGoodsIDs.contains($0.id) }
    }

    var selectedReceiverGoods: [GoodsItem] {
        return receiverChoiceGoods.filter { selectedReceiverGoodsIDs.contains($0.id) }
    }

    var resolvedReceiverGoodsIDs: [UUID] {
        orderedReceiverGoodsIDs
    }

    var configuration: ProposalCreateConfiguration {
        ProposalCreateConfiguration(
            exchangeMethod: exchangeMethod,
            hasSelectedSenderGoods: !orderedSenderGoodsIDs.isEmpty,
            hasCashOffer: senderCashAmount != nil,
            hasReceiverCashRequest: receiverCashAmount != nil,
            isCreatingProposal: appState.isCreatingProposal,
            hasReadyMailingAddress: appState.mailingAddress?.isReady == true,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            hasValidMeetup: meetupInput?.isValid == true,
            requiresPaymentSelection: requiresPaymentStep,
            hasSelectedPaymentMethod: !requiresPaymentStep || selectedPaymentOption != nil,
            receiverGoodsCount: resolvedReceiverGoodsIDs.count,
            isListingSource: listingID != nil
        )
    }

    var meetupInput: ProposalMeetupInput? {
        guard exchangeMethod == .hand || exchangeMethod == .both else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupDisplayPlaceName,
            latitude: meetupLatitude,
            longitude: meetupLongitude
        )
        return input.isValid ? input : nil
    }

    var meetupInputsForSubmission: [ProposalMeetupInput] {
        meetupInput.map { [$0] } ?? []
    }

    var selectedMeetupCandidateDraft: ProposalMeetupCandidateDraft {
        let candidateID = meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex)
            ? meetupCandidateDrafts[selectedMeetupCandidateIndex].id
            : UUID()
        return ProposalMeetupCandidateDraft(
            id: candidateID,
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupPlaceName,
            latitudeText: meetupLatitudeText,
            longitudeText: meetupLongitudeText
        )
    }

    var displayMeetupCandidateDrafts: [ProposalMeetupCandidateDraft] {
        var drafts = meetupCandidateDrafts
        if drafts.indices.contains(selectedMeetupCandidateIndex) {
            drafts[selectedMeetupCandidateIndex] = selectedMeetupCandidateDraft
        }
        return drafts
    }

    var proposalScheduleContext: ProposalScheduleContext {
        let cachedSchedules = appState.schedulesByProposalID.values.reduce(into: [PersonalSchedule]()) { result, schedules in
            result.append(contentsOf: schedules)
        }
        return ProposalScheduleContext(
            schedules: cachedSchedules,
            viewerID: appState.viewer?.id,
            partnerID: targetItem.ownerID,
            selectedStartAt: meetupStartAt,
            selectedEndAt: meetupEndAt
        )
    }

    var meetupSummary: String {
        if let meetupInput {
            return "\(Self.dateText(meetupInput.startAt)) / \(meetupInput.normalizedPlaceName)"
        }
        return configuration.requiresMeetupBeforeSubmit ? "未設定" : "現地では会わない設定"
    }

    var senderCashAmount: Int? {
        return TradeAmountFormatter.cashInputValue(from: senderCashAmountText)
    }

    var receiverCashAmount: Int? {
        return TradeAmountFormatter.cashInputValue(from: receiverCashAmountText)
    }

    var proposalCashAmount: Int? {
        senderCashAmount ?? receiverCashAmount
    }

    var proposalCashAmountSide: ProposalCashSide? {
        if senderCashAmount != nil {
            return .sender
        }
        if receiverCashAmount != nil {
            return .receiver
        }
        return nil
    }

    var requiresPaymentStep: Bool {
        senderCashAmount != nil || receiverCashAmount != nil
    }

    var senderSelectionCount: Int {
        orderedSenderGoodsIDs.count + (senderCashAmount == nil ? 0 : 1)
    }

    var receiverSelectionCount: Int {
        resolvedReceiverGoodsIDs.count + (receiverCashAmount == nil ? 0 : 1)
    }

    var draftExchangeSummary: IndividualListingExchangeSummary {
        IndividualListingExchangeSummary(
            handoffMethod: exchangeMethod.listingHandoffDraft,
            localPrefecture: currentMeetupPrefecture,
            localPlaceMemo: meetupPlaceMemo,
            localSchedule: Self.dateText(meetupStartAt),
            shippingFee: shippingFee,
            shippingDays: shippingDays,
            acceptsOutsideCondition: true
        )
    }

    var viewerListingExchangeSummary: IndividualListingExchangeSummary? {
        let selectedOrInitialSenderIDs = selectedSenderGoodsIDs.union(Set(initialSenderGoodsIDs))
        if let listingID,
           let listing = appState.listings.first(where: { $0.id == listingID }) {
            return IndividualListingExchangeSummary.extract(from: listing.note).summary
        }
        guard !selectedOrInitialSenderIDs.isEmpty else {
            return nil
        }
        return appState.listings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { selectedOrInitialSenderIDs.contains($0.itemID) }
            }
            .flatMap { IndividualListingExchangeSummary.extract(from: $0.note).summary }
    }

    var partnerExchangeSummary: IndividualListingExchangeSummary? {
        let partnerListings = appState.publicListingsByUserID[targetItem.ownerID] ?? []
        if let listingID,
           let listing = partnerListings.first(where: { $0.id == listingID }) {
            return IndividualListingExchangeSummary.extract(from: listing.note).summary
        }
        let receiverIDs = Set((receiverGoodsIDs ?? []) + [targetItem.id])
        return partnerListings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { receiverIDs.contains($0.itemID) }
            }
            .flatMap { IndividualListingExchangeSummary.extract(from: $0.note).summary }
    }

    var viewerListingForConditionDisplay: IndividualListing? {
        let selectedOrInitialSenderIDs = selectedSenderGoodsIDs.union(Set(initialSenderGoodsIDs))
        if let listingID,
           let listing = appState.listings.first(where: { $0.id == listingID }) {
            return listing
        }
        guard !selectedOrInitialSenderIDs.isEmpty else {
            return nil
        }
        return appState.listings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { selectedOrInitialSenderIDs.contains($0.itemID) }
            }
    }

    var partnerListingForConditionDisplay: IndividualListing? {
        let partnerListings = appState.publicListingsByUserID[targetItem.ownerID] ?? []
        if let listingID,
           let listing = partnerListings.first(where: { $0.id == listingID }) {
            return listing
        }
        let receiverIDs = Set((receiverGoodsIDs ?? []) + [targetItem.id])
        return partnerListings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { receiverIDs.contains($0.itemID) }
            }
    }

    var listingCashReferenceRows: [ProposalCashReferenceRow] {
        [
            partnerListingCashReferenceText.map { ProposalCashReferenceRow(label: "相手", value: $0) },
            viewerListingCashReferenceText.map { ProposalCashReferenceRow(label: "自分", value: $0) }
        ]
        .compactMap(\.self)
    }

    private var viewerListingCashReferenceText: String? {
        cashReferenceText(from: viewerListingForConditionDisplay)
    }

    private var partnerListingCashReferenceText: String? {
        cashReferenceText(from: partnerListingForConditionDisplay)
    }

    private func cashReferenceText(from listing: IndividualListing?) -> String? {
        guard let listing else {
            return nil
        }
        let values = listing.options
            .filter(\.isCashOffer)
            .map { TradeAmountFormatter.fixedPrice(amount: $0.cashAmount) }
        guard !values.isEmpty else {
            return nil
        }
        var seen = Set<String>()
        let uniqueValues = values.filter { seen.insert($0).inserted }
        return uniqueValues.joined(separator: " / ")
    }

    var currentMeetupPrefecture: String {
        meetupPrefecture.nilIfBlank
            ?? appState.viewer?.prefecture.nilIfBlank
            ?? targetItem.ownerPrefecture.nilIfBlank
            ?? "未設定"
    }

    var meetupDisplayPlaceName: String {
        [currentMeetupPrefecture.nilIfBlank, meetupPlaceMemo.nilIfBlank]
            .compactMap(\.self)
            .joined(separator: " / ")
    }

    var meetupLatitude: Double {
        Double(meetupLatitudeText) ?? locationState.coordinate?.latitude ?? 0
    }

    var meetupLongitude: Double {
        Double(meetupLongitudeText) ?? locationState.coordinate?.longitude ?? 0
    }

    var viewerLocalConditionText: String {
        viewerListingExchangeSummary?.localDetailTextForProposalDisplay ?? "未設定"
    }

    var partnerLocalConditionText: String {
        if let text = partnerExchangeSummary?.localDetailTextForProposalDisplay {
            return text
        }
        return "未設定"
    }

    var viewerShippingConditionText: String {
        viewerListingExchangeSummary?.mailDetailText ?? "未設定"
    }

    var partnerShippingConditionText: String {
        partnerExchangeSummary?.mailDetailText ?? "未設定"
    }

    var proposalMeetupSummaryText: String {
        draftExchangeSummary.localDetailTextForProposalDisplay ?? "未設定"
    }

    var proposalShippingSummaryText: String {
        draftExchangeSummary.mailDetailText ?? "未設定"
    }

    var viewerPaymentSummaryText: String {
        UserPaymentMethod.displayText(
            for: appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? [],
            otherNote: appState.paymentSettings?.otherNote ?? appState.viewer?.paymentNote
        )
    }

    var partnerPaymentSummaryText: String {
        if let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile {
            return profile.paymentSummaryText
        }
        return UserPaymentMethod.displayText(
            for: targetItem.ownerPaymentMethods,
            otherNote: targetItem.ownerPaymentNote
        )
    }

    var viewerPaymentOtherNote: String? {
        appState.paymentSettings?.otherNote ?? appState.viewer?.paymentNote
    }

    var partnerPaymentOtherNote: String? {
        if let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile {
            return profile.paymentNote
        }
        return targetItem.ownerPaymentNote
    }

    var viewerPaymentMethods: [UserPaymentMethod] {
        UserPaymentMethod.normalized(appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? [])
    }

    var partnerPaymentMethods: [UserPaymentMethod] {
        if let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile {
            return UserPaymentMethod.normalized(profile.paymentMethods)
        }
        return UserPaymentMethod.normalized(targetItem.ownerPaymentMethods)
    }

    var paymentNeedsDiscussion: Bool {
        guard senderCashAmount != nil || receiverCashAmount != nil else {
            return false
        }
        let commonMethods = Set(viewerPaymentMethods).intersection(Set(partnerPaymentMethods))
        return commonMethods.count != 1
    }

    var paymentOptionSections: [(section: ProposalPaymentOptionSection, options: [ProposalPaymentOption])] {
        ProposalPaymentOptionCatalog.sections(
            viewerMethods: viewerPaymentMethods,
            viewerOtherNote: viewerPaymentOtherNote,
            partnerMethods: partnerPaymentMethods,
            partnerOtherNote: partnerPaymentOtherNote
        )
    }

    var selectedPaymentOption: ProposalPaymentOption? {
        guard requiresPaymentStep else {
            return nil
        }
        let options = paymentOptionSections.flatMap(\.options)
        if let selectedPaymentOptionID,
           let selected = options.first(where: { $0.id == selectedPaymentOptionID }) {
            return selected
        }
        return options.first
    }

    var selectedPaymentSummaryText: String? {
        selectedPaymentOption?.confirmationTitle
    }

    var proposalConditionTags: [String] {
        var tags: [String] = []
        if configuration.requiresMeetupBeforeSubmit {
            tags.append("待ち合わせ: \(viewerLocalConditionText)")
        }
        if configuration.requiresShippingBeforeSubmit {
            tags.append("送料: \(shippingFee.title)")
            tags.append("発送目安: \(shippingDays.title)")
        }
        if senderCashAmount != nil || receiverCashAmount != nil {
            if let selectedPaymentSummaryText {
                tags.append("支払方法: \(selectedPaymentSummaryText)")
            }
        }
        return tags
    }

}

private extension ExchangeMethod {
    var listingHandoffDraft: IndividualListingHandoffDraft {
        switch self {
        case .hand:
            .local
        case .mail:
            .mail
        case .both:
            .both
        }
    }
}
