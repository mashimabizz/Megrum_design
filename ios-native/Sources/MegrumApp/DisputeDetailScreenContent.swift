import SwiftUI

struct DisputeDetailScreenContent: View {
    var state: DisputeDetailLoadState
    @Binding var replyDraft: DisputeReplyDraft
    var isSubmittingReply: Bool
    var isWithdrawing: Bool
    var onRetryLoad: () -> Void
    var onSubmitReply: () -> Void
    var onRequestWithdraw: () -> Void
    var onOpenLateRequest: () -> Void
    var onOpenCancellationRequest: () -> Void

    var body: some View {
        Group {
            switch state {
            case .loading:
                DisputeDetailLoadingStateView()
            case .loaded(let model):
                DisputeDetailLoadedList(
                    model: model,
                    replyDraft: $replyDraft,
                    isSubmittingReply: isSubmittingReply,
                    isWithdrawing: isWithdrawing,
                    onSubmitReply: onSubmitReply,
                    onRequestWithdraw: onRequestWithdraw,
                    onOpenLateRequest: onOpenLateRequest,
                    onOpenCancellationRequest: onOpenCancellationRequest
                )
            case .empty:
                DisputeDetailEmptyStateView()
            case .failed(let message):
                DisputeDetailErrorStateView(message: message, onRetry: onRetryLoad)
            }
        }
    }
}
