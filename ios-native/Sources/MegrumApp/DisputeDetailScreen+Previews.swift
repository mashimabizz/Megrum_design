import SwiftUI

#if DEBUG
@MainActor
private enum DisputeDetailPreviewData {
    enum PreviewError: LocalizedError {
        case failed

        var errorDescription: String? {
            "通信状況を確認して、もう一度お試しください。"
        }
    }

    static let submittedAt = Date(timeIntervalSince1970: 1_800)

    static var model: DisputeDetailModel {
        DisputeDetailModel(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            proposalID: UUID(uuidString: "30000000-0000-0000-0000-000000000101")!,
            ticketNo: "DPT-260531-ABCDEF12",
            status: .replyWindow,
            category: .noshow,
            reporterName: "あなた",
            respondentName: "相手",
            factMemo: "待ち合わせ時刻を過ぎても到着連絡がありませんでした。",
            submittedAt: submittedAt,
            replyDeadlineAt: submittedAt.addingTimeInterval(86_400),
            messages: [
                DisputeDetailMessageModel(
                    id: UUID(uuidString: "30000000-0000-0000-0000-000000000201")!,
                    senderName: "相手",
                    body: "到着予定は取引チャットで共有済みです。",
                    createdAt: submittedAt.addingTimeInterval(1_200)
                )
            ]
        )
    }

    static func store(state: DisputeDetailLoadState) -> DisputeDetailStore {
        DisputeDetailStore(
            initialState: state,
            detail: {
                switch state {
                case .loading:
                    try await Task.sleep(nanoseconds: 30_000_000_000)
                    return model
                case .failed:
                    throw PreviewError.failed
                case .empty:
                    return nil
                default:
                    return model
                }
            },
            reply: { draft in
                let message = DisputeDetailMessageModel(
                    senderName: "あなた",
                    body: draft.normalizedBody,
                    createdAt: submittedAt.addingTimeInterval(1_800)
                )
                return model.replacing(messages: model.messages + [message])
            },
            withdraw: {
                model.replacing(
                    status: .withdrawn,
                    resolvedAt: submittedAt.addingTimeInterval(2_400),
                    resolutionSummary: "申告は取り下げられました。"
                )
            }
        )
    }
}

struct DisputeDetailScreen_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        Group {
            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .loading))
            }
            .previewDisplayName("Loading")

            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .loaded(DisputeDetailPreviewData.model)))
            }
            .previewDisplayName("Reply / Withdraw")

            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .empty))
            }
            .previewDisplayName("Empty")

            NavigationStack {
                DisputeDetailScreen(store: DisputeDetailPreviewData.store(state: .failed("通信状況を確認して、もう一度お試しください。")))
            }
            .previewDisplayName("Error")
        }
    }
}
#endif
