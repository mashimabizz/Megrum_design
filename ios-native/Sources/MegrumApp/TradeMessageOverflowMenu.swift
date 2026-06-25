import MegrumDesign
import PhotosUI
import SwiftUI

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
