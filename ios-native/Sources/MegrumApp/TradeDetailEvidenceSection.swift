import Foundation
import MegrumCore
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
    var onOpenImage: (TradeEvidencePhoto) -> Void
    var onApprove: (TradeEvidencePhoto) -> Void
    var onRate: () -> Void

    var body: some View {
        if shouldShowEvidencePanel {
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

    private var shouldShowEvidencePanel: Bool {
        proposal.status == .agreed || proposal.status == .completed
    }
}
