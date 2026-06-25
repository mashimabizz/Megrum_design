import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeEvidencePanel: View {
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

    private var myApproved: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.approvedBy(viewerID)
    }

    private var partnerApproved: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.partnerApproved(for: viewerID)
    }

    private var hasEvidencePhotos: Bool {
        !evidencePhotos.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("取引証跡")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()

                if proposal.status == .completed {
                    Text("完了")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(MegrumTheme.ok, in: Capsule())
                }
            }

            if hasEvidencePhotos {
                TradeEvidencePhotoCarousel(
                    photos: evidencePhotos,
                    viewerID: viewerID,
                    onOpenImage: onOpenImage
                )

                Button(action: onOpenEvidenceList) {
                    Label("証跡一覧・追加", systemImage: "doc.viewfinder")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white.opacity(0.76), in: Capsule())
                        .foregroundStyle(MegrumTheme.ink)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TradeEvidenceApprovalChip(title: "あなた", isApproved: myApproved)
                TradeEvidenceApprovalChip(title: "相手", isApproved: partnerApproved)
            }

            if proposal.status == .completed {
                if evaluationState.hasSubmittedEvaluation {
                    Label("評価送信済み", systemImage: "star.fill")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ok)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.white.opacity(0.72), in: Capsule())
                        .accessibilityLabel("評価送信済み")
                } else {
                    Button(action: onRate) {
                        Label("評価を送信", systemImage: "star.fill")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(MegrumTheme.lavender, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            } else if !hasEvidencePhotos {
                Button(action: onOpenCamera) {
                    Label(isAddingEvidence ? "追加中" : "交換後にグッズを撮影", systemImage: "camera.fill")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(MegrumTheme.lavender, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isAddingEvidence || !canUseCamera)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("写真から選ぶ", systemImage: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white.opacity(0.76), in: Capsule())
                        .foregroundStyle(MegrumTheme.ink)
                }
                .buttonStyle(.plain)
                .disabled(isAddingEvidence)
            } else if !myApproved {
                Button(action: onApprove) {
                    Group {
                        if isApproving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("証跡を承認", systemImage: "checkmark.seal.fill")
                        }
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isApproving)
            } else {
                Text("相手の承認を待っています")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white.opacity(0.68), in: Capsule())
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        }
    }
}
