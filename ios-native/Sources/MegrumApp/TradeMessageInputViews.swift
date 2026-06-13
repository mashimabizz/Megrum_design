import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeMessageInput: View {
    @Binding var text: String
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isSending: Bool
    var showsCounterProposal: Bool
    var onOpenSchedule: () -> Void
    var onSendArrivalStatus: (TradeArrivalQuickAction) -> Void
    var onOpenLocationPlaceholder: () -> Void
    var canUseCamera: Bool
    var onOpenOutfitCamera: () -> Void
    var onCounterProposal: () -> Void
    var onRequestLate: () -> Void
    var onRequestCancel: () -> Void
    var onReport: () -> Void
    var onSend: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            TradeMessageQuickActionStrip(
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: isSending,
                showsCounterProposal: showsCounterProposal,
                canUseCamera: canUseCamera,
                onOpenLocationPlaceholder: onOpenLocationPlaceholder,
                onSendArrivalStatus: onSendArrivalStatus,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onCounterProposal: onCounterProposal
            )

            TradeMessageComposerRow(
                text: $text,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: isSending,
                showsCounterProposal: showsCounterProposal,
                canUseCamera: canUseCamera,
                onOpenSchedule: onOpenSchedule,
                onSendArrivalStatus: onSendArrivalStatus,
                onOpenLocationPlaceholder: onOpenLocationPlaceholder,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onCounterProposal: onCounterProposal,
                onRequestLate: onRequestLate,
                onRequestCancel: onRequestCancel,
                onReport: onReport,
                onSend: onSend
            )
        }
    }
}

private struct TradeMessageQuickActionStrip: View {
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isSending: Bool
    var showsCounterProposal: Bool
    var canUseCamera: Bool
    var onOpenLocationPlaceholder: () -> Void
    var onSendArrivalStatus: (TradeArrivalQuickAction) -> Void
    var onOpenOutfitCamera: () -> Void
    var onCounterProposal: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                TradeMessageQuickActionChip(
                    title: "現在地を送る",
                    systemImage: "location.fill",
                    isSending: isSending,
                    action: onOpenLocationPlaceholder
                )
                TradeMessageQuickActionChip(
                    title: "向かっています",
                    systemImage: "paperplane.fill",
                    isSending: isSending
                ) {
                    onSendArrivalStatus(.enroute)
                }
                TradeMessageQuickActionChip(
                    title: "到着しました",
                    systemImage: "checkmark.circle.fill",
                    isSending: isSending
                ) {
                    onSendArrivalStatus(.arrived)
                }

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
                    TradeMessageQuickActionChipLabel(title: "服装写真", systemImage: "tshirt.fill")
                }
                .disabled(isSending)

                if showsCounterProposal {
                    TradeMessageQuickActionChip(
                        title: "条件を調整",
                        systemImage: "arrow.triangle.2.circlepath",
                        isSending: isSending,
                        action: onCounterProposal
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct TradeMessageComposerRow: View {
    @Binding var text: String
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
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
    var onSend: () -> Void

    private var isMessageEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            TradeMessageOverflowMenu(
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: isSending,
                showsCounterProposal: showsCounterProposal,
                canUseCamera: canUseCamera,
                onOpenSchedule: onOpenSchedule,
                onSendArrivalStatus: onSendArrivalStatus,
                onOpenLocationPlaceholder: onOpenLocationPlaceholder,
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

private struct TradeMessageOverflowMenu: View {
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
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

    var body: some View {
        Menu {
            Button(action: onOpenSchedule) {
                Label("スケジュール", systemImage: "calendar")
            }

            Menu {
                ForEach(TradeArrivalQuickAction.allCases) { action in
                    Button {
                        onSendArrivalStatus(action)
                    } label: {
                        Label(action.title, systemImage: action.systemImage)
                    }
                    .disabled(isSending)
                }
            } label: {
                Label("到着ステータス", systemImage: "checkmark.circle")
            }

            Button(action: onOpenLocationPlaceholder) {
                Label("現在地を共有", systemImage: "location.fill")
            }

#if os(iOS)
            Button(action: onOpenOutfitCamera) {
                Label("服装写真を撮る", systemImage: "camera.fill")
            }
            .disabled(!canUseCamera || isSending)
#endif

            PhotosPicker(selection: $selectedOutfitPhotoItem, matching: .images) {
                Label("服装写真を選ぶ", systemImage: "photo.on.rectangle")
            }
            .disabled(isSending)

            if showsCounterProposal {
                Button(action: onCounterProposal) {
                    Label("再打診", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Button(action: onRequestLate) {
                Label(TradeAssistanceRequestKind.late.title, systemImage: TradeAssistanceRequestKind.late.systemImage)
            }
            .accessibilityLabel(TradeAssistanceRequestKind.late.menuAccessibilityLabel)

            Button(action: onRequestCancel) {
                Label(TradeAssistanceRequestKind.cancel.title, systemImage: TradeAssistanceRequestKind.cancel.systemImage)
            }
            .accessibilityLabel(TradeAssistanceRequestKind.cancel.menuAccessibilityLabel)

            Button(role: .destructive, action: onReport) {
                Label("通報", systemImage: "exclamationmark.bubble")
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
