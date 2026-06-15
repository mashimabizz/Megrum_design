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

    static func showsHeaderKicker(for step: ProposalCreateStep) -> Bool {
        step != .confirm
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
    case meetupCandidates
    case message
    case scheduleShare

    var id: String { rawValue }

    static func visibleOrder(requiresMeetupBeforeSubmit: Bool) -> [ProposalConfirmSectionKind] {
        [
            .exchangeContent,
            .method,
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
    var cashAmount: Int? = nil
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
            cashAmount: cashAmount
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
    static let maxCandidates = 5
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
        if draft.latitudeText.isBlank {
            draft.latitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        }
        if draft.longitudeText.isBlank {
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
            hasSelectedSenderGoods || hasCashOffer
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
