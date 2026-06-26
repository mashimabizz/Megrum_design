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
    var initialShippingFee: IndividualListingShippingFeeDraft? = nil
    var initialShippingDays: IndividualListingShippingDaysDraft? = nil
    var initialStep: ProposalCreateStep = .give
    var submissionStatusOverride: ProposalStatus?
    var showsCompletionAfterCreate = true
    var visualQAInitialScreen: VisualQAInitialScreen? = nil
    var onCreateSuccess: (() async -> Void)?
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) var dismiss
    @Environment(\.megrumSlidePresentationDismiss) var slidePresentationDismiss
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
}
