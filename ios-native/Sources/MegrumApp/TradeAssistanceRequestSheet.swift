import MegrumDesign
import SwiftUI

struct TradeAssistanceRequestSheet: View {
    var kind: TradeAssistanceRequestKind
    var isSubmitting: Bool
    var onSubmit: (TradeAssistanceSystemIntent) async -> Void

    @State private var draft: TradeAssistanceRequestDraft

    init(
        kind: TradeAssistanceRequestKind,
        isSubmitting: Bool,
        onSubmit: @escaping (TradeAssistanceSystemIntent) async -> Void
    ) {
        self.kind = kind
        self.isSubmitting = isSubmitting
        self.onSubmit = onSubmit
        self._draft = State(initialValue: TradeAssistanceRequestDraft(kind: kind))
    }

    var body: some View {
        Form {
            Section {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(MegrumTheme.ink)

                if kind == .late {
                    Picker("遅れる見込み", selection: $draft.delayBucket) {
                        ForEach(TradeLateDelayBucket.allCases) { bucket in
                            Text(bucket.title)
                                .tag(bucket)
                                .accessibilityLabel(bucket.accessibilityLabel)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("遅れる見込み")
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
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel(kind.reasonAccessibilityLabel)
            }

            Section {
                TextEditor(text: $draft.note)
                    .frame(minHeight: 96)
                    .overlay(alignment: .topLeading) {
                        if draft.note.isEmpty {
                            Text(kind.notePlaceholder)
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel(kind.noteAccessibilityLabel)
            } header: {
                Text("補足")
            } footer: {
                Text("補足は任意です。送信後は取引チャットにシステムメッセージとして残ります。")
            }

            Section {
                Toggle(kind.acknowledgementText, isOn: $draft.acknowledgesImpact)
                    .accessibilityLabel(kind.acknowledgementAccessibilityLabel)
            }

            if let intent = draft.systemIntent {
                Section("取引チャットへの反映文") {
                    Text(intent.messageBody)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
                        .accessibilityLabel("\(kind.title)の送信内容")
                }
            }
        }
        .navigationTitle(kind.title)
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        guard let intent = draft.systemIntent else {
                            return
                        }
                        await onSubmit(intent)
                    }
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
}
