import PhotosUI
import SwiftUI

struct TradeDetailMessageInputBar: View {
    @Binding var text: String
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isVisible: Bool
    var isSending: Bool
    var showsCounterProposal: Bool
    var canUseCamera: Bool
    var onOpenSchedule: () -> Void
    var onSendArrivalStatus: (TradeArrivalQuickAction) -> Void
    var onOpenLocationPlaceholder: () -> Void
    var onOpenOutfitCamera: () -> Void
    var onCounterProposal: () -> Void
    var onRequestLate: () -> Void
    var onRequestCancel: () -> Void
    var onReport: () -> Void
    var onSendMessage: () -> Void

    var body: some View {
        if isVisible {
            TradeMessageInput(
                text: $text,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: isSending,
                showsCounterProposal: showsCounterProposal,
                onOpenSchedule: onOpenSchedule,
                onSendArrivalStatus: onSendArrivalStatus,
                onOpenLocationPlaceholder: onOpenLocationPlaceholder,
                canUseCamera: canUseCamera,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onCounterProposal: onCounterProposal,
                onRequestLate: onRequestLate,
                onRequestCancel: onRequestCancel,
                onReport: onReport,
                onSend: onSendMessage
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }
}
