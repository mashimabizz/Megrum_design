import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @State var draftMessage = ""
    @State var selectedEvidencePhotoItem: PhotosPickerItem?
    @State var selectedChatPhotoItem: PhotosPickerItem?
    @State var selectedOutfitPhotoItem: PhotosPickerItem?
    @State var isShowingEvidenceCamera = false
    @State var isShowingChatCamera = false
    @State var isShowingOutfitCamera = false
    @State var isShowingEvidenceList = false
    @State var isShowingEvaluationPage = false
    @State var isShowingDisputePage = false
    @State var isShowingRejectConfirmation = false
    @State var isShowingCounterProposalPage = false
    @State var isShowingSchedulePage = false
    @State var unavailableChatAction: TradeUnavailableChatAction?
    @State var assistanceRequestKind: TradeAssistanceRequestKind?
    @State var selectedRemoteImage: RemoteImageSelection?
    @State var isWaitingToShareLocation = false
    @State var disputeDetailRoute: TradeDisputeDetailRoute?
    @State var partnerProfileRoute: TradePartnerProfileRoute?
    @State var didSubmitEvaluation = false
    @StateObject var locationState = MegrumLocationState()

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
        .sheet(isPresented: $isShowingEvidenceList) {
            TradeEvidenceListSheet(
                proposal: currentProposal,
                viewerID: viewerID,
                evidencePhotos: appState.evidencePhotos(for: currentProposal),
                selectedPhotoItem: $selectedEvidencePhotoItem,
                isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
                deletingPhotoID: appState.deletingEvidencePhotoID,
                canUseCamera: canUseCamera,
                onOpenCamera: {
                    isShowingEvidenceCamera = true
                },
                onOpenImage: { url in
                    selectedRemoteImage = RemoteImageSelection(url: url)
                },
                onDelete: { photo in
                    Task {
                        await appState.deleteTradeEvidencePhoto(
                            proposalID: currentProposal.id,
                            photoID: photo.id
                        )
                    }
                }
            )
        }
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
            onOpenEvidenceList: {
                isShowingEvidenceList = true
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
            PublicUserProfileScreen(
                appState: appState,
                userID: route.userID,
                presentationContext: .tradeChat
            )
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            handleLocationCoordinateChange(coordinate)
        }
        .onChange(of: locationState.locationErrorMessage) { _, errorMessage in
            handleLocationErrorChange(errorMessage)
        }
    }
}

struct TradePartnerProfileRoute: Identifiable, Hashable {
    var userID: UUID

    var id: UUID { userID }
}
