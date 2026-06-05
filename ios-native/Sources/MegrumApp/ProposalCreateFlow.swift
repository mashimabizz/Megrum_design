import Foundation
import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

enum ProposalCreateStep: String, CaseIterable, Identifiable, Equatable {
    case give
    case receive
    case meetup
    case confirm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .give:
            "出すもの"
        case .receive:
            "受け取る"
        case .meetup:
            "待ち合わせ"
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
        case .meetup:
            "会う"
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
        case .meetup:
            "mappin.and.ellipse"
        case .confirm:
            "checkmark.seal.fill"
        }
    }
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

enum ProposalCreateBottomBarCopy {
    static func primaryTitle(
        selectedStep: ProposalCreateStep,
        configuration: ProposalCreateConfiguration,
        meetupHasTimeDraft: Bool
    ) -> String {
        guard configuration.canAdvance(from: selectedStep) else {
            if selectedStep == .meetup {
                return meetupHasTimeDraft ? "場所未設定の候補があります" : "交換できる時間を設定してください"
            }
            return configuration.blockedTitle(for: selectedStep)
        }

        switch selectedStep {
        case .give:
            if configuration.receiverGoodsCount > 0 {
                return configuration.requiresMeetupBeforeSubmit ? "待ち合わせへ進む" : "次へ：送信確認"
            }
            return "受け取るものへ進む"
        case .receive:
            return configuration.requiresMeetupBeforeSubmit ? "待ち合わせへ進む" : "次へ：送信確認"
        case .meetup:
            return "次へ：送信確認"
        case .confirm:
            return configuration.submitTitle
        }
    }
}

enum ProposalCreatePrimaryStepDestination {
    static func destination(
        from selectedStep: ProposalCreateStep,
        configuration: ProposalCreateConfiguration,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        guard selectedStep != .confirm, configuration.canAdvance(from: selectedStep) else {
            return nil
        }

        switch selectedStep {
        case .give:
            if configuration.receiverGoodsCount > 0 {
                return nextMajorStep(configuration: configuration, visibleSteps: visibleSteps)
            }
            return adjacentStep(after: selectedStep, visibleSteps: visibleSteps)
        case .receive:
            return nextMajorStep(configuration: configuration, visibleSteps: visibleSteps)
        case .meetup:
            return visibleSteps.contains(.confirm) ? .confirm : nil
        case .confirm:
            return nil
        }
    }

    private static func nextMajorStep(
        configuration: ProposalCreateConfiguration,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        if configuration.requiresMeetupBeforeSubmit, visibleSteps.contains(.meetup) {
            return .meetup
        }
        return visibleSteps.contains(.confirm) ? .confirm : nil
    }

    private static func adjacentStep(
        after step: ProposalCreateStep,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        guard let index = visibleSteps.firstIndex(of: step),
              visibleSteps.indices.contains(index + 1)
        else {
            return nil
        }
        return visibleSteps[index + 1]
    }
}

enum ProposalFlowBottomBarPlacement {
    static func usesInlineScrollButton(for step: ProposalCreateStep) -> Bool {
        step == .confirm
    }
}

enum ProposalScheduleShareMetrics {
    static let cardGap: CGFloat = 12
    static let cardPadding: CGFloat = 13
    static let cardCornerRadius: CGFloat = 16
    static let titleFontSize: CGFloat = 13
    static let statusFontSize: CGFloat = 11
    static let statusTopSpacing: CGFloat = 2
    static let activeBackgroundOpacity: CGFloat = 0.08
    static let activeBorderOpacity: CGFloat = 0.48
    static let inactiveBorderOpacity: CGFloat = 0.08
}

enum ProposalFlowContentMetrics {
    static let defaultHorizontalPadding: CGFloat = 18
    static let confirmHorizontalPadding: CGFloat = 18
    static let defaultContentSpacing: CGFloat = 12
    static let confirmContentSpacing: CGFloat = 13
}

enum ProposalFlowBottomBarMetrics {
    static let horizontalPadding: CGFloat = 18
    static let topPadding: CGFloat = 10
    static let bottomPadding: CGFloat = 6
    static let inlineTopPadding: CGFloat = 4
    static let inlineBottomPadding: CGFloat = 4
    static let buttonMinHeight: CGFloat = 56
    static let buttonCornerRadius: CGFloat = 18
}

enum ProposalFlowScreenCopy {
    static func title(for step: ProposalCreateStep) -> String {
        step == .confirm ? "送信確認" : "提示物の選択"
    }

    static func confirmNoticeText(partnerHandle: String) -> String {
        "@\(partnerHandle) に下記の内容で打診を送ります。"
    }

    static func selectionTabs(from steps: [ProposalCreateStep]) -> [ProposalCreateStep] {
        steps.filter { $0 != .confirm }
    }
}

enum ProposalConfirmSectionCopy {
    static let meetupCandidatesTitle = "交換できる候補"
}

enum ProposalConfirmSectionKind: String, CaseIterable, Identifiable, Equatable {
    case exchangeContent
    case method
    case conditionTags
    case meetupCandidates
    case message
    case scheduleShare

    var id: String { rawValue }

    static func visibleOrder(requiresMeetupBeforeSubmit: Bool) -> [ProposalConfirmSectionKind] {
        [
            .exchangeContent,
            .method,
            .conditionTags,
            requiresMeetupBeforeSubmit ? .meetupCandidates : nil,
            .message,
            requiresMeetupBeforeSubmit ? .scheduleShare : nil
        ]
        .compactMap(\.self)
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
            listingID: listingID
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

struct ProposalCandidateListMetrics {
    static let spacing: CGFloat = 10
    static let paneSpacing: CGFloat = 10

    static func estimatedColumnCount(containerWidth: CGFloat) -> Int {
        1
    }
}

enum ProposalSelectableGoodsRowMetrics {
    static let rowSpacing: CGFloat = 12
    static let rowPadding: CGFloat = 10
    static let rowCornerRadius: CGFloat = 18
    static let selectedBackgroundOpacity: CGFloat = 0.08
    static let selectedBorderOpacity: CGFloat = 0.48
    static let defaultBorderOpacity: CGFloat = 0.08
    static let thumbnailWidth: CGFloat = 66
    static let thumbnailHeight: CGFloat = 82
    static let thumbnailCornerRadius: CGFloat = 15
    static let thumbnailShineSize: CGFloat = 56
    static let thumbnailShineOffsetX: CGFloat = 16
    static let thumbnailShineOffsetY: CGFloat = -18
    static let glyphFontSize: CGFloat = 27
    static let checkCircleSize: CGFloat = 26
}

enum ProposalExchangePreviewMetrics {
    static let thumbSize: CGFloat = 44
    static let thumbSpacing: CGFloat = 6

    static var thumbGridColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: thumbSize, maximum: thumbSize),
                spacing: thumbSpacing,
                alignment: .top
            )
        ]
    }
}

enum ProposalFlowHeaderMetrics {
    static let backButtonSize: CGFloat = 42
    static let backChevronSize: CGFloat = 18
    static let horizontalSpacing: CGFloat = 12
    static let kickerFontSize: CGFloat = 10
    static let kickerTracking: CGFloat = 0.7
    static let titleFontSize: CGFloat = 23
}

enum ProposalSectionTabsMetrics {
    static let containerPadding: CGFloat = 4
    static let tabGap: CGFloat = 4
    static let tabHorizontalPadding: CGFloat = 5
    static let tabVerticalPadding: CGFloat = 8
    static let minTabHeight: CGFloat = 36
    static let labelFontSize: CGFloat = 11.5
    static let countFontSize: CGFloat = 10
}

enum ProposalGoodsFilterMetrics {
    static let rowSpacing: CGFloat = 6
    static let labelWidth: CGFloat = 30
    static let labelFontSize: CGFloat = 9.5
    static let labelTracking: CGFloat = 0.4
    static let chipSpacing: CGFloat = 6
    static let chipHorizontalPadding: CGFloat = 10
    static let chipVerticalPadding: CGFloat = 5
    static let chipFontSize: CGFloat = 11
}

struct ProposalGoodsFilterCatalog {
    static func groupChoices(items: [GoodsItem], groups: [OshiGroup]) -> [ProposalFilterChoice] {
        let presentIDs = Set(items.compactMap(\.groupID))
        return groups
            .filter { presentIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .map { ProposalFilterChoice(id: $0.id, title: $0.name) }
    }

    static func goodsTypeChoices(items: [GoodsItem], goodsTypes: [GoodsType]) -> [ProposalFilterChoice] {
        let presentIDs = Set(items.compactMap(\.goodsTypeID))
        return goodsTypes
            .filter { presentIDs.contains($0.id) }
            .sorted { lhs, rhs in
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .map { ProposalFilterChoice(id: $0.id, title: $0.name) }
    }
}

struct ProposalMeetupMapDraft {
    static let fallbackPlaceName = "地図で選択した場所"

    static func coordinateValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func coordinateText(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    static func coordinate(latitudeText: String, longitudeText: String) -> MegrumLocationCoordinate? {
        guard
            let latitude = coordinateValue(from: latitudeText),
            let longitude = coordinateValue(from: longitudeText),
            isValid(latitude: latitude, longitude: longitude)
        else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
    }

    static func isValid(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
}

struct ProposalMeetupCandidateDraft: Identifiable, Equatable {
    static let maxCandidates = 3
    static let defaultDuration: TimeInterval = 30 * 60

    var id: UUID
    var startAt: Date
    var endAt: Date
    var placeName: String
    var latitudeText: String
    var longitudeText: String

    init(
        id: UUID = UUID(),
        startAt: Date = Date(),
        endAt: Date? = nil,
        placeName: String = "",
        latitudeText: String = "",
        longitudeText: String = ""
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt ?? startAt.addingTimeInterval(Self.defaultDuration)
        self.placeName = placeName
        self.latitudeText = latitudeText
        self.longitudeText = longitudeText
    }

    var meetupInput: ProposalMeetupInput? {
        guard let coordinate = ProposalMeetupMapDraft.coordinate(
            latitudeText: latitudeText,
            longitudeText: longitudeText
        ) else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: startAt,
            endAt: endAt,
            placeName: placeName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return input.isValid ? input : nil
    }

    var normalizedPlaceName: String {
        placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        meetupInput != nil
    }

    func summary(index: Int) -> String {
        let prefix = "候補\(index + 1)"
        let dateText = Self.dateText(startAt)
        if normalizedPlaceName.isEmpty {
            return "\(prefix) / \(dateText)"
        }
        return "\(prefix) / \(dateText) / \(normalizedPlaceName)"
    }

    func applyingCurrentLocation(_ coordinate: MegrumLocationCoordinate) -> Self {
        var draft = self
        if draft.normalizedPlaceName.isEmpty {
            draft.placeName = "現在地"
        }
        if draft.latitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.latitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        }
        if draft.longitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.longitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.longitude)
        }
        return draft
    }

    private static func dateText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
                .hour()
                .minute()
        )
    }
}

enum ProposalScheduleCalendarMode: String, CaseIterable, Identifiable, Equatable {
    case fiveDays
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fiveDays:
            "週"
        case .month:
            "月"
        }
    }
}

struct ProposalScheduleContext: Equatable {
    var schedules: [PersonalSchedule]
    var viewerID: UUID?
    var partnerID: UUID
    var selectedInterval: DateInterval

    init(
        schedules: [PersonalSchedule],
        viewerID: UUID?,
        partnerID: UUID,
        selectedStartAt: Date,
        selectedEndAt: Date
    ) {
        self.viewerID = viewerID
        self.partnerID = partnerID
        if selectedStartAt < selectedEndAt {
            self.selectedInterval = DateInterval(start: selectedStartAt, end: selectedEndAt)
        } else {
            self.selectedInterval = DateInterval(start: selectedStartAt, duration: 60)
        }

        var seenIDs: Set<UUID> = []
        self.schedules = schedules
            .filter { schedule in
                schedule.userID == viewerID || schedule.userID == partnerID
            }
            .filter { schedule in
                seenIDs.insert(schedule.id).inserted
            }
            .sorted { left, right in
                if left.startAt == right.startAt {
                    return left.title < right.title
                }
                return left.startAt < right.startAt
            }
    }

    var selectedOverlaps: [PersonalSchedule] {
        schedules.filter { schedule in
            schedule.overlaps(start: selectedInterval.start, end: selectedInterval.end)
        }
    }

    func roleText(for schedule: PersonalSchedule) -> String {
        schedule.userID == viewerID ? "あなた" : "相手"
    }

    func isMine(_ schedule: PersonalSchedule) -> Bool {
        schedule.userID == viewerID
    }

    func visibleDays(anchorDate: Date, mode: ProposalScheduleCalendarMode, calendar: Calendar = .current) -> [Date] {
        switch mode {
        case .fiveDays:
            let start = calendar.startOfDay(for: anchorDate)
            return (0..<5).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: start)
            }
        case .month:
            guard let month = calendar.dateInterval(of: .month, for: anchorDate),
                  let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
            else {
                return []
            }
            return dayRange.compactMap { day in
                calendar.date(byAdding: .day, value: day - 1, to: month.start)
            }
        }
    }

    func schedules(on day: Date, calendar: Calendar = .current) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return schedules.filter { schedule in
            schedule.overlaps(start: start, end: end)
        }
    }

    var placeSuggestions: [String] {
        var seen: Set<String> = []
        return schedules.compactMap { schedule in
            guard let placeName = schedule.placeName?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !placeName.isEmpty,
                  seen.insert(placeName).inserted
            else {
                return nil
            }
            return placeName
        }
    }
}

extension ProposalCreateConfiguration {
    func canAdvance(from step: ProposalCreateStep) -> Bool {
        switch step {
        case .give:
            hasSelectedSenderGoods
        case .receive:
            receiverGoodsCount > 0
        case .meetup:
            targetStatus != nil
        case .confirm:
            canSubmit
        }
    }

    func blockedTitle(for step: ProposalCreateStep) -> String {
        switch step {
        case .give:
            "出すものを選択してください"
        case .receive:
            "受け取るものを確認してください"
        case .meetup, .confirm:
            submitTitle
        }
    }
}

struct ProposalCreateFlow: View {
    private static let messageLimit = 400

    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]?
    var initialSenderGoodsIDs: [UUID] = []
    var matchType: ProposalMatchType = .perfect
    var initialStep: ProposalCreateStep = .give
    var visualQAInitialScreen: VisualQAInitialScreen? = nil
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStep: ProposalCreateStep = .give
    @State private var selectedSenderGoodsIDs: Set<UUID> = []
    @State private var selectedReceiverGoodsIDs: Set<UUID> = []
    @State private var senderGroupFilterID: UUID?
    @State private var senderGoodsTypeFilterID: UUID?
    @State private var receiverGroupFilterID: UUID?
    @State private var receiverGoodsTypeFilterID: UUID?
    @State private var exchangeMethod: ExchangeMethod = .hand
    @State private var selectedConditionTags: Set<String> = []
    @State private var shareSchedule = true
    @State private var message = ""
    @State private var meetupStartAt = Date()
    @State private var meetupEndAt = Date().addingTimeInterval(30 * 60)
    @State private var meetupPlaceName = ""
    @State private var meetupLatitudeText = ""
    @State private var meetupLongitudeText = ""
    @State private var meetupCandidateDrafts: [ProposalMeetupCandidateDraft] = []
    @State private var selectedMeetupCandidateIndex = 0
    @State private var meetupCalendarAnchorDate = Date()
    @State private var meetupPlaceFocusRequest = 0
    @State private var submittedSummary: ProposalSubmittedSummary?
    @State private var didApplyInitialStep = false
    @State private var didApplyVisualQAState = false
    @State private var showsAddressSettings = false
    @StateObject private var locationState = MegrumLocationState()

    private var visibleSteps: [ProposalCreateStep] {
        var steps: [ProposalCreateStep] = [.give, .receive]
        if configuration.requiresMeetupBeforeSubmit {
            steps.append(.meetup)
        }
        steps.append(.confirm)
        return steps
    }

    private var selectionTabs: [ProposalCreateStep] {
        ProposalFlowScreenCopy.selectionTabs(from: visibleSteps)
    }

    private var usesInlineBottomBar: Bool {
        ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: selectedStep)
    }

    private var horizontalContentPadding: CGFloat {
        selectedStep == .confirm
            ? ProposalFlowContentMetrics.confirmHorizontalPadding
            : ProposalFlowContentMetrics.defaultHorizontalPadding
    }

    private var contentSpacing: CGFloat {
        selectedStep == .confirm
            ? ProposalFlowContentMetrics.confirmContentSpacing
            : ProposalFlowContentMetrics.defaultContentSpacing
    }

    private var selectableSenderGoods: [GoodsItem] {
        let senderGoods = MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
        guard let viewerID = appState.viewer?.id else {
            return senderGoods
        }
        return senderGoods.filter { $0.ownerID == viewerID }
    }

    private var receiverChoiceGoods: [GoodsItem] {
        let loaded = appState.publicTradeGoodsByUserID[targetItem.ownerID] ?? []
        return MatchRelationComposer.deduplicatedGoods([targetItem] + loaded)
    }

    private var filteredSenderGoods: [GoodsItem] {
        selectableSenderGoods.filter { item in
            (senderGroupFilterID == nil || item.groupID == senderGroupFilterID)
                && (senderGoodsTypeFilterID == nil || item.goodsTypeID == senderGoodsTypeFilterID)
        }
    }

    private var senderGroupFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.groupChoices(items: selectableSenderGoods, groups: appState.oshiGroups)
    }

    private var senderGoodsTypeFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.goodsTypeChoices(items: selectableSenderGoods, goodsTypes: appState.goodsTypes)
    }

    private var filteredReceiverGoods: [GoodsItem] {
        receiverChoiceGoods.filter { item in
            (receiverGroupFilterID == nil || item.groupID == receiverGroupFilterID)
                && (receiverGoodsTypeFilterID == nil || item.goodsTypeID == receiverGoodsTypeFilterID)
        }
    }

    private var receiverGroupFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.groupChoices(items: receiverChoiceGoods, groups: appState.oshiGroups)
    }

    private var receiverGoodsTypeFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.goodsTypeChoices(items: receiverChoiceGoods, goodsTypes: appState.goodsTypes)
    }

    private var orderedSenderGoodsIDs: [UUID] {
        selectableSenderGoods.map(\.id).filter { selectedSenderGoodsIDs.contains($0) }
    }

    private var orderedReceiverGoodsIDs: [UUID] {
        receiverChoiceGoods.map(\.id).filter { selectedReceiverGoodsIDs.contains($0) }
    }

    private var selectedSenderGoods: [GoodsItem] {
        selectableSenderGoods.filter { selectedSenderGoodsIDs.contains($0.id) }
    }

    private var selectedReceiverGoods: [GoodsItem] {
        receiverChoiceGoods.filter { selectedReceiverGoodsIDs.contains($0.id) }
    }

    private var resolvedReceiverGoodsIDs: [UUID] {
        orderedReceiverGoodsIDs
    }

    private var configuration: ProposalCreateConfiguration {
        ProposalCreateConfiguration(
            exchangeMethod: exchangeMethod,
            hasSelectedSenderGoods: !orderedSenderGoodsIDs.isEmpty,
            isCreatingProposal: appState.isCreatingProposal,
            hasReadyMailingAddress: appState.mailingAddress?.isReady == true,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            hasValidMeetup: meetupInput?.isValid == true,
            receiverGoodsCount: resolvedReceiverGoodsIDs.count,
            isListingSource: listingID != nil
        )
    }

    private var conditionTagOptions: [String] {
        configuration.conditionTagOptions
    }

    private var orderedConditionTags: [String] {
        conditionTagOptions.filter { selectedConditionTags.contains($0) }
    }

    private var meetupInput: ProposalMeetupInput? {
        guard meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) else {
            return nil
        }
        return selectedMeetupCandidateDraft.meetupInput
    }

    private var meetupInputsForSubmission: [ProposalMeetupInput] {
        let drafts = displayMeetupCandidateDrafts
        let orderedIndices = [selectedMeetupCandidateIndex]
            + drafts.indices.filter { $0 != selectedMeetupCandidateIndex }
        return Array(
            orderedIndices
                .compactMap { index in drafts.indices.contains(index) ? drafts[index].meetupInput : nil }
                .prefix(ProposalMeetupCandidateDraft.maxCandidates)
        )
    }

    private var selectedMeetupCandidateDraft: ProposalMeetupCandidateDraft {
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

    private var displayMeetupCandidateDrafts: [ProposalMeetupCandidateDraft] {
        var drafts = meetupCandidateDrafts
        if drafts.indices.contains(selectedMeetupCandidateIndex) {
            drafts[selectedMeetupCandidateIndex] = selectedMeetupCandidateDraft
        }
        return drafts
    }

    private var proposalScheduleContext: ProposalScheduleContext {
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

    private var meetupSummary: String {
        if let meetupInput {
            return "\(Self.dateText(meetupInput.startAt)) / \(meetupInput.normalizedPlaceName)"
        }
        return configuration.requiresMeetupBeforeSubmit ? "未設定" : "現地では会わない設定"
    }

    var body: some View {
        Group {
            if let submittedSummary {
                ProposalCreateCompletionView(
                    summary: submittedSummary,
                    onSearchMore: {
                        onCompletionAction(.searchMore)
                        dismiss()
                    },
                    onOpenTrades: {
                        onCompletionAction(.openTrades)
                        dismiss()
                    }
                )
            } else {
                VStack(spacing: 0) {
                    ProposalFlowScreenHeader(
                        title: ProposalFlowScreenCopy.title(for: selectedStep),
                        onBack: handleHeaderLeadingAction
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                    ScrollView {
                        VStack(alignment: .leading, spacing: contentSpacing) {
                            if selectedStep != .confirm {
                                ProposalExchangeMethodSelector(
                                    exchangeMethod: $exchangeMethod
                                )

                                ProposalStepHeader(
                                    selectedStep: $selectedStep,
                                    steps: selectionTabs,
                                    configuration: configuration,
                                    senderCount: orderedSenderGoodsIDs.count,
                                    receiverCount: resolvedReceiverGoodsIDs.count
                                )
                            }

                            switch selectedStep {
                            case .give:
                                giveStep
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(stepSwipeGesture)
                            case .receive:
                                receiveStep
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(stepSwipeGesture)
                            case .meetup:
                                meetupStep
                            case .confirm:
                                ProposalConfirmNoticeCard(
                                    title: ProposalFlowScreenCopy.title(for: selectedStep),
                                    text: ProposalFlowScreenCopy.confirmNoticeText(partnerHandle: displayPartnerHandle)
                                )
                                confirmStep
                                ProposalFlowBottomBar(
                                    selectedStep: selectedStep,
                                    configuration: configuration,
                                    meetupHasTimeDraft: !displayMeetupCandidateDrafts.isEmpty,
                                    isCreating: appState.isCreatingProposal,
                                    isInline: true,
                                    onPrimary: primaryAction
                                )
                            }
                        }
                        .padding(.horizontal, horizontalContentPadding)
                        .padding(.top, 10)
                        .padding(.bottom, usesInlineBottomBar ? 20 : 104)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if submittedSummary == nil && !usesInlineBottomBar {
                ProposalFlowBottomBar(
                    selectedStep: selectedStep,
                    configuration: configuration,
                    meetupHasTimeDraft: !displayMeetupCandidateDrafts.isEmpty,
                    isCreating: appState.isCreatingProposal,
                    onPrimary: primaryAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #else
        .megrumInlineNavigationTitle()
        #endif
        .interactiveDismissDisabled(appState.isCreatingProposal || submittedSummary != nil)
        .onAppear {
            seedDefaultSenderSelection()
            seedDefaultReceiverSelection()
            normalizeMeetupEnd()
            applyVisualQAStateIfNeeded()
            applyInitialStepIfNeeded()
            meetupCalendarAnchorDate = calendarAnchorDate(for: meetupStartAt)
        }
        .task(id: targetItem.ownerID) {
            await appState.loadPublicExchangeContent(userID: targetItem.ownerID)
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
        }
        .task {
            if appState.oshiGroups.isEmpty {
                await appState.loadOshiGroups()
            }
            if appState.goodsTypes.isEmpty {
                await appState.loadGoodsTypes()
            }
        }
        .sheet(isPresented: $showsAddressSettings) {
            NavigationStack {
                AddressSettingsScreen(appState: appState)
            }
        }
        .onChange(of: selectableSenderGoods.map(\.id)) { _, ids in
            selectedSenderGoodsIDs = selectedSenderGoodsIDs.intersection(Set(ids))
            seedDefaultSenderSelection()
        }
        .onChange(of: receiverChoiceGoods.map(\.id)) { _, ids in
            selectedReceiverGoodsIDs = selectedReceiverGoodsIDs.intersection(Set(ids))
            seedDefaultReceiverSelection()
        }
        .onChange(of: exchangeMethod) { _, _ in
            selectedConditionTags = selectedConditionTags.intersection(Set(conditionTagOptions))
            if selectedStep == .meetup && !configuration.requiresMeetupBeforeSubmit {
                selectedStep = .confirm
            }
        }
        .onChange(of: message) { _, newValue in
            guard newValue.count > Self.messageLimit else {
                return
            }
            message = String(newValue.prefix(Self.messageLimit))
        }
        .onChange(of: meetupStartAt) { _, newValue in
            if meetupEndAt <= newValue {
                meetupEndAt = newValue.addingTimeInterval(30 * 60)
            }
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            guard let coordinate, configuration.requiresMeetupBeforeSubmit else {
                return
            }
            let updatedDraft = selectedMeetupCandidateDraft.applyingCurrentLocation(coordinate)
            applyMeetupCandidate(updatedDraft, at: selectedMeetupCandidateIndex)
        }
    }

    private var giveStep: some View {
        VStack(alignment: .leading, spacing: ProposalCandidateListMetrics.paneSpacing) {
            ProposalGoodsFilterBar(
                groupChoices: senderGroupFilterChoices,
                goodsTypeChoices: senderGoodsTypeFilterChoices,
                selectedGroupID: $senderGroupFilterID,
                selectedGoodsTypeID: $senderGoodsTypeFilterID
            )

            if selectableSenderGoods.isEmpty {
                ContentUnavailableView(
                    "在庫がありません",
                    systemImage: "tray",
                    description: Text("在庫を登録すると、ここから出すものを選べます。")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else if filteredSenderGoods.isEmpty {
                ContentUnavailableView(
                    "条件に合う在庫がありません",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("推しや種別の条件を変えてください。")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                VStack(spacing: ProposalCandidateListMetrics.spacing) {
                    ForEach(filteredSenderGoods) { item in
                        ProposalSelectableGoodsRow(
                            item: item,
                            isSelected: selectedSenderGoodsIDs.contains(item.id),
                            hintText: "相手がほしいものかも？"
                        ) {
                            toggleSenderGoods(item.id)
                        }
                    }
                }
            }
        }
    }

    private var receiveStep: some View {
        VStack(alignment: .leading, spacing: ProposalCandidateListMetrics.paneSpacing) {
            ProposalGoodsFilterBar(
                groupChoices: receiverGroupFilterChoices,
                goodsTypeChoices: receiverGoodsTypeFilterChoices,
                selectedGroupID: $receiverGroupFilterID,
                selectedGoodsTypeID: $receiverGoodsTypeFilterID
            )

            VStack(spacing: ProposalCandidateListMetrics.spacing) {
                ForEach(filteredReceiverGoods) { item in
                    ProposalSelectableGoodsRow(
                        item: item,
                        isSelected: selectedReceiverGoodsIDs.contains(item.id),
                        hintText: "私がほしいものかも？"
                    ) {
                        toggleReceiverGoods(item.id)
                    }
                }
            }

            if filteredReceiverGoods.isEmpty {
                ContentUnavailableView(
                    "条件に合う候補がありません",
                    systemImage: "sparkles",
                    description: Text("推しや種別の条件を変えてください。")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    private var meetupStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            if configuration.requiresMeetupBeforeSubmit {
                if !displayMeetupCandidateDrafts.isEmpty {
                    ProposalMeetupCandidatePicker(
                        drafts: displayMeetupCandidateDrafts,
                        selectedIndex: selectedMeetupCandidateIndex,
                        canAdd: meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates,
                        onSelect: selectMeetupCandidate,
                        onAdd: addMeetupCandidate,
                        onRemove: removeMeetupCandidate
                    )
                }

                ProposalMeetupCalendarEditor(
                    drafts: displayMeetupCandidateDrafts,
                    selectedIndex: selectedMeetupCandidateIndex,
                    anchorDate: meetupCalendarAnchorDate,
                    scheduleContext: proposalScheduleContext,
                    onSelectDraft: selectMeetupCandidate,
                    onShiftWeek: shiftMeetupWeek,
                    onSelectMonthDay: selectMeetupCalendarDay,
                    onCreateDraft: createMeetupCandidate,
                    onUpdateDraft: updateMeetupCandidate,
                    onOpenPlaceEntry: {
                        meetupPlaceFocusRequest += 1
                    }
                )

                ProposalScheduleBackgroundSection(
                    context: proposalScheduleContext,
                    selectedStartAt: meetupStartAt
                )

                ProposalFlowMeetupForm(
                    startAt: $meetupStartAt,
                    endAt: $meetupEndAt,
                    placeName: $meetupPlaceName,
                    latitudeText: $meetupLatitudeText,
                    longitudeText: $meetupLongitudeText,
                    isRequestingLocation: locationState.isRequestingLocation,
                    locationErrorMessage: locationState.locationErrorMessage,
                    placeSuggestions: proposalScheduleContext.placeSuggestions,
                    focusPlaceFieldRequest: meetupPlaceFocusRequest
                )
            }

        }
    }

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(ProposalConfirmSectionKind.visibleOrder(requiresMeetupBeforeSubmit: configuration.requiresMeetupBeforeSubmit)) { section in
                confirmSection(section)
            }

            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func confirmSection(_ section: ProposalConfirmSectionKind) -> some View {
        switch section {
        case .exchangeContent:
            ProposalConfirmSection(title: "交換内容") {
                ProposalExchangePreviewRow(
                    senderGoods: selectedSenderGoods,
                    receiverGoods: selectedReceiverGoods
                )
            }
        case .method:
            ProposalConfirmMethodCard(
                exchangeMethod: exchangeMethod,
                mailingAddress: appState.mailingAddress,
                isLoadingMailingAddress: appState.isLoadingMailingAddress,
                onOpenAddressSettings: {
                    showsAddressSettings = true
                }
            )
        case .conditionTags:
            ProposalConfirmSection(title: "交換条件タグ") {
                ProposalTagGrid(
                    tags: conditionTagOptions,
                    selectedTags: $selectedConditionTags
                )
            }
        case .meetupCandidates:
            ProposalConfirmMeetupCandidatesCard(candidates: meetupInputsForSubmission)
        case .message:
            ProposalConfirmSection(title: "メッセージ（任意）", rightText: "\(message.count) / \(Self.messageLimit)") {
                TextField("よろしくお願いします", text: $message, axis: .vertical)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(3...6)
                    .padding(12)
                    .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        case .scheduleShare:
            ProposalScheduleShareCard(shareSchedule: $shareSchedule)
        }
    }

    private var methodNotice: String? {
        if configuration.requiresMailingAddressBeforeSubmit && appState.isLoadingMailingAddress {
            return "住所登録を確認しています。"
        }
        if configuration.requiresMailingAddressBeforeSubmit && appState.mailingAddress?.isReady != true {
            return "郵送交換は住所登録が必要です。設定から住所を登録してください。"
        }
        if configuration.requiresMeetupBeforeSubmit && meetupInput == nil {
            return "日時、場所名、緯度経度を入れると次へ進めます。"
        }
        return nil
    }

    private func handleHeaderLeadingAction() {
        if selectedStep == .confirm {
            previousStep()
        } else {
            dismiss()
        }
    }

    private func toggleSenderGoods(_ id: UUID) {
        if selectedSenderGoodsIDs.contains(id) {
            guard selectedSenderGoodsIDs.count > 1 else {
                return
            }
            selectedSenderGoodsIDs.remove(id)
        } else {
            selectedSenderGoodsIDs.insert(id)
        }
    }

    private func toggleReceiverGoods(_ id: UUID) {
        if selectedReceiverGoodsIDs.contains(id) {
            guard selectedReceiverGoodsIDs.count > 1 else {
                return
            }
            selectedReceiverGoodsIDs.remove(id)
        } else {
            selectedReceiverGoodsIDs.insert(id)
        }
    }

    private func seedDefaultSenderSelection() {
        guard selectedSenderGoodsIDs.isEmpty else {
            return
        }
        let availableIDs = Set(selectableSenderGoods.map(\.id))
        let seededIDs = initialSenderGoodsIDs.filter { availableIDs.contains($0) }
        if !seededIDs.isEmpty {
            selectedSenderGoodsIDs = Set(seededIDs)
            return
        }
        guard let firstID = selectableSenderGoods.first?.id else {
            return
        }
        selectedSenderGoodsIDs.insert(firstID)
    }

    private func seedDefaultReceiverSelection() {
        guard selectedReceiverGoodsIDs.isEmpty else {
            return
        }
        let availableIDs = Set(receiverChoiceGoods.map(\.id))
        let candidateIDs = (receiverGoodsIDs ?? [targetItem.id]).filter { availableIDs.contains($0) }
        if !candidateIDs.isEmpty {
            selectedReceiverGoodsIDs = Set(candidateIDs)
            return
        }
        if availableIDs.contains(targetItem.id) {
            selectedReceiverGoodsIDs.insert(targetItem.id)
            return
        }
        if let firstID = receiverChoiceGoods.first?.id {
            selectedReceiverGoodsIDs.insert(firstID)
        }
    }

    private func applyVisualQAStateIfNeeded() {
        guard !didApplyVisualQAState else {
            return
        }
        didApplyVisualQAState = true
        guard visualQAInitialScreen == .proposalConfirm || visualQAInitialScreen == .proposalComplete else {
            return
        }
        seedVisualQAMeetupCandidateIfNeeded()
        selectedConditionTags = []
        message = ""
        shareSchedule = true
        selectedStep = .confirm
        if visualQAInitialScreen == .proposalComplete {
            submittedSummary = ProposalSubmittedSummary(
                senderCount: max(orderedSenderGoodsIDs.count, 1),
                receiverCount: max(resolvedReceiverGoodsIDs.count, 1),
                partnerHandle: displayPartnerHandle,
                methodTitle: Self.methodTitle(exchangeMethod),
                meetupSummary: meetupSummary,
                conditionTags: orderedConditionTags,
                exchangeMethod: exchangeMethod
            )
        }
    }

    private func seedVisualQAMeetupCandidateIfNeeded() {
        guard configuration.requiresMeetupBeforeSubmit, meetupCandidateDrafts.isEmpty else {
            return
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 7, hour: 16, minute: 30)) ?? Date()
        let end = start.addingTimeInterval(45 * 60)
        let draft = ProposalMeetupCandidateDraft(
            startAt: start,
            endAt: end,
            placeName: "東京ドーム 22ゲート前",
            latitudeText: "35.7056",
            longitudeText: "139.7519"
        )
        meetupCandidateDrafts = [draft]
        applyMeetupCandidate(draft, at: 0)
    }

    private func applyInitialStepIfNeeded() {
        guard !didApplyInitialStep else {
            return
        }
        didApplyInitialStep = true
        guard visibleSteps.contains(initialStep) else {
            return
        }
        if ProposalCreateStep.allCases
            .prefix(while: { $0 != initialStep })
            .allSatisfy({ configuration.canAdvance(from: $0) })
        {
            selectedStep = initialStep
        }
    }

    private func normalizeMeetupEnd() {
        if meetupEndAt <= meetupStartAt {
            meetupEndAt = meetupStartAt.addingTimeInterval(30 * 60)
        }
    }

    private func saveSelectedMeetupCandidate() {
        guard meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) else {
            return
        }
        meetupCandidateDrafts[selectedMeetupCandidateIndex] = selectedMeetupCandidateDraft
    }

    private func applyMeetupCandidate(_ draft: ProposalMeetupCandidateDraft, at index: Int) {
        selectedMeetupCandidateIndex = index
        meetupStartAt = draft.startAt
        meetupEndAt = draft.endAt
        meetupPlaceName = draft.placeName
        meetupLatitudeText = draft.latitudeText
        meetupLongitudeText = draft.longitudeText
        meetupCalendarAnchorDate = calendarAnchorDate(for: draft.startAt)
        normalizeMeetupEnd()
    }

    private func selectMeetupCandidate(_ index: Int) {
        guard meetupCandidateDrafts.indices.contains(index), index != selectedMeetupCandidateIndex else {
            return
        }
        saveSelectedMeetupCandidate()
        applyMeetupCandidate(meetupCandidateDrafts[index], at: index)
    }

    private func addMeetupCandidate() {
        guard meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates else {
            return
        }
        saveSelectedMeetupCandidate()
        let start = meetupEndAt.addingTimeInterval(30 * 60)
        let draft = ProposalMeetupCandidateDraft(
            startAt: start,
            placeName: meetupPlaceName,
            latitudeText: meetupLatitudeText,
            longitudeText: meetupLongitudeText
        )
        meetupCandidateDrafts.append(draft)
        applyMeetupCandidate(draft, at: meetupCandidateDrafts.count - 1)
    }

    private func removeMeetupCandidate(_ index: Int) {
        guard meetupCandidateDrafts.count > 1, meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        saveSelectedMeetupCandidate()
        meetupCandidateDrafts.remove(at: index)
        let nextIndex: Int
        if index < selectedMeetupCandidateIndex {
            nextIndex = max(0, selectedMeetupCandidateIndex - 1)
        } else if index == selectedMeetupCandidateIndex {
            nextIndex = min(index, meetupCandidateDrafts.count - 1)
        } else {
            nextIndex = selectedMeetupCandidateIndex
        }
        applyMeetupCandidate(meetupCandidateDrafts[nextIndex], at: nextIndex)
    }

    private func previousStep() {
        guard let index = visibleSteps.firstIndex(of: selectedStep), index > 0 else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = visibleSteps[index - 1]
        }
    }

    private func primaryAction() {
        if selectedStep == .confirm {
            Task {
                await createProposal()
            }
            return
        }
        guard let destination = ProposalCreatePrimaryStepDestination.destination(
            from: selectedStep,
            configuration: configuration,
            visibleSteps: visibleSteps
        ) else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = destination
        }
    }

    private var stepSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onEnded { value in
                guard selectedStep != .meetup, selectedStep != .confirm else {
                    return
                }
                guard let destination = ProposalStepSwipeNavigator.destination(
                    from: selectedStep,
                    translationWidth: value.translation.width,
                    translationHeight: value.translation.height,
                    visibleSteps: visibleSteps
                ) else {
                    return
                }
                withAnimation(.snappy) {
                    selectedStep = destination
                }
            }
    }

    private func createProposal() async {
        guard configuration.canSubmit, let targetStatus = configuration.targetStatus else {
            return
        }
        saveSelectedMeetupCandidate()
        let meetupCandidates = configuration.requiresMeetupBeforeSubmit ? meetupInputsForSubmission : []
        let meetup = meetupCandidates.first
        guard !configuration.requiresMeetupBeforeSubmit || meetup != nil else {
            return
        }
        let draft = ProposalCreateSubmissionDraft(
            receiverID: targetItem.ownerID,
            senderGoodsIDs: orderedSenderGoodsIDs,
            receiverGoodsIDs: resolvedReceiverGoodsIDs,
            exchangeMethod: exchangeMethod,
            conditionTags: orderedConditionTags,
            message: message,
            matchType: matchType,
            status: targetStatus,
            meetupCandidates: meetupCandidates,
            exposeCalendar: shareSchedule,
            listingID: listingID,
            senderCount: orderedSenderGoodsIDs.count,
            receiverCount: resolvedReceiverGoodsIDs.count,
            partnerHandle: partnerHandle,
            methodTitle: Self.methodTitle(exchangeMethod),
            meetupSummary: meetupSummary
        )
        let created = await appState.createProposal(draft.input)
        if created {
            withAnimation(.snappy) {
                submittedSummary = draft.summary
            }
        }
    }

    private func shiftMeetupWeek(_ direction: Int) {
        meetupCalendarAnchorDate = ProposalMeetupCalendarModel.shiftedAnchor(
            anchorDate: meetupCalendarAnchorDate,
            direction: direction
        )
    }

    private func selectMeetupCalendarDay(_ day: Date) {
        meetupCalendarAnchorDate = calendarAnchorDate(for: day)
    }

    private func createMeetupCandidate(day: Date, startSlot: Int, endSlot: Int) {
        let draft = ProposalMeetupCandidateDraft(
            startAt: ProposalMeetupCalendarModel.date(for: day, slot: startSlot),
            endAt: ProposalMeetupCalendarModel.date(for: day, slot: endSlot)
        )
        saveSelectedMeetupCandidate()
        if meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates {
            meetupCandidateDrafts.append(draft)
            applyMeetupCandidate(draft, at: meetupCandidateDrafts.count - 1)
        } else if meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) {
            meetupCandidateDrafts[selectedMeetupCandidateIndex] = draft
            applyMeetupCandidate(draft, at: selectedMeetupCandidateIndex)
        }
    }

    private func updateMeetupCandidate(index: Int, day: Date, startSlot: Int, endSlot: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        let updated = meetupCandidateDrafts[index].applyingCalendarRange(
            day: day,
            startSlot: startSlot,
            endSlot: endSlot
        )
        meetupCandidateDrafts[index] = updated
        if index == selectedMeetupCandidateIndex {
            applyMeetupCandidate(updated, at: index)
        }
    }

    private func calendarAnchorDate(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private static func methodTitle(_ method: ExchangeMethod) -> String {
        switch method {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地 / 郵送"
        }
    }

    private static func dateText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
                .hour()
                .minute()
        )
    }

    private var partnerHandle: String {
        appState.publicProfilesByUserID[targetItem.ownerID]?.profile.handle ?? "相手"
    }

    private var displayPartnerHandle: String {
        visualQAInitialScreen == nil ? partnerHandle : "michilion"
    }
}

private struct ProposalCreateCompletionView: View {
    var summary: ProposalSubmittedSummary
    var onSearchMore: () -> Void
    var onOpenTrades: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            completionCard

            VStack(spacing: 10) {
                ForEach(ProposalCompletionButtonCopy.buttons) { button in
                    Button(action: { perform(button.action) }) {
                        Text(button.title)
                            .font(buttonFont(button.role))
                            .foregroundStyle(buttonForeground(button.role))
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight(button.role))
                            .background(
                                buttonBackgroundColor(button.role),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay {
                                if button.role == .secondary {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .padding(.bottom, 18)
    }

    private func perform(_ action: ProposalCompletionAction) {
        switch action {
        case .searchMore:
            onSearchMore()
        case .openTrades:
            onOpenTrades()
        }
    }

    private func buttonFont(_ role: ProposalCompletionButtonSpec.Role) -> Font {
        switch role {
        case .secondary:
            .system(size: 14, weight: .heavy, design: .rounded)
        case .primary:
            .system(size: 15, weight: .heavy, design: .rounded)
        }
    }

    private func buttonForeground(_ role: ProposalCompletionButtonSpec.Role) -> Color {
        switch role {
        case .secondary:
            MegrumTheme.lavender
        case .primary:
            .white
        }
    }

    private func buttonHeight(_ role: ProposalCompletionButtonSpec.Role) -> CGFloat {
        switch role {
        case .secondary:
            48
        case .primary:
            52
        }
    }

    private func buttonBackgroundColor(_ role: ProposalCompletionButtonSpec.Role) -> Color {
        switch role {
        case .secondary:
            .white
        case .primary:
            MegrumTheme.lavender
        }
    }

    private var completionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(color: MegrumTheme.lavender.opacity(0.08), radius: 14, y: 8)

            decorativeBackground

            VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(width: 78, height: 78)

                Circle()
                    .fill(MegrumTheme.lavender)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: MegrumTheme.lavender.opacity(0.26), radius: 16, y: 8)
            }
            .frame(height: 82)

                VStack(spacing: 12) {
                Text(summary.completionTitle)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .multilineTextAlignment(.center)

                Text(summary.completionMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 58)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 316)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var decorativeBackground: some View {
        ZStack {
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.14))
                .frame(width: 140, height: 140)
                .offset(x: -172, y: -150)
            Circle()
                .fill(MegrumTheme.pink.opacity(0.28))
                .frame(width: 78, height: 78)
                .offset(x: 112, y: -106)
            Circle()
                .fill(MegrumTheme.sky.opacity(0.28))
                .frame(width: 118, height: 118)
                .offset(x: 168, y: 150)
        }
    }
}

private struct ProposalFlowScreenHeader: View {
    var title: String
    var onBack: () -> Void

    var body: some View {
        HStack(spacing: ProposalFlowHeaderMetrics.horizontalSpacing) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: ProposalFlowHeaderMetrics.backChevronSize, weight: .black))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(
                        width: ProposalFlowHeaderMetrics.backButtonSize,
                        height: ProposalFlowHeaderMetrics.backButtonSize
                    )
                    .background(.regularMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.66), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("戻る")

            VStack(alignment: .leading, spacing: 3) {
                Text("PROPOSAL")
                    .font(.system(size: ProposalFlowHeaderMetrics.kickerFontSize, weight: .black, design: .rounded))
                    .tracking(ProposalFlowHeaderMetrics.kickerTracking)
                    .foregroundStyle(MegrumTheme.lavender)
                Text(title)
                    .font(.system(size: ProposalFlowHeaderMetrics.titleFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            Spacer(minLength: 12)
        }
    }
}

private struct ProposalConfirmNoticeCard: View {
    var title: String
    var text: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

            Text(text)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.lavender.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.64), lineWidth: 1)
        }
    }
}

private struct ProposalStepHeader: View {
    @Binding var selectedStep: ProposalCreateStep
    var steps: [ProposalCreateStep]
    var configuration: ProposalCreateConfiguration
    var senderCount: Int
    var receiverCount: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(steps) { step in
                Button {
                    if canJump(to: step) {
                        withAnimation(.snappy) {
                            selectedStep = step
                        }
                    }
                } label: {
                    HStack(spacing: ProposalSectionTabsMetrics.tabGap) {
                        Text(tabTitle(for: step))
                            .font(.system(size: ProposalSectionTabsMetrics.labelFontSize, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(badgeText(for: step))
                            .font(.system(size: ProposalSectionTabsMetrics.countFontSize, weight: .black, design: .rounded))
                            .foregroundStyle(badgeColor(for: step))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        selectedStep == step
                            ? MegrumTheme.ink
                            : MegrumTheme.ink.opacity(0.55)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: ProposalSectionTabsMetrics.minTabHeight)
                    .padding(.horizontal, ProposalSectionTabsMetrics.tabHorizontalPadding)
                    .padding(.vertical, ProposalSectionTabsMetrics.tabVerticalPadding)
                    .background(
                        selectedStep == step ? AnyShapeStyle(Color.white.opacity(0.92)) : AnyShapeStyle(Color.clear),
                        in: Capsule()
                    )
                    .overlay {
                        if selectedStep == step {
                            Capsule()
                                .stroke(Color.white.opacity(0.92), lineWidth: 1)
                        }
                    }
                    .shadow(
                        color: selectedStep == step ? MegrumTheme.ink.opacity(0.13) : .clear,
                        radius: 12,
                        x: 0,
                        y: 5
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canJump(to: step))
                .opacity(canJump(to: step) ? 1 : 0.62)
            }
        }
        .padding(ProposalSectionTabsMetrics.containerPadding)
        .background(Color.white.opacity(0.58), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private func badgeText(for step: ProposalCreateStep) -> String {
        switch step {
        case .give:
            senderCount > 0 ? "\(senderCount)" : "!"
        case .receive:
            receiverCount > 0 ? "\(receiverCount)" : "!"
        case .meetup:
            configuration.targetStatus == nil ? "!" : "OK"
        case .confirm:
            configuration.canSubmit ? "OK" : "!"
        }
    }

    private func badgeColor(for step: ProposalCreateStep) -> Color {
        switch step {
        case .give:
            senderCount > 0 ? MegrumTheme.lavender : MegrumTheme.muted
        case .receive:
            receiverCount > 0 ? MegrumTheme.sky : MegrumTheme.muted
        case .meetup:
            configuration.targetStatus == nil ? MegrumTheme.muted : MegrumTheme.lavender
        case .confirm:
            configuration.canSubmit ? MegrumTheme.lavender : MegrumTheme.muted
        }
    }

    private func tabTitle(for step: ProposalCreateStep) -> String {
        switch step {
        case .give:
            "私が出す"
        case .receive:
            "受け取る"
        case .meetup:
            "待ち合わせ"
        case .confirm:
            "確認"
        }
    }

    private func canJump(to step: ProposalCreateStep) -> Bool {
        guard let targetIndex = steps.firstIndex(of: step) else {
            return false
        }
        let priorSteps = steps.prefix(targetIndex)
        return priorSteps.allSatisfy { configuration.canAdvance(from: $0) }
    }
}

private struct ProposalExchangeMethodSelector: View {
    @Binding var exchangeMethod: ExchangeMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("交換手段")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 0) {
                ForEach(ExchangeMethod.allCases) { method in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            exchangeMethod = method
                        }
                    } label: {
                        Text(method.displayName)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(exchangeMethod == method ? .white : MegrumTheme.ink.opacity(0.48))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                exchangeMethod == method ? MegrumTheme.lavender : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(exchangeMethod == method ? .isSelected : [])
                }
            }
            .padding(3)
            .background(MegrumTheme.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct ProposalGoodsFilterBar: View {
    var groupChoices: [ProposalFilterChoice]
    var goodsTypeChoices: [ProposalFilterChoice]
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: ProposalGoodsFilterMetrics.rowSpacing) {
            ProposalFilterRow(
                title: "推し",
                choices: groupChoices,
                selectedID: $selectedGroupID
            )
            ProposalFilterRow(
                title: "種別",
                choices: goodsTypeChoices,
                selectedID: $selectedGoodsTypeID
            )
        }
    }
}

struct ProposalFilterChoice: Identifiable, Equatable {
    var id: UUID
    var title: String
}

private struct ProposalFilterRow: View {
    var title: String
    var choices: [ProposalFilterChoice]
    @Binding var selectedID: UUID?

    var body: some View {
        if !choices.isEmpty {
            HStack(alignment: .center, spacing: ProposalGoodsFilterMetrics.chipSpacing) {
                Text(title)
                    .font(.system(size: ProposalGoodsFilterMetrics.labelFontSize, weight: .black, design: .rounded))
                    .tracking(ProposalGoodsFilterMetrics.labelTracking)
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: ProposalGoodsFilterMetrics.labelWidth, alignment: .trailing)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ProposalGoodsFilterMetrics.chipSpacing) {
                        ProposalFilterChip(title: "すべて", isSelected: selectedID == nil) {
                            selectedID = nil
                        }
                        ForEach(choices) { choice in
                            ProposalFilterChip(title: choice.title, isSelected: selectedID == choice.id) {
                                selectedID = choice.id
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }
}

private struct ProposalFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: ProposalGoodsFilterMetrics.chipFontSize, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, ProposalGoodsFilterMetrics.chipHorizontalPadding)
                .padding(.vertical, ProposalGoodsFilterMetrics.chipVerticalPadding)
                .background(isSelected ? MegrumTheme.lavender : Color.white.opacity(0.74), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? MegrumTheme.lavender.opacity(0.5) : .white.opacity(0.68), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ProposalSelectableGoodsRow: View {
    var item: GoodsItem
    var isSelected: Bool
    var hintText: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ProposalSelectableGoodsRowMetrics.rowSpacing) {
                RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.thumbnailCornerRadius, style: .continuous)
                    .fill(ProposalSelectableGoodsRowStyle.thumbnailColor(for: item))
                    .frame(
                        width: ProposalSelectableGoodsRowMetrics.thumbnailWidth,
                        height: ProposalSelectableGoodsRowMetrics.thumbnailHeight
                    )
                    .overlay {
                        if let imageURL = item.imageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(.white)
                                case .empty:
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: ProposalSelectableGoodsRowMetrics.thumbnailCornerRadius,
                                    style: .continuous
                                )
                            )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.25))
                                    .frame(
                                        width: ProposalSelectableGoodsRowMetrics.thumbnailShineSize,
                                        height: ProposalSelectableGoodsRowMetrics.thumbnailShineSize
                                    )
                                    .offset(
                                        x: ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetX,
                                        y: ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetY
                                    )
                                Text(ProposalSelectableGoodsRowStyle.glyph(for: item))
                                    .font(.system(size: ProposalSelectableGoodsRowMetrics.glyphFontSize, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                    }

                VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                    if !subtitleText.isEmpty {
                        Text(subtitleText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                    }
                    Text(hintText)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.sky)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(MegrumTheme.sky.opacity(0.22), in: Capsule())
                }

                Spacer()

                ProposalSelectableGoodsCheckmark(isSelected: isSelected)
            }
            .padding(ProposalSelectableGoodsRowMetrics.rowPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                rowBackground,
                in: RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous)
                    .stroke(rowBorderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue(isSelected ? "選択中" : "未選択")
    }

    private var subtitleText: String {
        item.tags.map(\.name).prefix(2).joined(separator: " / ")
    }

    private var rowBackground: Color {
        isSelected ? MegrumTheme.lavender.opacity(ProposalSelectableGoodsRowMetrics.selectedBackgroundOpacity) : .white
    }

    private var rowBorderColor: Color {
        isSelected
            ? MegrumTheme.lavender.opacity(ProposalSelectableGoodsRowMetrics.selectedBorderOpacity)
            : MegrumTheme.ink.opacity(ProposalSelectableGoodsRowMetrics.defaultBorderOpacity)
    }
}

private struct ProposalSelectableGoodsCheckmark: View {
    var isSelected: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? MegrumTheme.lavender : Color.clear)
            .frame(
                width: ProposalSelectableGoodsRowMetrics.checkCircleSize,
                height: ProposalSelectableGoodsRowMetrics.checkCircleSize
            )
            .overlay {
                Circle()
                    .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.16), lineWidth: 1)
            }
            .overlay {
                if isSelected {
                    Text("✓")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
    }
}

enum ProposalSelectableGoodsRowStyle {
    static func glyph(for item: GoodsItem) -> String {
        if item.title.contains("カリナ") {
            return "K"
        }
        if item.title.contains("ジョンウ") {
            return "J"
        }
        if item.title.contains("スア") {
            return "S"
        }
        if item.title.contains("ニンニン") {
            return "N"
        }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func thumbnailColor(for item: GoodsItem) -> Color {
        if item.title.contains("ジョンウ") || item.title.contains("ニンニン") {
            return MegrumTheme.sky.opacity(0.72)
        }
        if item.title.contains("スア") {
            return MegrumTheme.lavender.opacity(0.64)
        }
        return MegrumTheme.pink.opacity(0.68)
    }
}

private struct ProposalReceiveCard: View {
    var targetItem: GoodsItem
    var receiverGoodsCount: Int
    var isListingSource: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MegrumTheme.sky.opacity(0.24))
                    .frame(width: 76, height: 90)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(targetItem.title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(2)
                    Text(isListingSource ? "個別募集から選択" : "相手の在庫から選択")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    if receiverGoodsCount > 1 {
                        Text("ほか\(receiverGoodsCount - 1)件も条件に含まれます")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
            }

            Label("受け取る内容はこのステップで固定されています", systemImage: "lock.fill")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.68), lineWidth: 1)
        }
    }
}

private struct ProposalCardSection<Content: View>: View {
    var title: String
    var rightText: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 0)
                if let rightText, !rightText.isEmpty {
                    Text(rightText)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            content
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
    }
}

private struct ProposalConfirmSection<Content: View>: View {
    var title: String
    var rightText: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 0)
                if let rightText, !rightText.isEmpty {
                    Text(rightText)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            content
        }
    }
}

private struct ProposalMeetupCandidatePicker: View {
    var drafts: [ProposalMeetupCandidateDraft]
    var selectedIndex: Int
    var canAdd: Bool
    var onSelect: (Int) -> Void
    var onAdd: () -> Void
    var onRemove: (Int) -> Void

    var body: some View {
        ProposalCardSection(title: "候補選択") {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(drafts.enumerated()), id: \.offset) { index, draft in
                            ProposalMeetupCandidateButton(
                                index: index,
                                draft: draft,
                                isSelected: selectedIndex == index,
                                canRemove: drafts.count > 1,
                                onSelect: {
                                    onSelect(index)
                                },
                                onRemove: {
                                    onRemove(index)
                                }
                            )
                        }

                        Button(action: onAdd) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24, weight: .bold))
                                Text("候補を追加")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(canAdd ? MegrumTheme.lavender : MegrumTheme.muted)
                            .frame(width: 128)
                            .frame(minHeight: 108)
                            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                    .foregroundStyle(MegrumTheme.lavender.opacity(canAdd ? 0.42 : 0.18))
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!canAdd)
                        .accessibilityLabel("待ち合わせ候補を追加")
                    }
                    .padding(.vertical, 2)
                }

                Text("候補は最大3件まで保存できます。今選んでいる候補が送信内容に反映されます。")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ProposalMeetupCandidateButton: View {
    var index: Int
    var draft: ProposalMeetupCandidateDraft
    var isSelected: Bool
    var canRemove: Bool
    var onSelect: () -> Void
    var onRemove: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .heavy))
                    Text("候補\(index + 1)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
                .foregroundStyle(titleColor)

                Text(draft.summary(index: index))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)

                Text(draft.isValid ? "送信可" : "未入力")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(draft.isValid ? MegrumTheme.ok : MegrumTheme.muted)
            }
            .padding(12)
            .frame(width: 178, alignment: .topLeading)
            .frame(minHeight: 108, alignment: .topLeading)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if canRemove {
                Button(role: .destructive, action: onRemove) {
                    Label("候補を削除", systemImage: "trash")
                }
            }
        }
    }

    private var iconName: String {
        isSelected ? "checkmark.circle.fill" : "circle"
    }

    private var titleColor: Color {
        isSelected ? MegrumTheme.lavender : MegrumTheme.muted
    }

    private var backgroundColor: Color {
        isSelected ? MegrumTheme.lavender.opacity(0.12) : Color.white.opacity(0.7)
    }

    private var borderColor: Color {
        isSelected ? MegrumTheme.lavender.opacity(0.52) : Color.white.opacity(0.68)
    }
}

private struct ProposalScheduleBackgroundSection: View {
    var context: ProposalScheduleContext
    var selectedStartAt: Date
    @State private var mode: ProposalScheduleCalendarMode = .fiveDays

    private let calendar = Calendar.current

    var body: some View {
        ProposalCardSection(title: "スケジュール背景") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("表示", selection: $mode) {
                    ForEach(ProposalScheduleCalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ProposalScheduleLegend()

                if context.schedules.isEmpty {
                    ContentUnavailableView(
                        "予定なし",
                        systemImage: "calendar",
                        description: Text("読み込める予定はありません。")
                    )
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                } else {
                    if !context.selectedOverlaps.isEmpty {
                        ProposalSelectedScheduleOverlapBanner(context: context)
                    }

                    switch mode {
                    case .fiveDays:
                        VStack(spacing: 8) {
                            ForEach(context.visibleDays(anchorDate: selectedStartAt, mode: .fiveDays, calendar: calendar), id: \.self) { day in
                                ProposalScheduleDayStrip(
                                    day: day,
                                    schedules: context.schedules(on: day, calendar: calendar),
                                    context: context
                                )
                            }
                        }
                    case .month:
                        ProposalScheduleMonthGrid(context: context, anchorDate: selectedStartAt)
                    }
                }
            }
        }
    }
}

private struct ProposalSelectedScheduleOverlapBanner: View {
    var context: ProposalScheduleContext

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("選択中の時間に予定があります", systemImage: "calendar.badge.exclamationmark")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)

            ForEach(context.selectedOverlaps.prefix(2)) { schedule in
                Text("\(context.roleText(for: schedule))：\(schedule.title)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.lavender.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProposalScheduleLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem(title: "あなた", color: MegrumTheme.lavender)
            legendItem(title: "相手", color: MegrumTheme.sky)
            Spacer()
        }
        .font(.system(size: 12, weight: .heavy, design: .rounded))
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private struct ProposalScheduleDayStrip: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var context: ProposalScheduleContext

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(day.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(day.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
            .frame(width: 62, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if schedules.isEmpty {
                    Text("予定なし")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.vertical, 5)
                } else {
                    ForEach(schedules.prefix(3)) { schedule in
                        ProposalScheduleMiniRow(schedule: schedule, isMine: context.isMine(schedule))
                    }
                    if schedules.count > 3 {
                        Text("ほか\(schedules.count - 3)件")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProposalScheduleMiniRow: View {
    var schedule: PersonalSchedule
    var isMine: Bool

    private var color: Color {
        isMine ? MegrumTheme.lavender : MegrumTheme.sky
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(timeRangeText)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 72, alignment: .leading)

            Text(schedule.title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)

            if let placeName = schedule.placeName {
                Text(placeName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }
        }
    }

    private var timeRangeText: String {
        if schedule.allDay {
            return "終日"
        }
        let start = schedule.startAt.formatted(.dateTime.hour().minute())
        let end = schedule.endAt.formatted(.dateTime.hour().minute())
        return "\(start)-\(end)"
    }
}

private struct ProposalScheduleMonthGrid: View {
    var context: ProposalScheduleContext
    var anchorDate: Date

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(anchorDate.formatted(.dateTime.year().month(.wide)))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 6) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthGridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let schedules = context.schedules(on: day, calendar: calendar)
                        ProposalScheduleMonthCell(
                            day: day,
                            schedules: schedules,
                            isToday: calendar.isDateInToday(day),
                            context: context
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }

    private var monthGridDays: [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = (calendar.component(.weekday, from: month.start) + 6) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }
}

private struct ProposalScheduleMonthCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var context: ProposalScheduleContext

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(isToday ? .white : MegrumTheme.ink)
                .frame(width: 22, height: 22)
                .background(isToday ? MegrumTheme.lavender : Color.clear, in: Circle())

            HStack(spacing: 3) {
                ForEach(schedules.prefix(3)) { schedule in
                    Circle()
                        .fill(context.isMine(schedule) ? MegrumTheme.lavender : MegrumTheme.sky)
                        .frame(width: 5, height: 5)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        .padding(5)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ProposalFlowMeetupForm: View {
    private enum Field: Hashable {
        case place
    }

    @Binding var startAt: Date
    @Binding var endAt: Date
    @Binding var placeName: String
    @Binding var latitudeText: String
    @Binding var longitudeText: String
    var isRequestingLocation: Bool
    var locationErrorMessage: String?
    var placeSuggestions: [String]
    var focusPlaceFieldRequest: Int
    @State private var cameraPosition: MapCameraPosition = .region(Self.fallbackRegion)
    @FocusState private var focusedField: Field?

    private static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    private static let mapSpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    private static let fallbackRegion = MKCoordinateRegion(center: fallbackCoordinate, span: mapSpan)

    private var selectedCoordinate: CLLocationCoordinate2D? {
        ProposalMeetupMapDraft.coordinate(latitudeText: latitudeText, longitudeText: longitudeText)?.clLocationCoordinate
    }

    var body: some View {
        ProposalCardSection(title: "待ち合わせ候補") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 0) {
                    DatePicker("開始日時", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                        .proposalFlowMeetupRow()
                    Divider()
                    DatePicker("終了日時", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                        .proposalFlowMeetupRow()
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 12)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Label("地図で場所を選択", systemImage: "map")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    MapReader { proxy in
                        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                            if let selectedCoordinate {
                                Marker(placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "待ち合わせ" : placeName, coordinate: selectedCoordinate)
                                    .tint(MegrumTheme.lavender)
                            }
                        }
                        .frame(height: 184)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        }
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    guard let coordinate = proxy.convert(value.location, from: .local) else {
                                        return
                                    }
                                    applyMapSelection(coordinate)
                                }
                        )
                    }

                    VStack(spacing: 0) {
                        TextField("場所名", text: $placeName)
                            .focused($focusedField, equals: .place)
                            .proposalFlowMeetupRow()
                        Divider()
                        HStack(spacing: 12) {
                            TextField("緯度", text: $latitudeText)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                            TextField("経度", text: $longitudeText)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                        }
                        .proposalFlowMeetupRow()
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 12)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if !placeSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("予定から場所を反映")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(placeSuggestions, id: \.self) { suggestion in
                                        Button {
                                            placeName = suggestion
                                        } label: {
                                            Text(suggestion)
                                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                                .lineLimit(1)
                                                .foregroundStyle(MegrumTheme.ink)
                                                .padding(.horizontal, 11)
                                                .frame(height: 34)
                                                .background(.white.opacity(0.72), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    if isRequestingLocation {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(locationErrorMessage ?? "現在地が使える場合は緯度経度を自動入力します。")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .onAppear {
            syncCameraToSelectedCoordinate(animated: false)
        }
        .onChange(of: latitudeText) { _, _ in
            syncCameraToSelectedCoordinate(animated: true)
        }
        .onChange(of: longitudeText) { _, _ in
            syncCameraToSelectedCoordinate(animated: true)
        }
        .onChange(of: focusPlaceFieldRequest) { _, _ in
            focusedField = .place
        }
    }

    private func applyMapSelection(_ coordinate: CLLocationCoordinate2D) {
        guard ProposalMeetupMapDraft.isValid(latitude: coordinate.latitude, longitude: coordinate.longitude) else {
            return
        }
        latitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        longitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.longitude)
        let trimmedPlaceName = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPlaceName.isEmpty || trimmedPlaceName == "現在地" {
            placeName = ProposalMeetupMapDraft.fallbackPlaceName
        }
        withAnimation(.smooth(duration: 0.18)) {
            cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: Self.mapSpan))
        }
    }

    private func syncCameraToSelectedCoordinate(animated: Bool) {
        guard let selectedCoordinate else {
            return
        }
        let region = MKCoordinateRegion(center: selectedCoordinate, span: Self.mapSpan)
        if animated {
            withAnimation(.smooth(duration: 0.18)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
}

private struct ProposalTagGrid: View {
    var tags: [String]
    @Binding var selectedTags: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("打診の条件として相手に伝えたいものを選べます。")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if tags.isEmpty {
                Text("この方法で使えるタグはありません")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 7)], spacing: 7) {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        } label: {
                            Text(tag)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .foregroundStyle(selectedTags.contains(tag) ? MegrumTheme.lavender : MegrumTheme.ink)
                                .padding(.horizontal, 8)
                                .frame(height: 32)
                                .background(
                                    selectedTags.contains(tag) ? AnyShapeStyle(MegrumTheme.lavender.opacity(0.16)) : AnyShapeStyle(MegrumTheme.ink.opacity(0.05)),
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(selectedTags.contains(tag) ? MegrumTheme.lavender.opacity(0.42) : MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct ProposalScheduleShareCard: View {
    @Binding var shareSchedule: Bool

    var body: some View {
        HStack(spacing: ProposalScheduleShareMetrics.cardGap) {
            VStack(alignment: .leading, spacing: ProposalScheduleShareMetrics.statusTopSpacing) {
                Text("スケジュールを共有する")
                    .font(.system(size: ProposalScheduleShareMetrics.titleFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(shareSchedule ? "ON" : "OFF")
                    .font(.system(size: ProposalScheduleShareMetrics.statusFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(shareSchedule ? MegrumTheme.lavender : MegrumTheme.muted)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $shareSchedule)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(ProposalScheduleShareMetrics.cardPadding)
        .background(
            shareSchedule ? MegrumTheme.lavender.opacity(ProposalScheduleShareMetrics.activeBackgroundOpacity) : Color.white,
            in: RoundedRectangle(cornerRadius: ProposalScheduleShareMetrics.cardCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: ProposalScheduleShareMetrics.cardCornerRadius, style: .continuous)
                .stroke(
                    shareSchedule
                        ? MegrumTheme.lavender.opacity(ProposalScheduleShareMetrics.activeBorderOpacity)
                        : MegrumTheme.ink.opacity(ProposalScheduleShareMetrics.inactiveBorderOpacity),
                    lineWidth: 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: ProposalScheduleShareMetrics.cardCornerRadius, style: .continuous))
        .onTapGesture {
            shareSchedule.toggle()
        }
    }
}

private struct ProposalConfirmSummary: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var methodTitle: String
    var meetupSummary: String
    var conditionTags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProposalExchangePreviewRow(
                senderGoods: senderGoods,
                receiverGoods: receiverGoods
            )
            ProposalSummaryRow(title: "交換方法", value: methodTitle)
            ProposalSummaryRow(title: "待ち合わせ", value: meetupSummary)
            if !conditionTags.isEmpty {
                ProposalSummaryRow(title: "条件タグ", value: conditionTags.joined(separator: " / "))
            }
        }
        .padding(16)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.68), lineWidth: 1)
        }
    }
}

private struct ProposalConfirmMeetupCandidatesCard: View {
    var candidates: [ProposalMeetupInput]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ProposalCardSection(title: ProposalConfirmSectionCopy.meetupCandidatesTitle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("待ち合わせ候補")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Text("\(candidates.count)件")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                }

                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    ForEach(Array(candidates.enumerated()), id: \.offset) { index, candidate in
                        Marker("候補\(index + 1)", coordinate: CLLocationCoordinate2D(latitude: candidate.latitude, longitude: candidate.longitude))
                            .tint(index == 0 ? MegrumTheme.lavender : MegrumTheme.sky)
                    }
                }
                .frame(height: 204)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.7), lineWidth: 1)
                }

                VStack(spacing: 10) {
                    ForEach(Array(candidates.enumerated()), id: \.offset) { index, candidate in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(index == 0 ? MegrumTheme.lavender : MegrumTheme.sky, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(timeText(for: candidate))
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .lineLimit(1)
                                Text(candidate.normalizedPlaceName)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.muted)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .onAppear {
            syncCameraPosition()
        }
        .onChange(of: candidates) { _, _ in
            syncCameraPosition()
        }
    }

    private func timeText(for candidate: ProposalMeetupInput) -> String {
        let start = candidate.startAt.formatted(.dateTime.locale(Locale(identifier: "ja_JP")).month().day().hour().minute())
        let end = candidate.endAt.formatted(.dateTime.hour().minute())
        return "\(start) - \(end)"
    }

    private func syncCameraPosition() {
        guard !candidates.isEmpty else {
            cameraPosition = .automatic
            return
        }
        if candidates.count == 1 {
            let candidate = candidates[0]
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: candidate.latitude, longitude: candidate.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                )
            )
            return
        }

        let latitudes = candidates.map(\.latitude)
        let longitudes = candidates.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (latitudes.min()! + latitudes.max()!) / 2,
            longitude: (longitudes.min()! + longitudes.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (latitudes.max()! - latitudes.min()!) * 1.8),
            longitudeDelta: max(0.01, (longitudes.max()! - longitudes.min()!) * 1.8)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

private struct ProposalExchangePreviewRow: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            ProposalPreviewSide(title: "相手の譲", goods: receiverGoods)
            VStack(spacing: 4) {
                ProposalArrowDot(symbolName: "arrow.right", color: MegrumTheme.lavender)
                ProposalArrowDot(symbolName: "arrow.left", color: MegrumTheme.sky)
            }
            .padding(.top, 24)
            ProposalPreviewSide(title: "あなたの譲", goods: senderGoods, alignRight: true, isMine: true)
        }
        .padding(10)
        .background(MegrumTheme.sky.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProposalPreviewSide: View {
    var title: String
    var goods: [GoodsItem]
    var alignRight = false
    var isMine = false

    var body: some View {
        VStack(alignment: alignRight ? .trailing : .leading, spacing: 8) {
            Text("\(title)（\(goods.count)）")
                .font(.system(size: 10.5, weight: .black, design: .rounded))
                .foregroundStyle(isMine ? MegrumTheme.lavender : MegrumTheme.sky)
            LazyVGrid(
                columns: ProposalExchangePreviewMetrics.thumbGridColumns,
                alignment: alignRight ? .trailing : .leading,
                spacing: ProposalExchangePreviewMetrics.thumbSpacing
            ) {
                ForEach(goods.prefix(4)) { item in
                    ProposalPreviewThumb(item: item)
                }
            }
            .frame(maxWidth: .infinity, alignment: alignRight ? .trailing : .leading)
        }
        .padding(9)
        .frame(minHeight: 108, alignment: .top)
        .frame(maxWidth: .infinity)
        .background((isMine ? MegrumTheme.pink : Color.white).opacity(isMine ? 0.08 : 0.9), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct ProposalArrowDot: View {
    var symbolName: String
    var color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay {
                Image(systemName: symbolName)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
            }
    }
}

private struct ProposalPreviewThumb: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.14))
            .frame(width: 44, height: 44)
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallback
                        case .empty:
                            ProgressView()
                                .controlSize(.small)
                                .tint(MegrumTheme.lavender)
                        @unknown default:
                            fallback
                        }
                    }
                } else {
                    fallback
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(.white.opacity(0.8), lineWidth: 1)
            }
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 30, height: 30)
                .offset(x: -11, y: -12)
            Text(ProposalPreviewGlyphResolver.glyph(for: item.title))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
    }
}

enum ProposalPreviewGlyphResolver {
    static func glyph(for title: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.contains("カリナ") {
            return "K"
        }
        if trimmedTitle.contains("ジョンウ") {
            return "J"
        }
        if trimmedTitle.contains("スア") {
            return "S"
        }
        if trimmedTitle.contains("ニンニン") {
            return "N"
        }
        guard let firstCharacter = trimmedTitle.first else {
            return "?"
        }
        return String(firstCharacter)
    }
}

private struct ProposalConfirmMethodCard: View {
    var exchangeMethod: ExchangeMethod
    var mailingAddress: MailingAddress?
    var isLoadingMailingAddress: Bool
    var onOpenAddressSettings: () -> Void

    var body: some View {
        ProposalConfirmSection(title: "受け渡し方法") {
            VStack(alignment: .leading, spacing: 12) {
                Text(exchangeMethod.displayName)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

                Text(methodDescription)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if exchangeMethod == .mail || exchangeMethod == .both {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("あなたの住所登録")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        if isLoadingMailingAddress {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("確認中")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        } else if let mailingAddress {
                            Text(mailingAddress.summary)
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            HStack(spacing: 10) {
                                Text("未登録")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.red)
                                Spacer()
                                Button(action: onOpenAddressSettings) {
                                    Text("登録する")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .frame(height: 32)
                                        .background(MegrumTheme.lavender, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var iconName: String {
        switch exchangeMethod {
        case .hand:
            "figure.wave"
        case .mail:
            "shippingbox"
        case .both:
            "arrow.triangle.2.circlepath"
        }
    }

    private var methodDescription: String {
        switch exchangeMethod {
        case .hand:
            return "現地交換では、待ち合わせ候補と場所を相手に送ります。"
        case .mail:
            return "郵送交換では、待ち合わせ候補は送りません。合意後にだけ当事者へ住所を表示します。"
        case .both:
            return "現地交換の候補と、郵送に使う住所登録の両方を確認します。合意後にだけ当事者へ住所を表示します。"
        }
    }
}

private struct ProposalSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 92, alignment: .leading)
            Text(value.isEmpty ? "未選択" : value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}

private struct ProposalFlowBottomBar: View {
    var selectedStep: ProposalCreateStep
    var configuration: ProposalCreateConfiguration
    var meetupHasTimeDraft: Bool
    var isCreating: Bool
    var isInline = false
    var onPrimary: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrimary) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryTitle)
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: ProposalFlowBottomBarMetrics.buttonMinHeight)
                .background(
                    MegrumTheme.lavender,
                    in: RoundedRectangle(cornerRadius: ProposalFlowBottomBarMetrics.buttonCornerRadius, style: .continuous)
                )
                .shadow(color: MegrumTheme.lavender.opacity(canUsePrimary ? 0.28 : 0), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canUsePrimary)
            .opacity(canUsePrimary ? 1 : 0.48)
        }
        .padding(.horizontal, isInline ? 0 : ProposalFlowBottomBarMetrics.horizontalPadding)
        .padding(.top, isInline ? ProposalFlowBottomBarMetrics.inlineTopPadding : ProposalFlowBottomBarMetrics.topPadding)
        .padding(.bottom, isInline ? ProposalFlowBottomBarMetrics.inlineBottomPadding : ProposalFlowBottomBarMetrics.bottomPadding)
        .background(background)
    }

    private var canUsePrimary: Bool {
        configuration.canAdvance(from: selectedStep)
    }

    private var primaryTitle: String {
        ProposalCreateBottomBarCopy.primaryTitle(
            selectedStep: selectedStep,
            configuration: configuration,
            meetupHasTimeDraft: meetupHasTimeDraft
        )
    }

    @ViewBuilder
    private var background: some View {
        if isInline {
            Color.clear
        } else {
            MegrumTheme.canvas.ignoresSafeArea(edges: .bottom)
        }
    }
}

private extension View {
    func proposalFlowMeetupRow() -> some View {
        self
            .frame(minHeight: 48)
            .padding(.vertical, 6)
    }
}
