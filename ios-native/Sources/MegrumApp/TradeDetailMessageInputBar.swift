import MegrumCore
import PhotosUI
import SwiftUI

struct TradeDetailMessageInputBar: View {
    @Binding var text: String
    @Binding var selectedChatPhotoItem: PhotosPickerItem?
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isVisible: Bool
    var context: TradeMessageInputContext
    var onOpenSchedule: () -> Void
    var onSendArrivalStatus: (TradeArrivalQuickAction) -> Void
    var onOpenLocationPlaceholder: () -> Void
    var onOpenChatCamera: () -> Void
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
                selectedChatPhotoItem: $selectedChatPhotoItem,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                context: context,
                onOpenSchedule: onOpenSchedule,
                onSendArrivalStatus: onSendArrivalStatus,
                onOpenLocationPlaceholder: onOpenLocationPlaceholder,
                onOpenChatCamera: onOpenChatCamera,
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
