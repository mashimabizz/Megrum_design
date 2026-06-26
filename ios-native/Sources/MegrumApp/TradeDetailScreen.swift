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
    @State var isShowingEvidenceSourceDialog = false
    @State var isShowingEvidencePhotoLibraryPicker = false
    @State var isShowingChatPhotoLibraryPicker = false
    @State var isShowingOutfitPhotoLibraryPicker = false
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
    @State var isMessageComposerFocused = false
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
        .confirmationDialog(
            "証跡写真を追加",
            isPresented: $isShowingEvidenceSourceDialog,
            titleVisibility: .visible
        ) {
            Button("写真を撮る") {
                isShowingEvidenceCamera = true
            }
            .disabled(appState.addingEvidenceProposalID == currentProposal.id || !canUseCamera)

            Button("アルバムから選ぶ") {
                isShowingEvidencePhotoLibraryPicker = true
            }
            .disabled(appState.addingEvidenceProposalID == currentProposal.id)

            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("交換したグッズがわかる写真を追加します。")
        }
        .photosPicker(
            isPresented: $isShowingEvidencePhotoLibraryPicker,
            selection: evidencePhotoPickerSelection,
            matching: .images
        )
        .photosPicker(
            isPresented: $isShowingChatPhotoLibraryPicker,
            selection: $selectedChatPhotoItem,
            matching: .images
        )
        .photosPicker(
            isPresented: $isShowingOutfitPhotoLibraryPicker,
            selection: $selectedOutfitPhotoItem,
            matching: .images
        )
        .sheet(isPresented: $isShowingEvidenceList) {
            TradeEvidenceListSheet(
                proposal: currentProposal,
                viewerID: viewerID,
                evidencePhotos: appState.evidencePhotos(for: currentProposal),
                isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
                isApproving: appState.approvingEvidenceProposalID == currentProposal.id,
                deletingPhotoID: appState.deletingEvidencePhotoID,
                canUseCamera: canUseCamera,
                onOpenCamera: {
                    isShowingEvidenceCamera = true
                },
                onOpenPhotoLibrary: {
                    isShowingEvidencePhotoLibraryPicker = true
                },
                onDelete: { photo in
                    await appState.deleteTradeEvidencePhoto(
                        proposalID: currentProposal.id,
                        photoID: photo.id
                    )
                },
                onApprove: { photo in
                    Task {
                        await appState.approveTradeEvidence(proposalID: currentProposal.id, photoID: photo.id)
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
        .overlay {
            if let selectedRemoteImage {
                FullScreenRemoteImageView(
                    url: selectedRemoteImage.url,
                    onDismiss: {
                        self.selectedRemoteImage = nil
                    },
                    onDelete: selectedRemoteImageDeleteAction(for: selectedRemoteImage)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(10)
            }
        }
#if os(iOS)
        .toolbar(selectedRemoteImage == nil ? .visible : .hidden, for: .navigationBar)
#endif
    }
}

struct TradePartnerProfileRoute: Identifiable, Hashable {
    var userID: UUID

    var id: UUID { userID }
}
