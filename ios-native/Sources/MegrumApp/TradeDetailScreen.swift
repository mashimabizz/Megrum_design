import Foundation
import MegrumCore
import PhotosUI
import SwiftUI

struct TradeDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @State var interactionState = TradeDetailInteractionState()
    @State var photoPresentationState = TradeDetailPhotoPresentationState()
    @State var routePresentationState = TradeDetailRoutePresentationState()
    @StateObject var locationState = MegrumLocationState()

    var body: some View {
        bodyBeforeDialogs
        .confirmationDialog(
            "この打診を断りますか？",
            isPresented: $routePresentationState.isShowingRejectConfirmation,
            titleVisibility: .visible
        ) {
            Button("断る", role: .destructive, action: rejectCurrentProposal)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("断った後は、この打診では取引を進められません。")
        }
        .confirmationDialog(
            "証跡写真を追加",
            isPresented: $photoPresentationState.isShowingEvidenceSourceDialog,
            titleVisibility: .visible
        ) {
            Button("写真を撮る", action: presentEvidenceCamera)
            .disabled(appState.addingEvidenceProposalID == currentProposal.id || !canUseCamera)

            Button("アルバムから選ぶ", action: presentEvidencePhotoLibrary)
            .disabled(appState.addingEvidenceProposalID == currentProposal.id)

            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("交換したグッズがわかる写真を追加します。")
        }
        .photosPicker(
            isPresented: $photoPresentationState.isShowingEvidencePhotoLibraryPicker,
            selection: evidencePhotoPickerSelection,
            matching: .images
        )
        .photosPicker(
            isPresented: $photoPresentationState.isShowingChatPhotoLibraryPicker,
            selection: $photoPresentationState.selectedChatPhotoItem,
            matching: .images
        )
        .photosPicker(
            isPresented: $photoPresentationState.isShowingOutfitPhotoLibraryPicker,
            selection: $photoPresentationState.selectedOutfitPhotoItem,
            matching: .images
        )
        .sheet(isPresented: $routePresentationState.isShowingEvidenceList) {
            TradeEvidenceListSheet(
                proposal: currentProposal,
                viewerID: viewerID,
                evidencePhotos: appState.evidencePhotos(for: currentProposal),
                isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
                isApproving: appState.approvingEvidenceProposalID == currentProposal.id,
                deletingPhotoID: appState.deletingEvidencePhotoID,
                canUseCamera: canUseCamera,
                onOpenCamera: presentEvidenceCamera,
                onOpenPhotoLibrary: presentEvidencePhotoLibrary,
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
        .sheet(isPresented: $photoPresentationState.isShowingEvidenceCamera) {
            NativeCameraCaptureView { imageData in
                handleCapturedEvidenceImage(imageData)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $photoPresentationState.isShowingOutfitCamera) {
            NativeCameraCaptureView { imageData in
                handleCapturedOutfitImage(imageData)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $photoPresentationState.isShowingChatCamera) {
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
                        routePresentationState.isShowingDisputePage = true
                    } label: {
                        Label("通報", systemImage: "exclamationmark.bubble")
                    }
                    .disabled(appState.filingDisputeProposalID == currentProposal.id)
                }
            }
        }
        .overlay {
            if let selectedRemoteImage = routePresentationState.selectedRemoteImage {
                FullScreenRemoteImageView(
                    url: selectedRemoteImage.url,
                    onDismiss: {
                        routePresentationState.clearSelectedRemoteImage()
                    },
                    onDelete: selectedRemoteImageDeleteAction(for: selectedRemoteImage)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(10)
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = interactionState.toastMessage {
                MeguriToastView(message: toastMessage)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(9)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: interactionState.toastMessage)
#if os(iOS)
        .toolbar(routePresentationState.selectedRemoteImage == nil ? .visible : .hidden, for: .navigationBar)
#endif
    }
}

struct TradePartnerProfileRoute: Identifiable, Hashable {
    var userID: UUID

    var id: UUID { userID }
}
