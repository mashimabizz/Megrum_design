import MegrumCore
import SwiftUI

struct DisputeDetailToolbarContent: ToolbarContent {
    var canWithdraw: Bool
    var isWithdrawing: Bool
    var onDismiss: () -> Void
    var onRequestWithdraw: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("閉じる", action: onDismiss)
        }

        if canWithdraw {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive, action: onRequestWithdraw) {
                    if isWithdrawing {
                        ProgressView()
                    } else {
                        Label("取り下げ", systemImage: "arrow.uturn.backward")
                    }
                }
            }
        }
    }
}

private struct DisputeDetailTradeRequestSheetModifier: ViewModifier {
    @Binding var presentedRequestKind: TradeRequestKind?
    var onSubmitTradeRequest: (TradeRequestDraft) async -> Bool

    func body(content: Content) -> some View {
        content.sheet(item: $presentedRequestKind) { kind in
            NavigationStack {
                TradeRequestSheet(kind: kind, onSubmit: onSubmitTradeRequest)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct DisputeDetailWithdrawConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onWithdraw: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "申告を取り下げますか？",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button("取り下げる", role: .destructive, action: onWithdraw)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("取り下げ後は、この申告への反論や仲裁確認を進められません。")
        }
    }
}

private struct DisputeDetailActionErrorAlertModifier: ViewModifier {
    var message: String?
    var onClear: () -> Void

    func body(content: Content) -> some View {
        content.alert(
            "操作を完了できませんでした",
            isPresented: Binding(
                get: { message != nil },
                set: { isPresented in
                    if !isPresented {
                        onClear()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel, action: onClear)
        } message: {
            Text(message ?? "")
        }
    }
}

extension View {
    func disputeDetailTradeRequestSheet(
        presentedRequestKind: Binding<TradeRequestKind?>,
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool
    ) -> some View {
        modifier(
            DisputeDetailTradeRequestSheetModifier(
                presentedRequestKind: presentedRequestKind,
                onSubmitTradeRequest: onSubmitTradeRequest
            )
        )
    }

    func disputeDetailWithdrawConfirmation(
        isPresented: Binding<Bool>,
        onWithdraw: @escaping () -> Void
    ) -> some View {
        modifier(
            DisputeDetailWithdrawConfirmationModifier(
                isPresented: isPresented,
                onWithdraw: onWithdraw
            )
        )
    }

    func disputeDetailActionErrorAlert(
        message: String?,
        onClear: @escaping () -> Void
    ) -> some View {
        modifier(
            DisputeDetailActionErrorAlertModifier(
                message: message,
                onClear: onClear
            )
        )
    }
}
