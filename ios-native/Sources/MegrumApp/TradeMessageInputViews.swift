import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeMessageInput: View {
    @Binding var text: String
    @Binding var selectedChatPhotoItem: PhotosPickerItem?
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
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
    var onSend: () -> Void

    @State private var isComposerFocused = false

    var body: some View {
        VStack(spacing: 8) {
            if context.shouldShowQuickActions(isComposerFocused: isComposerFocused) {
                TradeMessageQuickActionStrip(
                    actions: context.quickActions,
                    selectedChatPhotoItem: $selectedChatPhotoItem,
                    selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                    isSending: context.isSending,
                    onOpenSchedule: onOpenSchedule,
                    canUseCamera: context.canUseCamera,
                    onOpenLocationPlaceholder: onOpenLocationPlaceholder,
                    onSendArrivalStatus: onSendArrivalStatus,
                    onOpenChatCamera: onOpenChatCamera,
                    onOpenOutfitCamera: onOpenOutfitCamera,
                    onCounterProposal: onCounterProposal,
                    onRequestLate: onRequestLate,
                    onRequestCancel: onRequestCancel
                )
            }

            TradeMessageComposerRow(
                text: $text,
                overflowActions: context.overflowActions,
                selectedChatPhotoItem: $selectedChatPhotoItem,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: context.isSending,
                canUseCamera: context.canUseCamera,
                onOpenSchedule: onOpenSchedule,
                onSendArrivalStatus: onSendArrivalStatus,
                onOpenLocationPlaceholder: onOpenLocationPlaceholder,
                onOpenChatCamera: onOpenChatCamera,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onCounterProposal: onCounterProposal,
                onRequestLate: onRequestLate,
                onRequestCancel: onRequestCancel,
                onReport: onReport,
                onSend: onSend,
                onFocusChange: { isComposerFocused = $0 }
            )
        }
    }
}

private struct TradeMessageComposerRow: View {
    @Binding var text: String
    var overflowActions: [TradeMessageOverflowActionKind]
    @Binding var selectedChatPhotoItem: PhotosPickerItem?
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isSending: Bool
    var canUseCamera: Bool
    var onOpenSchedule: () -> Void
    var onSendArrivalStatus: (TradeArrivalQuickAction) -> Void
    var onOpenLocationPlaceholder: () -> Void
    var onOpenChatCamera: () -> Void
    var onOpenOutfitCamera: () -> Void
    var onCounterProposal: () -> Void
    var onRequestLate: () -> Void
    var onRequestCancel: () -> Void
    var onReport: () -> Void
    var onSend: () -> Void
    var onFocusChange: (Bool) -> Void
    @FocusState private var isTextFieldFocused: Bool

    private var isMessageEmpty: Bool {
        text.isBlank
    }

    var body: some View {
        HStack(spacing: 10) {
            TradeMessageOverflowMenu(
                actions: overflowActions,
                selectedChatPhotoItem: $selectedChatPhotoItem,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: isSending,
                canUseCamera: canUseCamera,
                onOpenSchedule: onOpenSchedule,
                onSendArrivalStatus: onSendArrivalStatus,
                onOpenLocationPlaceholder: onOpenLocationPlaceholder,
                onOpenChatCamera: onOpenChatCamera,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onCounterProposal: onCounterProposal,
                onRequestLate: onRequestLate,
                onRequestCancel: onRequestCancel,
                onReport: onReport
            )

            TextField("メッセージ…", text: $text, axis: .vertical)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { _, focused in
                    onFocusChange(focused)
                }

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 35, height: 35)
                .background(MegrumTheme.lavender, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(isMessageEmpty || isSending)
            .opacity(isMessageEmpty ? 0.45 : 1)
        }
    }
}
