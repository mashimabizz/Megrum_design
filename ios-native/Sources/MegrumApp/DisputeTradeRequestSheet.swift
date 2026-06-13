import MegrumDesign
import SwiftUI

enum TradeRequestKind: String, CaseIterable, Identifiable, Sendable {
    case cancellation
    case late

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cancellation:
            "キャンセル申請"
        case .late:
            "遅刻申請"
        }
    }

    var shortTitle: String {
        switch self {
        case .cancellation:
            "キャンセル"
        case .late:
            "遅刻"
        }
    }

    var systemImage: String {
        switch self {
        case .cancellation:
            "xmark.circle.fill"
        case .late:
            "clock.badge.exclamationmark.fill"
        }
    }

    var reasonPlaceholder: String {
        switch self {
        case .cancellation:
            "キャンセルが必要な理由"
        case .late:
            "遅れる理由と到着見込み"
        }
    }

    var acknowledgementText: String {
        switch self {
        case .cancellation:
            "キャンセル後の取引継続可否は相手と運営の確認が必要です。"
        case .late:
            "30分を超える遅刻では、相手にキャンセル権が発生する可能性があります。"
        }
    }
}

struct TradeRequestDraft: Equatable, Sendable {
    var kind: TradeRequestKind
    var reason: String = ""
    var estimatedDelayMinutes = 10
    var acknowledgesImpact = false

    var normalizedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        guard !normalizedReason.isEmpty, acknowledgesImpact else {
            return false
        }

        switch kind {
        case .cancellation:
            return true
        case .late:
            return (5...180).contains(estimatedDelayMinutes)
        }
    }

    var systemMessageBody: String? {
        guard isSubmittable else {
            return nil
        }

        switch kind {
        case .cancellation:
            return "キャンセル申請: \(normalizedReason)"
        case .late:
            return "遅刻申請: \(estimatedDelayMinutes)分ほど遅れます。\(normalizedReason)"
        }
    }
}

struct TradeRequestSheet: View {
    var kind: TradeRequestKind
    var onSubmit: (TradeRequestDraft) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var draft: TradeRequestDraft
    @State private var isSubmitting = false

    init(kind: TradeRequestKind, onSubmit: @escaping (TradeRequestDraft) async -> Bool) {
        self.kind = kind
        self.onSubmit = onSubmit
        self._draft = State(initialValue: TradeRequestDraft(kind: kind))
    }

    var body: some View {
        Form {
            Section {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(MegrumTheme.ink)

                if kind == .late {
                    Stepper(value: $draft.estimatedDelayMinutes, in: 5...180, step: 5) {
                        LabeledContent("遅れる見込み", value: "\(draft.estimatedDelayMinutes)分")
                    }
                }
            } footer: {
                Text(kind.acknowledgementText)
            }

            Section("理由") {
                TextEditor(text: $draft.reason)
                    .frame(minHeight: 132)
                    .overlay(alignment: .topLeading) {
                        if draft.reason.isEmpty {
                            Text(kind.reasonPlaceholder)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Toggle(kind.acknowledgementText, isOn: $draft.acknowledgesImpact)
            }

            if let message = draft.systemMessageBody {
                Section("取引チャットへの反映文") {
                    Text(message)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
                }
            }
        }
        .navigationTitle(kind.title)
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    submit()
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("送信")
                    }
                }
                .disabled(!draft.isSubmittable || isSubmitting)
            }
        }
    }

    private func submit() {
        guard draft.isSubmittable, !isSubmitting else {
            return
        }

        Task {
            isSubmitting = true
            let sent = await onSubmit(draft)
            isSubmitting = false
            if sent {
                dismiss()
            }
        }
    }
}
