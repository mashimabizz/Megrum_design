import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TradeDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @State private var draftMessage = ""
    @State private var selectedEvidencePhotoItem: PhotosPickerItem?
    @State private var selectedChatPhotoItem: PhotosPickerItem?
    @State private var selectedOutfitPhotoItem: PhotosPickerItem?
    @State private var isShowingEvidenceCamera = false
    @State private var isShowingChatCamera = false
    @State private var isShowingOutfitCamera = false
    @State private var isShowingEvaluationPage = false
    @State private var isShowingDisputePage = false
    @State private var isShowingRejectConfirmation = false
    @State private var isShowingCounterProposalPage = false
    @State private var isShowingSchedulePage = false
    @State private var unavailableChatAction: TradeUnavailableChatAction?
    @State private var assistanceRequestKind: TradeAssistanceRequestKind?
    @State private var selectedRemoteImage: RemoteImageSelection?
    @State private var isWaitingToShareLocation = false
    @State private var disputeDetailRoute: TradeDisputeDetailRoute?
    @State private var partnerProfileRoute: TradePartnerProfileRoute?
    @State private var didSubmitEvaluation = false
    @StateObject private var locationState = MegrumLocationState()

    private var messages: [TradeMessage] {
        appState.messages(for: proposal.id)
    }

    private var currentProposal: TradeProposal {
        appState.proposals.first { $0.id == proposal.id } ?? proposal
    }

    private var goodsByID: [UUID: GoodsItem] {
        TradeGoodsLookup.build(
            inventory: appState.inventory,
            homeMatchedItems: appState.homeMatchedItems,
            homePossibleItems: appState.homePossibleItems,
            wishes: appState.wishes,
            publicTradeGoodsByUserID: appState.publicTradeGoodsByUserID
        )
    }

    private var latestDisputeSummary: TradeDisputeSummary? {
        messages
            .compactMap(TradeDisputeSummary.init(message:))
            .max { $0.submittedAt < $1.submittedAt }
    }

    private var chatInputAvailability: TradeChatInputAvailability {
        TradeChatInputAvailability(proposal: currentProposal)
    }

    private var isChatInputVisible: Bool {
        guard let viewerID else {
            return false
        }
        return currentProposal.isParticipant(viewerID) && chatInputAvailability.canSendMessages
    }

    private var messageInputContext: TradeMessageInputContext {
        TradeMessageInputContext(
            isSending: appState.sendingMessageProposalID == proposal.id,
            canUseCamera: canUseCamera,
            proposalStatus: currentProposal.status,
            supportsHandExchange: supportsHandExchange,
            showsCounterProposal: currentProposal.canCreateCounterProposal(from: viewerID)
        )
    }

    private var supportsHandExchange: Bool {
        currentProposal.exchangeMethod == .hand || currentProposal.exchangeMethod == .both
    }

    private var evaluationPromptState: TradeEvaluationPromptState {
        TradeEvaluationPromptState(
            proposal: currentProposal,
            viewerID: viewerID,
            messages: messages,
            localSubmission: didSubmitEvaluation
        )
    }

    private var viewerID: UUID? {
        appState.viewer?.id
    }

    private var partnerID: UUID? {
        viewerID.flatMap { currentProposal.partnerID(for: $0) }
    }

    private var partnerProfile: UserProfile? {
        partnerID.flatMap { appState.publicProfilesByUserID[$0]?.profile }
    }

    private var heroPresentation: TradeDetailHeroPresentation {
        TradeDetailHeroPresentation(
            proposal: currentProposal,
            viewerID: viewerID,
            profilesByUserID: appState.publicProfilesByUserID
        )
    }

    private var offeredGoodsIDs: [UUID] {
        viewerID.flatMap { currentProposal.goodsOffered(by: $0) } ?? currentProposal.senderGoodsIDs
    }

    private var requestedGoodsIDs: [UUID] {
        viewerID.flatMap { currentProposal.goodsRequested(by: $0) } ?? currentProposal.receiverGoodsIDs
    }

    private var requestedGoods: [GoodsItem] {
        tradeItems(for: requestedGoodsIDs)
    }

    private var offeredGoods: [GoodsItem] {
        tradeItems(for: offeredGoodsIDs)
    }

    private var paymentSummaryText: String? {
        guard currentProposal.cashOffer else {
            return nil
        }
        return UserPaymentMethod.displayText(
            for: partnerProfile?.paymentMethods ?? [],
            otherNote: partnerProfile?.paymentNote,
            emptyText: "未設定"
        )
    }

    var body: some View {
        bodyBeforeDialogs
        .confirmationDialog(
            "この打診を断りますか？",
            isPresented: $isShowingRejectConfirmation,
            titleVisibility: .visible
        ) {
            Button("断る", role: .destructive) {
                Task {
                    await appState.rejectProposal(proposalID: currentProposal.id)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("断った後は、この打診では取引を進められません。")
        }
#if os(iOS)
        .fullScreenCover(item: $selectedRemoteImage) { selection in
            FullScreenRemoteImageView(url: selection.url)
        }
#else
        .sheet(item: $selectedRemoteImage) { selection in
            FullScreenRemoteImageView(url: selection.url)
        }
#endif
#if os(iOS)
        .sheet(isPresented: $isShowingEvidenceCamera) {
            NativeCameraCaptureView { imageData in
                handleCapturedEvidenceImage(imageData)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingOutfitCamera) {
            NativeCameraCaptureView { imageData in
                handleCapturedOutfitImage(imageData)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingChatCamera) {
            NativeCameraCaptureView { imageData in
                handleCapturedChatImage(imageData)
            }
            .ignoresSafeArea()
        }
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let latestDisputeSummary {
                    Button {
                        openDisputeDetail(latestDisputeSummary)
                    } label: {
                        Label("申告詳細", systemImage: "exclamationmark.bubble")
                    }
                } else {
                    Button {
                        isShowingDisputePage = true
                    } label: {
                        Label("通報", systemImage: "exclamationmark.bubble")
                    }
                    .disabled(appState.filingDisputeProposalID == currentProposal.id)
                }
            }
        }
    }

    private var bodyBeforeDialogs: some View {
        TradeDetailContent(
            proposal: currentProposal,
            messages: messages,
            viewerID: viewerID,
            heroPresentation: heroPresentation,
            latestDisputeSummary: latestDisputeSummary,
            tradeSummaryLine: tradeSummaryLine,
            requestedGoods: requestedGoods,
            offeredGoods: offeredGoods,
            requestedGoodsCount: requestedGoodsIDs.count,
            offeredGoodsCount: offeredGoodsIDs.count,
            paymentSummaryText: paymentSummaryText,
            evidencePhotos: appState.evidencePhotos(for: currentProposal),
            selectedEvidencePhotoItem: $selectedEvidencePhotoItem,
            partnerLastReadAt: appState.partnerLastReadAt(for: currentProposal.id),
            evaluationState: evaluationPromptState,
            isResponding: appState.respondingProposalID == currentProposal.id,
            isLoadingMessages: appState.loadingMessagesProposalID == proposal.id,
            isApprovingCancel: appState.respondingProposalID == currentProposal.id,
            isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
            isApprovingEvidence: appState.approvingEvidenceProposalID == currentProposal.id,
            canUseCamera: canUseCamera,
            onOpenDispute: openDisputeDetail,
            onOpenPartnerProfile: openPartnerProfile,
            onAgree: { acceptedExchangeMethod in
                Task {
                    await appState.agreeProposal(
                        proposalID: currentProposal.id,
                        acceptedExchangeMethod: acceptedExchangeMethod
                    )
                }
            },
            onReject: {
                isShowingRejectConfirmation = true
            },
            onCounterProposal: {
                isShowingCounterProposalPage = true
            },
            onOpenEvidenceCamera: {
                isShowingEvidenceCamera = true
            },
            onOpenImage: { url in
                selectedRemoteImage = RemoteImageSelection(url: url)
            },
            onApproveEvidence: {
                Task {
                    await appState.approveTradeEvidence(proposalID: currentProposal.id)
                }
            },
            onRate: {
                isShowingEvaluationPage = true
            },
            onApproveCancel: {
                Task {
                    await appState.approveTradeCancel(proposalID: currentProposal.id)
                }
            }
        )
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            TradeDetailMessageInputBar(
                text: $draftMessage,
                selectedChatPhotoItem: $selectedChatPhotoItem,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isVisible: isChatInputVisible,
                context: messageInputContext,
                onOpenSchedule: {
                    isShowingSchedulePage = true
                },
                onSendArrivalStatus: { action in
                    sendArrivalQuickAction(action)
                },
                onOpenLocationPlaceholder: {
                    shareCurrentLocation()
                },
                onOpenChatCamera: {
                    isShowingChatCamera = true
                },
                onOpenOutfitCamera: {
                    isShowingOutfitCamera = true
                },
                onCounterProposal: {
                    isShowingCounterProposalPage = true
                },
                onRequestLate: {
                    assistanceRequestKind = .late
                },
                onRequestCancel: {
                    assistanceRequestKind = .cancel
                },
                onReport: {
                    isShowingDisputePage = true
                },
                onSendMessage: sendDraftMessage
            )
        }
        .navigationTitle("@\(heroPresentation.partnerHandle)")
        .megrumInlineNavigationTitle()
#if os(iOS)
        .toolbar(.hidden, for: .tabBar)
#endif
        .task {
            await appState.loadMessages(proposalID: proposal.id)
            await appState.loadTradeEvidencePhotos(proposal: currentProposal, reportsFailure: false)
            if let partnerID, appState.publicProfilesByUserID[partnerID] == nil {
                await appState.loadPublicUserProfile(userID: partnerID, reportsFailure: false)
            }
        }
        .onChange(of: selectedEvidencePhotoItem) { _, item in
            handleSelectedEvidencePhoto(item)
        }
        .onChange(of: selectedChatPhotoItem) { _, item in
            handleSelectedChatPhoto(item)
        }
        .onChange(of: selectedOutfitPhotoItem) { _, item in
            handleSelectedOutfitPhoto(item)
        }
        .navigationDestination(isPresented: $isShowingEvaluationPage) {
            TradeEvaluationSheet(
                isSubmitting: appState.submittingEvaluationProposalID == currentProposal.id
            ) { stars, comment in
                let sent = await appState.submitTradeEvaluation(
                    proposalID: currentProposal.id,
                    stars: stars,
                    comment: comment
                )
                if sent {
                    didSubmitEvaluation = true
                    await appState.loadMessages(proposalID: currentProposal.id)
                    isShowingEvaluationPage = false
                }
            }
        }
        .navigationDestination(isPresented: $isShowingDisputePage) {
            TradeDisputeSheet(
                isSubmitting: appState.filingDisputeProposalID == currentProposal.id
            ) { category, factMemo in
                let sent = await appState.fileTradeDispute(
                    proposalID: currentProposal.id,
                    category: category,
                    factMemo: factMemo
                )
                if sent {
                    isShowingDisputePage = false
                }
            }
        }
        .navigationDestination(isPresented: $isShowingCounterProposalPage) {
            CounterProposalSheet(
                appState: appState,
                proposal: currentProposal
            )
        }
        .navigationDestination(isPresented: $isShowingSchedulePage) {
            TradeScheduleSheet(appState: appState, proposal: currentProposal)
        }
        .navigationDestination(item: $unavailableChatAction) { action in
            TradeUnavailableChatActionSheet(action: action)
        }
        .navigationDestination(item: $assistanceRequestKind) { kind in
            TradeAssistanceRequestSheet(
                kind: kind,
                isSubmitting: appState.sendingMessageProposalID == currentProposal.id
            ) { intent in
                let sent: Bool
                switch intent.action {
                case .lateNotice:
                    sent = await appState.sendLateNoticeMessage(
                        proposalID: currentProposal.id,
                        lateMinutes: intent.lateMinutes ?? TradeLateDelayBucket.ten.rawValue,
                        reason: intent.reason,
                        note: intent.note
                    )
                case .cancelRequested:
                    sent = await appState.sendCancelRequestMessage(
                        proposalID: currentProposal.id,
                        reason: intent.reason,
                        note: intent.note
                    )
                }
                if sent {
                    assistanceRequestKind = nil
                }
            }
        }
        .navigationDestination(item: $disputeDetailRoute) { route in
            DisputeDetailScreen(model: route.model)
        }
        .navigationDestination(item: $partnerProfileRoute) { route in
            PublicUserProfileScreen(appState: appState, userID: route.userID)
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            handleLocationCoordinateChange(coordinate)
        }
        .onChange(of: locationState.locationErrorMessage) { _, errorMessage in
            handleLocationErrorChange(errorMessage)
        }
    }

    private var tradeSummaryLine: String {
        "受け取る \(receiveSummaryText)  ⇄  出す \(goodsSummary(for: offeredGoodsIDs))"
    }

    private var receiveSummaryText: String {
        if currentProposal.cashOffer, requestedGoodsIDs.isEmpty {
            return TradeAmountFormatter.fixedPrice(amount: currentProposal.cashAmount, fallback: "定価交換")
        }
        return goodsSummary(for: requestedGoodsIDs)
    }

    private func goodsSummary(for ids: [UUID]) -> String {
        let items = tradeItems(for: ids)
        guard let first = items.first else {
            return ids.isEmpty ? "未設定" : "\(ids.count)点"
        }
        let suffix = items.count > 1 ? " 他\(items.count - 1)点" : ""
        return "\(first.title)\(first.quantity > 1 ? "×\(first.quantity)" : "")\(suffix)"
    }

    private func openDisputeDetail(_ summary: TradeDisputeSummary) {
        disputeDetailRoute = TradeDisputeDetailRoute(
            summary: summary,
            model: summary.detailModel(proposal: currentProposal, viewerID: viewerID)
        )
    }

    private func openPartnerProfile() {
        guard let partnerID else {
            return
        }
        partnerProfileRoute = TradePartnerProfileRoute(userID: partnerID)
    }

    private func handleSelectedEvidencePhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await addEvidence(from: item)
        }
    }

    private func handleSelectedChatPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await addChatPhoto(from: item, messageType: .photo)
        }
    }

    private func handleSelectedOutfitPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await addChatPhoto(from: item, messageType: .outfitPhoto)
        }
    }

    private func handleCapturedEvidenceImage(_ imageData: Data) {
        Task {
            await addEvidence(data: imageData, imageContentType: "image/jpeg")
        }
    }

    private func handleCapturedOutfitImage(_ imageData: Data) {
        Task {
            await addChatPhoto(
                data: imageData,
                messageType: .outfitPhoto,
                imageContentType: "image/jpeg"
            )
        }
    }

    private func handleCapturedChatImage(_ imageData: Data) {
        Task {
            await addChatPhoto(
                data: imageData,
                messageType: .photo,
                imageContentType: "image/jpeg"
            )
        }
    }

    private func sendDraftMessage() {
        Task {
            let sent = await appState.sendMessage(proposalID: proposal.id, body: draftMessage)
            if sent {
                draftMessage = ""
            }
        }
    }

    private func handleLocationCoordinateChange(_ coordinate: MegrumLocationCoordinate?) {
        guard isWaitingToShareLocation, let coordinate else {
            return
        }
        isWaitingToShareLocation = false
        sendLocationMessage(coordinate)
    }

    private func handleLocationErrorChange(_ errorMessage: String?) {
        guard isWaitingToShareLocation, errorMessage != nil else {
            return
        }
        isWaitingToShareLocation = false
        unavailableChatAction = .location
    }

    private func addEvidence(from item: PhotosPickerItem) async {
        defer {
            selectedEvidencePhotoItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }
        await addEvidence(data: data, imageContentType: inferredEvidenceImageContentType(from: data))
    }

    private func addEvidence(data: Data, imageContentType: String) async {
        _ = await appState.addTradeEvidence(
            proposalID: currentProposal.id,
            imageData: data,
            imageContentType: imageContentType
        )
    }

    private func addChatPhoto(from item: PhotosPickerItem, messageType: TradeMessageType) async {
        defer {
            switch messageType {
            case .outfitPhoto:
                selectedOutfitPhotoItem = nil
            case .photo:
                selectedChatPhotoItem = nil
            case .text, .location, .arrivalStatus, .system:
                break
            }
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            unavailableChatAction = messageType == .photo ? .photo : .outfitPhoto
            return
        }
        await addChatPhoto(
            data: data,
            messageType: messageType,
            imageContentType: inferredEvidenceImageContentType(from: data)
        )
    }

    private func addChatPhoto(data: Data, messageType: TradeMessageType, imageContentType: String) async {
        let intent = TradeOutfitPhotoSendIntent(
            imageContentType: imageContentType
        )
        let sent = await appState.sendPhotoMessage(
            proposalID: currentProposal.id,
            imageData: data,
            imageContentType: intent.imageContentType,
            messageType: messageType == .outfitPhoto ? intent.messageType : messageType,
            body: messageType == .outfitPhoto ? intent.body : nil
        )
        if !sent {
            unavailableChatAction = messageType == .photo ? .photo : .outfitPhoto
        }
    }

    private func sendArrivalQuickAction(_ action: TradeArrivalQuickAction) {
        let intent = TradeArrivalStatusSendIntent(action: action)
        Task {
            _ = await appState.sendArrivalStatusMessage(
                proposalID: currentProposal.id,
                status: intent.status,
                body: intent.body
            )
        }
    }

    private func shareCurrentLocation() {
        if let coordinate = locationState.coordinate {
            sendLocationMessage(coordinate)
            return
        }

        isWaitingToShareLocation = true
        locationState.requestCurrentLocation()
    }

    private func sendLocationMessage(_ coordinate: MegrumLocationCoordinate) {
        let intent = TradeLocationShareIntent(coordinate: coordinate)
        guard intent.isSubmittable else {
            unavailableChatAction = .location
            return
        }
        Task {
            _ = await appState.sendLocationMessage(
                proposalID: currentProposal.id,
                latitude: intent.coordinate.latitude,
                longitude: intent.coordinate.longitude,
                label: intent.normalizedLabel,
                body: intent.body
            )
        }
    }

    private var canUseCamera: Bool {
#if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
#else
        false
#endif
    }

    private func tradeItems(for ids: [UUID]) -> [GoodsItem] {
        ids.compactMap { goodsByID[$0] }
    }
}

private struct TradePartnerProfileRoute: Identifiable, Hashable {
    var userID: UUID

    var id: UUID { userID }
}
