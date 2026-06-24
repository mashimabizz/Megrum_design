import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeDetailEvidenceSection: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var evidencePhotos: [TradeEvidencePhoto]
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var evaluationState: TradeEvaluationPromptState
    var isAddingEvidence: Bool
    var isApproving: Bool
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
    var onOpenEvidenceList: () -> Void
    var onOpenImage: (URL) -> Void
    var onApprove: () -> Void
    var onRate: () -> Void

    var body: some View {
        if proposal.status == .agreed || proposal.status == .completed {
            TradeEvidencePanel(
                proposal: proposal,
                viewerID: viewerID,
                evidencePhotos: evidencePhotos,
                selectedPhotoItem: $selectedPhotoItem,
                evaluationState: evaluationState,
                isAddingEvidence: isAddingEvidence,
                isApproving: isApproving,
                canUseCamera: canUseCamera,
                onOpenCamera: onOpenCamera,
                onOpenEvidenceList: onOpenEvidenceList,
                onOpenImage: onOpenImage,
                onApprove: onApprove,
                onRate: onRate
            )
        }
    }
}

struct TradeEvidenceListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletePhoto: TradeEvidencePhoto?

    var proposal: TradeProposal
    var viewerID: UUID?
    var evidencePhotos: [TradeEvidencePhoto]
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var isAddingEvidence: Bool
    var deletingPhotoID: UUID?
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
    var onOpenImage: (URL) -> Void
    var onDelete: (TradeEvidencePhoto) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if evidencePhotos.isEmpty {
                        ContentUnavailableView(
                            "取引証跡はまだありません",
                            systemImage: "doc.viewfinder",
                            description: Text("交換後のグッズ写真を追加できます。")
                        )
                    } else {
                        ForEach(evidencePhotos) { photo in
                            evidencePhotoRow(photo)
                        }
                    }
                } header: {
                    Text("証跡写真")
                }

                Section {
                    Button {
                        dismiss()
                        DispatchQueue.main.async {
                            onOpenCamera()
                        }
                    } label: {
                        Label(isAddingEvidence ? "追加中" : "写真を撮って追加", systemImage: "camera.fill")
                    }
                    .disabled(isAddingEvidence || !canUseCamera)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("写真から追加", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isAddingEvidence)
                }
            }
            .navigationTitle("取引証跡")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "この証跡写真を削除しますか？",
                isPresented: Binding(
                    get: { pendingDeletePhoto != nil },
                    set: { isPresented in
                        if !isPresented {
                            pendingDeletePhoto = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let pendingDeletePhoto {
                        onDelete(pendingDeletePhoto)
                    }
                    pendingDeletePhoto = nil
                }
                Button("キャンセル", role: .cancel) {
                    pendingDeletePhoto = nil
                }
            } message: {
                Text("削除すると、取引証跡の一覧から外れます。")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func evidencePhotoRow(_ photo: TradeEvidencePhoto) -> some View {
        HStack(spacing: 12) {
            Button {
                onOpenImage(photo.photoURL)
            } label: {
                AsyncImage(url: photo.photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        MegrumTheme.sky.opacity(0.18)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                    case .empty:
                        MegrumTheme.sky.opacity(0.12)
                            .overlay {
                                ProgressView()
                            }
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(photo.isUploadedBy(viewerID) ? "あなたが追加" : "相手が追加")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                if let takenAt = photo.takenAt {
                    Text(takenAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Spacer()

            if canDelete(photo) {
                Button(role: .destructive) {
                    pendingDeletePhoto = photo
                } label: {
                    if deletingPhotoID == photo.id {
                        ProgressView()
                    } else {
                        Image(systemName: "trash")
                    }
                }
                .disabled(deletingPhotoID == photo.id)
                .accessibilityLabel("証跡写真を削除")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func canDelete(_ photo: TradeEvidencePhoto) -> Bool {
        proposal.status == .agreed && photo.isUploadedBy(viewerID)
    }
}
