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

private struct DisputeStatusHeader: View {
    var model: DisputeDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.status.systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(model.status.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.status.displayName)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(model.ticketNo)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                statusChip(title: "受付", value: model.submittedAt.formatted(date: .abbreviated, time: .shortened))
                if model.canSubmitReply {
                    statusChip(title: "反論", value: model.replyCountdownText())
                } else if let operatorDeadlineAt = model.operatorDeadlineAt, model.status == .arbitration {
                    statusChip(title: "運営", value: operatorDeadlineAt.formatted(date: .abbreviated, time: .shortened))
                } else if let resolvedAt = model.resolvedAt, model.status == .resolved || model.status == .withdrawn {
                    statusChip(title: "完了", value: resolvedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(model.statusDescription)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Text(model.nextActionText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        }
    }

    private func statusChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DisputeTimelineView: View {
    var entries: [DisputeTimelineEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        marker(for: entry)
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(lineColor(after: entry))
                                .frame(width: 2)
                                .frame(minHeight: 28)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(entry.detail)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        if let date = entry.date {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.76))
                        }
                    }
                    .padding(.bottom, index < entries.count - 1 ? 16 : 0)
                }
            }
        }
    }

    private func marker(for entry: DisputeTimelineEvent) -> some View {
        Image(systemName: markerSymbol(for: entry.state))
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(markerForeground(for: entry))
            .frame(width: 24, height: 24)
            .background(markerBackground(for: entry), in: Circle())
    }

    private func markerSymbol(for state: DisputeTimelineEventState) -> String {
        switch state {
        case .completed:
            "checkmark"
        case .current:
            "circle.fill"
        case .pending:
            "circle"
        }
    }

    private func markerForeground(for entry: DisputeTimelineEvent) -> Color {
        switch entry.state {
        case .completed, .current:
            .white
        case .pending:
            MegrumTheme.muted
        }
    }

    private func markerBackground(for entry: DisputeTimelineEvent) -> Color {
        switch entry.state {
        case .completed:
            MegrumTheme.ok
        case .current:
            entry.status.tint
        case .pending:
            MegrumTheme.muted.opacity(0.14)
        }
    }

    private func lineColor(after entry: DisputeTimelineEvent) -> Color {
        entry.state == .pending ? MegrumTheme.muted.opacity(0.18) : MegrumTheme.lavender.opacity(0.38)
    }
}

private struct DisputeMessageRow: View {
    var message: DisputeDetailMessageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(message.senderName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Text(message.body)
                .font(.body)
                .foregroundStyle(MegrumTheme.ink)

            if !message.photoURLs.isEmpty {
                Label("\(message.photoURLs.count)件の写真", systemImage: "photo.on.rectangle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DisputeEvidenceGroupView: View {
    var group: DisputeEvidenceGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(group.title, systemImage: "photo.stack.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text(group.ownerName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }

            ForEach(Array(group.photoURLs.enumerated()), id: \.offset) { index, url in
                if let link = URL(string: url), link.scheme != nil {
                    Link(destination: link) {
                        HStack {
                            Label("証跡写真 \(index + 1)", systemImage: "photo")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                } else {
                    Label("証跡写真 \(index + 1)", systemImage: "photo")
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            .font(.callout.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}

private struct DisputeReplyComposer: View {
    @Binding var draft: DisputeReplyDraft
    var isSubmitting: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $draft.body)
                .frame(minHeight: 124)
                .overlay(alignment: .topLeading) {
                    if draft.body.isEmpty {
                        Text("事実関係、到着時刻、チャットで確認できる内容を書いてください")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            Toggle("証跡やチャット内容も確認してほしい", isOn: $draft.includesEvidenceNote)

            if let validationMessage = draft.validationMessage, !draft.normalizedBody.isEmpty {
                Text(validationMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Button(action: onSubmit) {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("反論を送信", systemImage: "paperplane.fill")
                    }
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!draft.isSubmittable || isSubmitting)
            .opacity(draft.isSubmittable ? 1 : 0.45)
        }
        .padding(.vertical, 6)
    }
}
