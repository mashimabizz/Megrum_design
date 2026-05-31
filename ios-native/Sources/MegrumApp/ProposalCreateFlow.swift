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
    var methodTitle: String
    var meetupSummary: String
    var conditionTags: [String]

    var detailText: String {
        let goodsText = "\(senderCount)件を提示 / \(receiverCount)件を受け取り候補"
        if conditionTags.isEmpty {
            return "\(goodsText)で送信しました。"
        }
        return "\(goodsText)・\(conditionTags.joined(separator: " / "))"
    }
}

enum ProposalCompletionAction: Equatable {
    case searchMore
    case openTrades
}

struct ProposalCandidateGridMetrics {
    static let minimumCardWidth: CGFloat = 156
    static let spacing: CGFloat = 10

    static var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: minimumCardWidth), spacing: spacing)]
    }

    static func estimatedColumnCount(containerWidth: CGFloat) -> Int {
        guard containerWidth > 0 else {
            return 1
        }
        return max(1, Int((containerWidth + spacing) / (minimumCardWidth + spacing)))
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
    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]?
    var initialSenderGoodsIDs: [UUID] = []
    var matchType: ProposalMatchType = .perfect
    var initialStep: ProposalCreateStep = .give
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
    @State private var meetupCandidateDrafts: [ProposalMeetupCandidateDraft] = [ProposalMeetupCandidateDraft()]
    @State private var selectedMeetupCandidateIndex = 0
    @State private var submittedSummary: ProposalSubmittedSummary?
    @State private var didApplyInitialStep = false
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

    private var selectableSenderGoods: [GoodsItem] {
        MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
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

    private var filteredReceiverGoods: [GoodsItem] {
        receiverChoiceGoods.filter { item in
            (receiverGroupFilterID == nil || item.groupID == receiverGroupFilterID)
                && (receiverGoodsTypeFilterID == nil || item.goodsTypeID == receiverGoodsTypeFilterID)
        }
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
        selectedMeetupCandidateDraft.meetupInput
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
                ) {
                    dismiss()
                }
            } else {
                VStack(spacing: 0) {
                    ProposalStepHeader(
                        selectedStep: $selectedStep,
                        steps: visibleSteps,
                        configuration: configuration,
                        senderCount: orderedSenderGoodsIDs.count,
                        receiverCount: resolvedReceiverGoodsIDs.count
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                    Divider()
                        .overlay(MegrumTheme.lavender.opacity(0.12))

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            ProposalScreenTitle(
                                step: selectedStep,
                                targetItem: targetItem,
                                steps: visibleSteps
                            )

                            ProposalExchangeMethodSelector(
                                exchangeMethod: $exchangeMethod
                            )

                            switch selectedStep {
                            case .give:
                                giveStep
                            case .receive:
                                receiveStep
                            case .meetup:
                                meetupStep
                            case .confirm:
                                confirmStep
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 104)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if submittedSummary == nil {
                ProposalFlowBottomBar(
                    selectedStep: selectedStep,
                    configuration: configuration,
                    isCreating: appState.isCreatingProposal,
                    onBack: previousStep,
                    onPrimary: primaryAction
                )
            }
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle(submittedSummary == nil ? "打診作成" : "送信完了")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(submittedSummary == nil ? "閉じる" : "完了") {
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled(appState.isCreatingProposal)
        .onAppear {
            seedDefaultSenderSelection()
            seedDefaultReceiverSelection()
            normalizeMeetupEnd()
            applyInitialStepIfNeeded()
            requestLocationIfNeeded()
        }
        .task(id: targetItem.ownerID) {
            await appState.loadPublicExchangeContent(userID: targetItem.ownerID)
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
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
            requestLocationIfNeeded()
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
        VStack(alignment: .leading, spacing: 14) {
            ProposalStepLead(
                symbolName: "shippingbox.fill",
                title: "あなたが出すグッズを選ぶ",
                text: "複数選択できます。相手に見せる提示物として送信されます。"
            )

            ProposalGoodsFilterBar(
                groups: appState.oshiGroups,
                goodsTypes: appState.goodsTypes,
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
                LazyVGrid(columns: ProposalCandidateGridMetrics.adaptiveColumns, spacing: ProposalCandidateGridMetrics.spacing) {
                    ForEach(filteredSenderGoods) { item in
                        ProposalSelectableGoodsCompactCard(
                            item: item,
                            isSelected: selectedSenderGoodsIDs.contains(item.id),
                            badgeText: selectedSenderGoodsIDs.contains(item.id) ? "選択中" : nil
                        ) {
                            toggleSenderGoods(item.id)
                        }
                    }
                }
            }
        }
    }

    private var receiveStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProposalStepLead(
                symbolName: "sparkles",
                title: "受け取るグッズを選ぶ",
                text: listingID == nil
                    ? "相手の譲る在庫から、今回受け取りたいものを選びます。"
                    : "個別募集で候補になった相手のグッズを確認し、必要なら調整できます。"
            )

            ProposalGoodsFilterBar(
                groups: appState.oshiGroups,
                goodsTypes: appState.goodsTypes,
                selectedGroupID: $receiverGroupFilterID,
                selectedGoodsTypeID: $receiverGoodsTypeFilterID
            )

            LazyVGrid(columns: ProposalCandidateGridMetrics.adaptiveColumns, spacing: ProposalCandidateGridMetrics.spacing) {
                ForEach(filteredReceiverGoods) { item in
                    ProposalSelectableGoodsCompactCard(
                        item: item,
                        isSelected: selectedReceiverGoodsIDs.contains(item.id),
                        badgeText: selectedReceiverGoodsIDs.contains(item.id) ? "選択中" : nil
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
            ProposalStepLead(
                symbolName: "mappin.and.ellipse",
                title: "会う場所と時間を決める",
                text: "現地交換では、送信前に待ち合わせ候補まで入れておきます。"
            )

            if configuration.requiresMeetupBeforeSubmit {
                ProposalMeetupCandidatePicker(
                    drafts: displayMeetupCandidateDrafts,
                    selectedIndex: selectedMeetupCandidateIndex,
                    canAdd: meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates,
                    onSelect: selectMeetupCandidate,
                    onAdd: addMeetupCandidate,
                    onRemove: removeMeetupCandidate
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
                    placeSuggestions: proposalScheduleContext.placeSuggestions
                )
            }

        }
    }

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProposalStepLead(
                symbolName: "checkmark.seal.fill",
                title: "送信前の確認",
                text: "出すもの、受け取るもの、待ち合わせを確認してから打診します。"
            )

            ProposalConfirmSummary(
                senderGoods: selectedSenderGoods,
                receiverGoods: selectedReceiverGoods,
                methodTitle: Self.methodTitle(exchangeMethod),
                meetupSummary: meetupSummary,
                conditionTags: orderedConditionTags
            )

            ProposalConfirmMethodCard(
                exchangeMethod: exchangeMethod,
                mailingAddress: appState.mailingAddress,
                isLoadingMailingAddress: appState.isLoadingMailingAddress,
                onOpenAddressSettings: {
                    showsAddressSettings = true
                }
            )

            ProposalCardSection(title: "交換条件タグ") {
                ProposalTagGrid(tags: conditionTagOptions, selectedTags: $selectedConditionTags)
            }

            if configuration.requiresMeetupBeforeSubmit {
                ProposalCardSection(title: "スケジュール共有") {
                    Toggle(isOn: $shareSchedule) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("相手に自分の予定を共有する")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                            Text("待ち合わせ調整に使います。送信後も取引チャットで確認できます。")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .toggleStyle(.switch)
                }
            }

            ProposalCardSection(title: "メッセージ") {
                TextField("よろしくお願いします", text: $message, axis: .vertical)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(3...6)
                    .padding(14)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        guard configuration.canAdvance(from: selectedStep),
              let index = visibleSteps.firstIndex(of: selectedStep),
              visibleSteps.indices.contains(index + 1)
        else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = visibleSteps[index + 1]
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
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let created = await appState.createProposal(
            ProposalCreateInput(
                receiverID: targetItem.ownerID,
                senderGoodsIDs: orderedSenderGoodsIDs,
                receiverGoodsIDs: resolvedReceiverGoodsIDs,
                exchangeMethod: exchangeMethod,
                conditionTags: orderedConditionTags,
                message: trimmedMessage.isEmpty ? nil : trimmedMessage,
                matchType: matchType,
                status: targetStatus,
                meetup: meetup,
                meetupCandidates: meetupCandidates,
                exposeCalendar: shareSchedule,
                listingID: listingID
            )
        )
        if created {
            let summary = ProposalSubmittedSummary(
                senderCount: orderedSenderGoodsIDs.count,
                receiverCount: resolvedReceiverGoodsIDs.count,
                methodTitle: Self.methodTitle(exchangeMethod),
                meetupSummary: meetupSummary,
                conditionTags: orderedConditionTags
            )
            withAnimation(.snappy) {
                submittedSummary = summary
            }
        }
    }

    private func requestLocationIfNeeded() {
        guard configuration.requiresMeetupBeforeSubmit else {
            return
        }
        locationState.requestCurrentLocation()
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
}

private struct ProposalCreateCompletionView: View {
    var summary: ProposalSubmittedSummary
    var onSearchMore: () -> Void
    var onOpenTrades: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 42)

            Image(systemName: "paperplane.circle.fill")
                .font(.system(size: 82, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 10) {
                Text("打診を送信しました")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .multilineTextAlignment(.center)

                Text(summary.detailText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ProposalSummaryRow(title: "交換方法", value: summary.methodTitle)
                ProposalSummaryRow(title: "待ち合わせ", value: summary.meetupSummary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.62), lineWidth: 1)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: onOpenTrades) {
                    Text("打診一覧に飛ぶ")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 14, y: 8)
                }
                .buttonStyle(.plain)

                Button(action: onSearchMore) {
                    Text("まだ他に探す")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.66), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button(action: onClose) {
                    Text("閉じる")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
    }
}

private struct ProposalStepHeader: View {
    @Binding var selectedStep: ProposalCreateStep
    var steps: [ProposalCreateStep]
    var configuration: ProposalCreateConfiguration
    var senderCount: Int
    var receiverCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(steps) { step in
                    Button {
                        if canJump(to: step) {
                            withAnimation(.snappy) {
                                selectedStep = step
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: step.symbolName)
                                .font(.system(size: 14, weight: .heavy))
                            Text(step.shortTitle)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                            Text(badgeText(for: step))
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(isComplete(step) ? .white : MegrumTheme.muted)
                                .frame(minWidth: 22, minHeight: 22)
                                .background(isComplete(step) ? MegrumTheme.ok : Color.white.opacity(0.82), in: Capsule())
                        }
                        .foregroundStyle(selectedStep == step ? .white : MegrumTheme.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(
                            selectedStep == step ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.regularMaterial),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canJump(to: step))
                    .opacity(canJump(to: step) ? 1 : 0.5)
                }
            }
            .padding(.vertical, 2)
        }
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

    private func isComplete(_ step: ProposalCreateStep) -> Bool {
        configuration.canAdvance(from: step)
    }

    private func canJump(to step: ProposalCreateStep) -> Bool {
        guard let targetIndex = steps.firstIndex(of: step) else {
            return false
        }
        let priorSteps = steps.prefix(targetIndex)
        return priorSteps.allSatisfy { configuration.canAdvance(from: $0) }
    }
}

private struct ProposalScreenTitle: View {
    var step: ProposalCreateStep
    var targetItem: GoodsItem
    var steps: [ProposalCreateStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEP \(stepIndex)/\(max(steps.count, 1))")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(step.title)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text(targetItem.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(2)
        }
    }

    private var stepIndex: Int {
        (steps.firstIndex(of: step) ?? 0) + 1
    }
}

private struct ProposalExchangeMethodSelector: View {
    @Binding var exchangeMethod: ExchangeMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("交換手段")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Picker("交換手段", selection: $exchangeMethod) {
                ForEach(ExchangeMethod.allCases) { method in
                    Text(method.displayName).tag(method)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.64), lineWidth: 1)
        }
    }
}

private struct ProposalGoodsFilterBar: View {
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProposalFilterRow(
                title: "推し",
                choices: groups.map { ProposalFilterChoice(id: $0.id, title: $0.name) },
                selectedID: $selectedGroupID
            )
            ProposalFilterRow(
                title: "種別",
                choices: goodsTypes.map { ProposalFilterChoice(id: $0.id, title: $0.name) },
                selectedID: $selectedGoodsTypeID
            )
        }
    }
}

private struct ProposalFilterChoice: Identifiable, Equatable {
    var id: UUID
    var title: String
}

private struct ProposalFilterRow: View {
    var title: String
    var choices: [ProposalFilterChoice]
    @Binding var selectedID: UUID?

    var body: some View {
        if !choices.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ProposalFilterChip(title: "すべて", isSelected: selectedID == nil) {
                            selectedID = nil
                        }
                        ForEach(choices) { choice in
                            ProposalFilterChip(title: choice.title, isSelected: selectedID == choice.id) {
                                selectedID = choice.id
                            }
                        }
                    }
                    .padding(.vertical, 2)
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
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 13)
                .frame(height: 38)
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

private struct ProposalStepLead: View {
    var symbolName: String
    var title: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(text)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
    }
}

private struct ProposalSelectableGoodsRow: View {
    var item: GoodsItem
    var isSelected: Bool
    var badgeText: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(isSelected ? 0.24 : 0.12))
                    .frame(width: 72, height: 86)
                    .overlay {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "photo")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundStyle(isSelected ? MegrumTheme.lavender : .white)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(2)
                    if !item.tags.isEmpty {
                        Text(item.tags.map(\.name).prefix(2).joined(separator: " / "))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let badgeText {
                    Text(badgeText)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(MegrumTheme.lavender, in: Capsule())
                }
            }
            .padding(14)
            .background(.white.opacity(isSelected ? 0.94 : 0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? MegrumTheme.lavender.opacity(0.5) : .white.opacity(0.62), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProposalSelectableGoodsCompactCard: View {
    var item: GoodsItem
    var isSelected: Bool
    var badgeText: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MegrumTheme.lavender.opacity(isSelected ? 0.24 : 0.12))
                        .frame(width: 46, height: 58)
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
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(.white)
                                    case .empty:
                                        ProgressView()
                                            .controlSize(.small)
                                            .tint(.white)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "photo")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(isSelected ? MegrumTheme.lavender : .white)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundStyle(MegrumTheme.lavender)
                                    .background(.white, in: Circle())
                                    .offset(x: 5, y: -5)
                            }
                        }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if !item.tags.isEmpty {
                            Text(item.tags.map(\.name).prefix(2).joined(separator: " / "))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.6))

                    Text(badgeText ?? "候補")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted)

                    Spacer(minLength: 0)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .background(.white.opacity(isSelected ? 0.94 : 0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? MegrumTheme.lavender.opacity(0.52) : .white.opacity(0.62), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue(isSelected ? "選択中" : "未選択")
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
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
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
    @Binding var startAt: Date
    @Binding var endAt: Date
    @Binding var placeName: String
    @Binding var latitudeText: String
    @Binding var longitudeText: String
    var isRequestingLocation: Bool
    var locationErrorMessage: String?
    var placeSuggestions: [String]
    @State private var cameraPosition: MapCameraPosition = .region(Self.fallbackRegion)

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
        if tags.isEmpty {
            Text("この方法で使えるタグはありません")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    } label: {
                        Text(tag)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(selectedTags.contains(tag) ? .white : MegrumTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                selectedTags.contains(tag) ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.72)),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
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

private struct ProposalExchangePreviewRow: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ProposalPreviewSide(title: "受け取る", goods: receiverGoods)
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.sky)
            }
            ProposalPreviewSide(title: "私が出す", goods: senderGoods, alignRight: true)
        }
        .padding(14)
        .background(MegrumTheme.sky.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ProposalPreviewSide: View {
    var title: String
    var goods: [GoodsItem]
    var alignRight = false

    var body: some View {
        VStack(alignment: alignRight ? .trailing : .leading, spacing: 8) {
            Text("\(title) \(goods.count)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            HStack(spacing: -8) {
                ForEach(goods.prefix(4)) { item in
                    ProposalPreviewThumb(item: item)
                }
            }
            .frame(maxWidth: .infinity, alignment: alignRight ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProposalPreviewThumb: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.14))
            .frame(width: 48, height: 58)
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
        Image(systemName: "photo")
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
    }
}

private struct ProposalConfirmMethodCard: View {
    var exchangeMethod: ExchangeMethod
    var mailingAddress: MailingAddress?
    var isLoadingMailingAddress: Bool
    var onOpenAddressSettings: () -> Void

    var body: some View {
        ProposalCardSection(title: "受け渡し方法") {
            VStack(alignment: .leading, spacing: 12) {
                Label(exchangeMethod.displayName, systemImage: iconName)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

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
    var isCreating: Bool
    var onBack: () -> Void
    var onPrimary: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if selectedStep != .give {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 52, height: 56)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button(action: onPrimary) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryTitle)
                    if selectedStep != .confirm {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: MegrumTheme.lavender.opacity(canUsePrimary ? 0.28 : 0), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canUsePrimary)
            .opacity(canUsePrimary ? 1 : 0.48)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.regularMaterial)
    }

    private var canUsePrimary: Bool {
        configuration.canAdvance(from: selectedStep)
    }

    private var primaryTitle: String {
        guard canUsePrimary else {
            return configuration.blockedTitle(for: selectedStep)
        }
        if selectedStep == .confirm {
            return configuration.submitTitle
        }
        return "次へ"
    }
}

private extension View {
    func proposalFlowMeetupRow() -> some View {
        self
            .frame(minHeight: 48)
            .padding(.vertical, 6)
    }
}
