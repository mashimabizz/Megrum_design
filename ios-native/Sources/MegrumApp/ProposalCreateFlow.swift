import Foundation
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

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStep: ProposalCreateStep = .give
    @State private var selectedSenderGoodsIDs: Set<UUID> = []
    @State private var exchangeMethod: ExchangeMethod = .hand
    @State private var selectedConditionTags: Set<String> = []
    @State private var message = ""
    @State private var meetupStartAt = Date()
    @State private var meetupEndAt = Date().addingTimeInterval(30 * 60)
    @State private var meetupPlaceName = ""
    @State private var meetupLatitudeText = ""
    @State private var meetupLongitudeText = ""
    @StateObject private var locationState = MegrumLocationState()

    private var orderedSenderGoodsIDs: [UUID] {
        appState.inventory.map(\.id).filter { selectedSenderGoodsIDs.contains($0) }
    }

    private var selectedSenderGoods: [GoodsItem] {
        appState.inventory.filter { selectedSenderGoodsIDs.contains($0.id) }
    }

    private var resolvedReceiverGoodsIDs: [UUID] {
        var uniqueIDs: [UUID] = []
        let candidateIDs = receiverGoodsIDs ?? [targetItem.id]
        for id in candidateIDs where !uniqueIDs.contains(id) {
            uniqueIDs.append(id)
        }
        return uniqueIDs.isEmpty ? [targetItem.id] : uniqueIDs
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
        guard
            let latitude = Self.coordinateValue(from: meetupLatitudeText),
            let longitude = Self.coordinateValue(from: meetupLongitudeText)
        else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupPlaceName,
            latitude: latitude,
            longitude: longitude
        )
        return input.isValid ? input : nil
    }

    private var meetupSummary: String {
        if let meetupInput {
            return "\(Self.dateText(meetupInput.startAt)) / \(meetupInput.normalizedPlaceName)"
        }
        return configuration.requiresMeetupBeforeSubmit ? "未設定" : "現地では会わない設定"
    }

    var body: some View {
        VStack(spacing: 0) {
            ProposalStepHeader(
                selectedStep: $selectedStep,
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
                    ProposalScreenTitle(step: selectedStep, targetItem: targetItem)

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
        .safeAreaInset(edge: .bottom) {
            ProposalFlowBottomBar(
                selectedStep: selectedStep,
                configuration: configuration,
                isCreating: appState.isCreatingProposal,
                onBack: previousStep,
                onPrimary: primaryAction
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("打診作成")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled(appState.isCreatingProposal)
        .onAppear {
            seedDefaultSenderSelection()
            normalizeMeetupEnd()
            requestLocationIfNeeded()
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
        }
        .onChange(of: appState.inventory.map(\.id)) { _, _ in
            selectedSenderGoodsIDs = selectedSenderGoodsIDs.intersection(Set(appState.inventory.map(\.id)))
            seedDefaultSenderSelection()
        }
        .onChange(of: exchangeMethod) { _, _ in
            selectedConditionTags = selectedConditionTags.intersection(Set(conditionTagOptions))
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
            if meetupPlaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                meetupPlaceName = "現在地"
            }
            if meetupLatitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                meetupLatitudeText = Self.coordinateText(coordinate.latitude)
            }
            if meetupLongitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                meetupLongitudeText = Self.coordinateText(coordinate.longitude)
            }
        }
    }

    private var giveStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProposalStepLead(
                symbolName: "shippingbox.fill",
                title: "あなたが出すグッズを選ぶ",
                text: "複数選択できます。相手に見せる提示物として送信されます。"
            )

            if appState.inventory.isEmpty {
                ContentUnavailableView(
                    "在庫がありません",
                    systemImage: "tray",
                    description: Text("在庫を登録すると、ここから出すものを選べます。")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(appState.inventory) { item in
                        ProposalSelectableGoodsRow(
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
                title: "受け取る内容を確認",
                text: listingID == nil
                    ? "検索またはプロフィールで選んだ相手のグッズです。"
                    : "個別募集の条件に含まれるグッズを受け取る内容です。"
            )

            ProposalReceiveCard(
                targetItem: targetItem,
                receiverGoodsCount: resolvedReceiverGoodsIDs.count,
                isListingSource: listingID != nil
            )
        }
    }

    private var meetupStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProposalStepLead(
                symbolName: "mappin.and.ellipse",
                title: "会う場所と時間を決める",
                text: "現地交換では、送信前に待ち合わせ候補まで入れておきます。"
            )

            ProposalCardSection(title: "交換方法") {
                Picker("交換方法", selection: $exchangeMethod) {
                    ForEach(ExchangeMethod.allCases) { method in
                        Text(Self.methodTitle(method)).tag(method)
                    }
                }
                .pickerStyle(.segmented)

                if let notice = methodNotice {
                    Text(notice)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if configuration.requiresMeetupBeforeSubmit {
                ProposalFlowMeetupForm(
                    startAt: $meetupStartAt,
                    endAt: $meetupEndAt,
                    placeName: $meetupPlaceName,
                    latitudeText: $meetupLatitudeText,
                    longitudeText: $meetupLongitudeText,
                    isRequestingLocation: locationState.isRequestingLocation,
                    locationErrorMessage: locationState.locationErrorMessage
                )
            }

            ProposalCardSection(title: "交換条件タグ") {
                ProposalTagGrid(tags: conditionTagOptions, selectedTags: $selectedConditionTags)
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
                targetItem: targetItem,
                receiverGoodsCount: resolvedReceiverGoodsIDs.count,
                methodTitle: Self.methodTitle(exchangeMethod),
                meetupSummary: meetupSummary,
                conditionTags: orderedConditionTags
            )

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
            selectedSenderGoodsIDs.remove(id)
        } else {
            selectedSenderGoodsIDs.insert(id)
        }
    }

    private func seedDefaultSenderSelection() {
        guard selectedSenderGoodsIDs.isEmpty, let firstID = appState.inventory.first?.id else {
            return
        }
        selectedSenderGoodsIDs.insert(firstID)
    }

    private func normalizeMeetupEnd() {
        if meetupEndAt <= meetupStartAt {
            meetupEndAt = meetupStartAt.addingTimeInterval(30 * 60)
        }
    }

    private func previousStep() {
        guard let index = ProposalCreateStep.allCases.firstIndex(of: selectedStep), index > 0 else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = ProposalCreateStep.allCases[index - 1]
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
              let index = ProposalCreateStep.allCases.firstIndex(of: selectedStep),
              ProposalCreateStep.allCases.indices.contains(index + 1)
        else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = ProposalCreateStep.allCases[index + 1]
        }
    }

    private func createProposal() async {
        guard configuration.canSubmit, let targetStatus = configuration.targetStatus else {
            return
        }
        let meetup = configuration.requiresMeetupBeforeSubmit ? meetupInput : nil
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
                status: targetStatus,
                meetup: meetup,
                listingID: listingID
            )
        )
        if created {
            dismiss()
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

    private static func coordinateValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func coordinateText(_ value: Double) -> String {
        String(format: "%.6f", value)
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

private struct ProposalStepHeader: View {
    @Binding var selectedStep: ProposalCreateStep
    var configuration: ProposalCreateConfiguration
    var senderCount: Int
    var receiverCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ProposalCreateStep.allCases) { step in
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
        guard let targetIndex = ProposalCreateStep.allCases.firstIndex(of: step) else {
            return false
        }
        let priorSteps = ProposalCreateStep.allCases.prefix(targetIndex)
        return priorSteps.allSatisfy { configuration.canAdvance(from: $0) }
    }
}

private struct ProposalScreenTitle: View {
    var step: ProposalCreateStep
    var targetItem: GoodsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEP \(stepIndex)/4")
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
        (ProposalCreateStep.allCases.firstIndex(of: step) ?? 0) + 1
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

private struct ProposalFlowMeetupForm: View {
    @Binding var startAt: Date
    @Binding var endAt: Date
    @Binding var placeName: String
    @Binding var latitudeText: String
    @Binding var longitudeText: String
    var isRequestingLocation: Bool
    var locationErrorMessage: String?

    var body: some View {
        ProposalCardSection(title: "待ち合わせ候補") {
            VStack(spacing: 0) {
                DatePicker("開始日時", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    .proposalFlowMeetupRow()
                Divider()
                DatePicker("終了日時", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    .proposalFlowMeetupRow()
                Divider()
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
    var targetItem: GoodsItem
    var receiverGoodsCount: Int
    var methodTitle: String
    var meetupSummary: String
    var conditionTags: [String]

    var body: some View {
        VStack(spacing: 10) {
            ProposalSummaryRow(title: "あなたが出す", value: senderGoods.map(\.title).joined(separator: " / "))
            ProposalSummaryRow(
                title: "受け取る",
                value: receiverGoodsCount > 1 ? "\(targetItem.title) ほか\(receiverGoodsCount - 1)件" : targetItem.title
            )
            ProposalSummaryRow(title: "交換方法", value: methodTitle)
            ProposalSummaryRow(title: "待ち合わせ", value: meetupSummary)
            ProposalSummaryRow(title: "条件タグ", value: conditionTags.isEmpty ? "なし" : conditionTags.joined(separator: " / "))
        }
        .padding(16)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.68), lineWidth: 1)
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
