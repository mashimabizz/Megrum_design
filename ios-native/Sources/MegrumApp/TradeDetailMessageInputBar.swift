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
    var onOpenChatLibrary: () -> Void
    var onOpenOutfitCamera: () -> Void
    var onOpenOutfitLibrary: () -> Void
    var onCounterProposal: () -> Void
    var onRequestLate: () -> Void
    var onRequestCancel: () -> Void
    var onReport: () -> Void
    var onSendMessage: () -> Void
    var onFocusChange: (Bool) -> Void = { _ in }

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
                onOpenChatLibrary: onOpenChatLibrary,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onOpenOutfitLibrary: onOpenOutfitLibrary,
                onCounterProposal: onCounterProposal,
                onRequestLate: onRequestLate,
                onRequestCancel: onRequestCancel,
                onReport: onReport,
                onSend: onSendMessage,
                onFocusChange: onFocusChange
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }
}
