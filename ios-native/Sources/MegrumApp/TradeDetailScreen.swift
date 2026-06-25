import Foundation
import MegrumCore
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
}

struct TradePartnerProfileRoute: Identifiable, Hashable {
    var userID: UUID

    var id: UUID { userID }
}
