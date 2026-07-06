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
    var revisingProposalID: UUID?
    var showsCompletionAfterCreate = true
    var visualQAInitialScreen: VisualQAInitialScreen? = nil
    var onCreateSuccess: (() async -> Void)?
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) var dismiss
    @Environment(\.megrumSlidePresentationDismiss) var slidePresentationDismiss
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @AppStorage(HomeExchangeSettingsStorageKeys.localPrefecture) var exchangeLocalPrefecture = HomeDefaultExchangeSettings.standard.localPrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateKeys) var exchangeLocalDateKeysRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingFee) var exchangeMailShippingFeeRawValue = HomeDefaultExchangeSettings.standard.mailShippingFee.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingDays) var exchangeMailShippingDaysRawValue = HomeDefaultExchangeSettings.standard.mailShippingDays.rawValue
    @State var selectedStep: ProposalCreateStep = .give
    @State var selectedSenderGoodsIDs: Set<UUID> = []
    @State var selectedReceiverGoodsIDs: Set<UUID> = []
    @State var valueSelectionState = ProposalCreateValueSelectionState()
    @State var filterState = ProposalCreateFilterState()
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
    @State var initialStateFlags = ProposalCreateInitialStateFlags()
    @State var showsAddressSettings = false
    @State var showsPartnerScheduleCalendar = false
    @State var shippingFee: IndividualListingShippingFeeDraft = .negotiate
    @State var shippingDays: IndividualListingShippingDaysDraft = .twoToFourDays
    @StateObject var locationState = MegrumLocationState()
}
