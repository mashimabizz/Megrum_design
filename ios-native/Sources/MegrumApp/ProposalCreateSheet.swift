import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCreateSheet: View {
    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSenderGoodsID: UUID?
    @State private var exchangeMethod: ExchangeMethod = .mail
    @State private var selectedConditionTags: Set<String> = []
    @State private var message = ""
    @State private var meetupStartAt = Date()
    @State private var meetupEndAt = Date().addingTimeInterval(30 * 60)
    @State private var meetupPlaceName = ""
    @State private var meetupLatitudeText = ""
    @State private var meetupLongitudeText = ""
    @StateObject private var locationState = MegrumLocationState()

    private var selectedSenderID: UUID? {
        selectedSenderGoodsID ?? appState.inventory.first?.id
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
            hasSelectedSenderGoods: selectedSenderID != nil,
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROPOSAL")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text("打診を作成")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                }

                proposalTargetCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("私が出す")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    if appState.inventory.isEmpty {
                        Text("マイグッズを登録すると選択できます")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(appState.inventory) { item in
                                    proposalGoodsChoice(item)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

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

                    if let methodNotice = configuration.methodNotice {
                        Text(methodNotice)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if configuration.requiresMeetupBeforeSubmit {
                    ProposalMeetupForm(
                        startAt: $meetupStartAt,
                        endAt: $meetupEndAt,
                        placeName: $meetupPlaceName,
                        latitudeText: $meetupLatitudeText,
                        longitudeText: $meetupLongitudeText,
                        isRequestingLocation: locationState.isRequestingLocation,
                        locationErrorMessage: locationState.locationErrorMessage
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("交換条件タグ")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                        ForEach(conditionTagOptions, id: \.self) { tag in
                            Button {
                                if selectedConditionTags.contains(tag) {
                                    selectedConditionTags.remove(tag)
                                } else {
                                    selectedConditionTags.insert(tag)
                                }
                            } label: {
                                Text(tag)
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundStyle(selectedConditionTags.contains(tag) ? .white : MegrumTheme.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(
                                        selectedConditionTags.contains(tag)
                                            ? AnyShapeStyle(MegrumTheme.lavender)
                                            : AnyShapeStyle(.regularMaterial),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("メッセージ")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    TextField("よろしくお願いします", text: $message, axis: .vertical)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(3...6)
                        .padding(16)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                Button {
                    Task {
                        await createProposal()
                    }
                } label: {
                    HStack {
                        if appState.isCreatingProposal {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(configuration.submitTitle)
                    }
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!configuration.canSubmit)
                .opacity(configuration.canSubmit ? 1 : 0.48)
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 40)
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
        .onAppear {
            selectedSenderGoodsID = selectedSenderID
            if meetupEndAt <= meetupStartAt {
                meetupEndAt = meetupStartAt.addingTimeInterval(30 * 60)
            }
            requestLocationIfNeeded()
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
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
            if meetupPlaceName.isBlank {
                meetupPlaceName = "現在地"
            }
            if meetupLatitudeText.isBlank {
                meetupLatitudeText = Self.coordinateText(coordinate.latitude)
            }
            if meetupLongitudeText.isBlank {
                meetupLongitudeText = Self.coordinateText(coordinate.longitude)
            }
        }
    }

    private var proposalTargetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("受け取る")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MegrumTheme.sky.opacity(0.24))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(targetItem.title)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(2)
                    Text(configuration.targetSubtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    if let targetSupplement = configuration.targetSupplement {
                        Text(targetSupplement)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.72), lineWidth: 1))
        }
    }

    private func proposalGoodsChoice(_ item: GoodsItem) -> some View {
        Button {
            selectedSenderGoodsID = item.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.2))
                    .frame(width: 98, height: 116)
                    .overlay {
                        Image(systemName: selectedSenderGoodsID == item.id ? "checkmark.circle.fill" : "photo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(selectedSenderGoodsID == item.id ? MegrumTheme.lavender : .white)
                    }

                Text(item.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .frame(width: 98, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func createProposal() async {
        guard let selectedSenderID, let targetStatus = configuration.targetStatus else {
            return
        }
        let meetup = configuration.requiresMeetupBeforeSubmit ? meetupInput : nil
        guard !configuration.requiresMeetupBeforeSubmit || meetup != nil else {
            return
        }
        let created = await appState.createProposal(
            ProposalCreateInput(
                receiverID: targetItem.ownerID,
                senderGoodsIDs: [selectedSenderID],
                receiverGoodsIDs: resolvedReceiverGoodsIDs,
                exchangeMethod: exchangeMethod,
                conditionTags: orderedConditionTags,
                message: message,
                status: targetStatus,
                meetup: meetup,
                listingID: listingID
            )
        )
        if created {
            dismiss()
        }
    }

    private static func coordinateValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func coordinateText(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private func requestLocationIfNeeded() {
        guard configuration.requiresMeetupBeforeSubmit else {
            return
        }
        locationState.requestCurrentLocation()
    }
}
