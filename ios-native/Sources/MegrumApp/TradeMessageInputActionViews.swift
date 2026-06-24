import MegrumCore
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

struct TradeMessageOverflowMenu: View {
    var actions: [TradeMessageOverflowActionKind]
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

    var body: some View {
        Menu {
            ForEach(actions) { action in
                overflowActionView(for: action)
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 35, height: 35)
                .background(.white.opacity(0.9), in: Circle())
        }
        .accessibilityLabel("メッセージ操作")
    }

    @ViewBuilder
    private func overflowActionView(for action: TradeMessageOverflowActionKind) -> some View {
        switch action {
        case .arrivalStatusMenu:
            Menu {
                ForEach(TradeArrivalQuickAction.allCases) { arrivalAction in
                    Button {
                        onSendArrivalStatus(arrivalAction)
                    } label: {
                        Label(arrivalAction.title, systemImage: arrivalAction.systemImage)
                    }
                    .disabled(isSending)
                }
            } label: {
                Label("到着ステータス", systemImage: "checkmark.circle")
            }
        case .location:
            Button(action: onOpenLocationPlaceholder) {
                Label("現在地を共有", systemImage: "location.fill")
            }
        case .outfitCamera:
#if os(iOS)
            Button(action: onOpenOutfitCamera) {
                Label("服装写真を撮る", systemImage: "camera.fill")
            }
            .disabled(!canUseCamera || isSending)
#endif
        case .outfitLibrary:
            PhotosPicker(selection: $selectedOutfitPhotoItem, matching: .images) {
                Label("服装写真を選ぶ", systemImage: "photo.on.rectangle")
            }
            .disabled(isSending)
        case .assistance(let kind):
            Button(action: assistanceAction(for: kind)) {
                Label(kind.title, systemImage: kind.systemImage)
            }
            .accessibilityLabel(kind.menuAccessibilityLabel)
        case .schedule:
            Button(action: onOpenSchedule) {
                Label("スケジュール", systemImage: "calendar")
            }
        case .counterProposal:
            Button(action: onCounterProposal) {
                Label("条件を変えて再打診", systemImage: "arrow.triangle.2.circlepath")
            }
        case .chatCamera:
#if os(iOS)
            Button(action: onOpenChatCamera) {
                Label("写真を撮る", systemImage: "camera.fill")
            }
            .disabled(!canUseCamera || isSending)
#endif
        case .chatLibrary:
            PhotosPicker(selection: $selectedChatPhotoItem, matching: .images) {
                Label("アルバムから選ぶ", systemImage: "photo.on.rectangle")
            }
            .disabled(isSending)
        }
    }

    private func assistanceAction(for kind: TradeAssistanceRequestKind) -> () -> Void {
        switch kind {
        case .late:
            onRequestLate
        case .cancel:
            onRequestCancel
        }
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
