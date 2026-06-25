import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeMessageQuickActionStrip: View {
    var actions: [TradeMessageQuickActionKind]
    @Binding var selectedChatPhotoItem: PhotosPickerItem?
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isSending: Bool
    var onOpenSchedule: () -> Void
    var canUseCamera: Bool
    var onOpenLocationPlaceholder: () -> Void
    var onSendArrivalStatus: (TradeArrivalQuickAction) -> Void
    var onOpenChatCamera: () -> Void
    var onOpenOutfitCamera: () -> Void
    var onCounterProposal: () -> Void
    var onRequestLate: () -> Void
    var onRequestCancel: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(actions) { action in
                    quickActionView(for: action)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func quickActionView(for action: TradeMessageQuickActionKind) -> some View {
        switch action {
        case .location:
            quickActionChip(action, onOpenLocationPlaceholder)
        case .arrival(let arrivalAction):
            quickActionChip(action) {
                onSendArrivalStatus(arrivalAction)
            }
        case .outfitPhoto:
            Menu {
#if os(iOS)
                Button(action: onOpenOutfitCamera) {
                    Label("カメラで撮る", systemImage: "camera.fill")
                }
                .disabled(!canUseCamera || isSending)
#endif

                PhotosPicker(selection: $selectedOutfitPhotoItem, matching: .images) {
                    Label("写真から選ぶ", systemImage: "photo.on.rectangle")
                }
                .disabled(isSending)
            } label: {
                TradeMessageQuickActionChipLabel(title: action.title, systemImage: action.systemImage)
            }
            .disabled(isSending)
        case .assistance(.late):
            quickActionChip(action, onRequestLate)
        case .assistance(.cancel):
            quickActionChip(action, onRequestCancel)
        case .schedule:
            quickActionChip(action, onOpenSchedule)
        case .counterProposal:
            quickActionChip(action, onCounterProposal)
        case .chatPhoto:
            Menu {
#if os(iOS)
                Button(action: onOpenChatCamera) {
                    Label("写真を撮る", systemImage: "camera.fill")
                }
                .disabled(!canUseCamera || isSending)
#endif

                PhotosPicker(selection: $selectedChatPhotoItem, matching: .images) {
                    Label("アルバムから選ぶ", systemImage: "photo.on.rectangle")
                }
                .disabled(isSending)
            } label: {
                TradeMessageQuickActionChipLabel(title: action.title, systemImage: action.systemImage)
            }
            .disabled(isSending)
            .accessibilityLabel("写真を送信")
        }
    }

    private func quickActionChip(_ action: TradeMessageQuickActionKind, _ handler: @escaping () -> Void) -> some View {
        TradeMessageQuickActionChip(
            title: action.title,
            systemImage: action.systemImage,
            isSending: isSending,
            action: handler
        )
    }
}

private struct TradeMessageQuickActionChip: View {
    var title: String
    var systemImage: String
    var isSending: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            TradeMessageQuickActionChipLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .disabled(isSending)
    }
}

private struct TradeMessageQuickActionChipLabel: View {
    var title: String
    var systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11.5, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.86), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
            }
    }
}
