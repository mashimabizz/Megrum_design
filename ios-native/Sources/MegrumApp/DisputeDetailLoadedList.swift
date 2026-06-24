import MegrumDesign
import SwiftUI

struct DisputeDetailLoadedList: View {
    var model: DisputeDetailModel
    @Binding var replyDraft: DisputeReplyDraft
    var isSubmittingReply: Bool
    var isWithdrawing: Bool
    var onSubmitReply: () -> Void
    var onRequestWithdraw: () -> Void
    var onOpenLateRequest: () -> Void
    var onOpenCancellationRequest: () -> Void

    var body: some View {
        List {
            Section {
                DisputeStatusHeader(model: model)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)

            Section("タイムライン") {
                DisputeTimelineView(entries: model.timeline)
                    .padding(.vertical, 4)
            }

            Section("申告内容") {
                LabeledContent("受付番号", value: model.ticketNo)
                LabeledContent("カテゴリ", value: model.category?.displayName ?? "未設定")
                LabeledContent("申告者", value: model.reporterName)
                LabeledContent("相手", value: model.respondentName)

                if let factMemo = model.factMemo?.trimmingCharacters(in: .whitespacesAndNewlines), !factMemo.isEmpty {
                    Text(factMemo)
                        .font(.body)
                        .foregroundStyle(MegrumTheme.ink)
                        .padding(.vertical, 4)
                }
            }

            Section("証跡") {
                if model.evidenceGroups.isEmpty {
                    ContentUnavailableView(
                        "添付された証跡はありません",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("取引チャットや交換証跡の内容も運営確認の対象です。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    ForEach(model.evidenceGroups) { group in
                        DisputeEvidenceGroupView(group: group)
                    }
                }
            }

            if let resolutionSummary = model.resolutionSummary {
                Section("仲裁結果") {
                    Text(resolutionSummary)
                        .foregroundStyle(MegrumTheme.ink)
                }
            }

            Section("返信履歴") {
                if model.messages.isEmpty {
                    Text("まだ返信はありません。")
                        .font(.callout)
                        .foregroundStyle(MegrumTheme.muted)
                } else {
                    ForEach(model.messages) { message in
                        DisputeMessageRow(message: message)
                    }
                }
            }

            if model.canSubmitReply {
                Section {
                    DisputeReplyComposer(
                        draft: $replyDraft,
                        isSubmitting: isSubmittingReply,
                        onSubmit: onSubmitReply
                    )
                } header: {
                    Text("反論")
                } footer: {
                    Text(model.replyCountdownText())
                }
            }

            Section {
                if model.canWithdraw {
                    Button(role: .destructive, action: onRequestWithdraw) {
                        Label("申告を取り下げる", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(isWithdrawing)
                } else if let message = model.withdrawalUnavailableText {
                    Label(message, systemImage: "lock.fill")
                        .font(.callout)
                        .foregroundStyle(MegrumTheme.muted)
                }

                Button(action: onOpenLateRequest) {
                    Label(TradeRequestKind.late.title, systemImage: TradeRequestKind.late.systemImage)
                }

                Button(role: .destructive, action: onOpenCancellationRequest) {
                    Label(TradeRequestKind.cancellation.title, systemImage: TradeRequestKind.cancellation.systemImage)
                }
            } header: {
                Text("操作")
            } footer: {
                Text("遅刻やキャンセルは取引チャット側へ反映するための独立した申請として扱います。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }
}

private extension View {
    @ViewBuilder
    func disputeDetailListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }
}
