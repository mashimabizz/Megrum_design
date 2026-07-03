import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeEvidenceListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var presentationState = TradeEvidenceListPresentationState()

    var proposal: TradeProposal
    var viewerID: UUID?
    var evidencePhotos: [TradeEvidencePhoto]
    var isAddingEvidence: Bool
    var isApproving: Bool
    var deletingPhotoID: UUID?
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
    var onOpenPhotoLibrary: () -> Void
    var onDelete: (TradeEvidencePhoto) async -> Bool
    var onApprove: (TradeEvidencePhoto) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if displayedEvidencePhotos.isEmpty {
                        ContentUnavailableView(
                            "取引証跡はまだありません",
                            systemImage: "doc.viewfinder",
                            description: Text("交換後のグッズ写真を追加できます。")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 34)
                    } else {
                        TradeEvidencePhotoList(
                            proposal: proposal,
                            photos: displayedEvidencePhotos,
                            viewerID: viewerID,
                            showsApprovalControls: true,
                            isApproving: isApproving,
                            deletingPhotoID: deletingPhotoID,
                            onOpenImage: { photo in
                                presentationState.openPhoto(photo)
                            },
                            onApprove: onApprove,
                            onDelete: { photo in
                                presentationState.requestDelete(photo)
                            }
                        )
                    }

                    VStack(spacing: 10) {
                        Button {
                            dismiss()
                            DispatchQueue.main.async {
                                onOpenCamera()
                            }
                        } label: {
                            Label(isAddingEvidence ? "追加中" : "写真を撮って追加", systemImage: "camera.fill")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(MegrumTheme.lavender, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(isAddingEvidence || !canUseCamera)

                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                onOpenPhotoLibrary()
                            }
                        } label: {
                            Label("写真から追加", systemImage: "photo.on.rectangle")
                                .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(.white.opacity(0.86), in: Capsule())
                                .foregroundStyle(MegrumTheme.ink)
                        }
                        .buttonStyle(.plain)
                        .disabled(isAddingEvidence)
                    }
                }
                .padding(18)
                .padding(.bottom, 126)
            }
            .navigationTitle("取引証跡")
            .safeAreaInset(edge: .bottom) {
                approvalFooter
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
#if os(iOS)
            .toolbar(presentationState.presentedPhoto == nil ? .visible : .hidden, for: .navigationBar)
#endif
            .confirmationDialog(
                "この証跡写真を削除しますか？",
                isPresented: Binding(
                    get: { presentationState.isDeleteConfirmationPresented },
                    set: { isPresented in
                        if !isPresented {
                            presentationState.clearPendingDelete()
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let pendingDeletePhoto = presentationState.pendingDeletePhoto {
                        deletePhoto(pendingDeletePhoto)
                    }
                    presentationState.clearPendingDelete()
                }
                Button("キャンセル", role: .cancel) {
                    presentationState.clearPendingDelete()
                }
            } message: {
                Text("削除すると、取引証跡の一覧から外れます。")
            }
        }
        .overlay {
            if let presentedPhoto = presentationState.presentedPhoto {
                FullScreenRemoteImageView(
                    url: presentedPhoto.photoURL,
                    onDismiss: {
                        presentationState.clearPresentedPhoto()
                    },
                    onDelete: deleteAction(for: presentedPhoto)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(10)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var displayedEvidencePhotos: [TradeEvidencePhoto] {
        presentationState.displayedPhotos(from: evidencePhotos)
    }

    private func deletePhoto(_ photo: TradeEvidencePhoto) {
        presentationState.markDeleted(photo)
        Task {
            _ = await onDelete(photo)
        }
    }

    private func deleteAction(for photo: TradeEvidencePhoto) -> (() -> Void)? {
        guard proposal.status == .agreed,
              photo.isUploadedBy(viewerID),
              deletingPhotoID != photo.id else {
            return nil
        }
        return {
            deletePhoto(photo)
        }
    }

    private var myApproved: Bool {
        guard let viewerID else {
            return false
        }
        if !displayedEvidencePhotos.isEmpty {
            return displayedEvidencePhotos.allSatisfy { $0.isApproved(by: viewerID, in: proposal) }
        }
        return proposal.approvedBy(viewerID)
    }

    private var partnerApproved: Bool {
        guard let viewerID, let partnerID = proposal.partnerID(for: viewerID) else {
            return false
        }
        if !displayedEvidencePhotos.isEmpty {
            return displayedEvidencePhotos.allSatisfy { $0.isApproved(by: partnerID, in: proposal) }
        }
        return proposal.partnerApproved(for: viewerID)
    }

    private var canApprove: Bool {
        proposal.status == .agreed && displayedEvidencePhotos.contains { !$0.isApproved(by: viewerID, in: proposal) }
    }

    @ViewBuilder
    private var approvalFooter: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TradeEvidenceApprovalChip(title: "あなた", isApproved: myApproved)
                TradeEvidenceApprovalChip(title: "相手", isApproved: partnerApproved)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if canApprove {
                Text("承認が必要な画像の「承認」を押してください")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(.white.opacity(0.86), in: Capsule())
            } else if proposal.status == .completed {
                Label("取引が完了しました", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ok)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.white.opacity(0.86), in: Capsule())
            } else if myApproved {
                Text("相手の承認を待っています")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.white.opacity(0.86), in: Capsule())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.regularMaterial)
    }
}
