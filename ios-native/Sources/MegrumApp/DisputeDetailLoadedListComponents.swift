import MegrumDesign
import SwiftUI

struct DisputeStatusHeader: View {
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

struct DisputeTimelineView: View {
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

struct DisputeMessageRow: View {
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

struct DisputeEvidenceGroupView: View {
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

struct DisputeReplyComposer: View {
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
