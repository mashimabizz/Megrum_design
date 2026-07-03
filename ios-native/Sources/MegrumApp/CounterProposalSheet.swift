import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct CounterProposalSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var draftState: CounterProposalDraftState

    private let conditionTagOptions = ["即日発送", "同日発送", "終演後OK", "グッズ販売中OK"]

    init(appState: MegrumAppState, proposal: TradeProposal) {
        self.appState = appState
        self.proposal = proposal
        _draftState = State(initialValue: CounterProposalDraftState(proposal: proposal))
    }

    private var viewerID: UUID? {
        appState.viewer?.id
    }

    private var isSubmitting: Bool {
        appState.isCreatingProposal
    }

    private var offeredCount: Int {
        guard let viewerID else {
            return 0
        }
        return proposal.goodsOffered(by: viewerID)?.count ?? 0
    }

    private var requestedCount: Int {
        guard let viewerID else {
            return 0
        }
        return proposal.goodsRequested(by: viewerID)?.count ?? 0
    }

    private var availableConditionTags: [String] {
        CounterProposalDraftState.availableConditionTags(
            defaultOptions: conditionTagOptions,
            proposalTags: proposal.conditionTags
        )
    }

    private var orderedConditionTags: [String] {
        draftState.orderedConditionTags(in: availableConditionTags)
    }

    private var canSubmit: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.counterProposalInput(
            from: viewerID,
            exchangeMethod: draftState.exchangeMethod,
            conditionTags: orderedConditionTags,
            message: draftState.message
        ) != nil
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("私が出す", value: "\(offeredCount)件")
                LabeledContent("受け取る", value: "\(requestedCount)件")
            } header: {
                Text("元の内容をコピー")
            } footer: {
                Text("提示物は元の打診から引き継ぎます。条件だけ変更して相手に返せます。")
            }

            Section("交換手段") {
                Picker("交換手段", selection: $draftState.exchangeMethod) {
                    ForEach(ExchangeMethod.allCases) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("交換条件シリーズ") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                    ForEach(availableConditionTags, id: \.self) { tag in
                        Button {
                            toggleConditionTag(tag)
                        } label: {
                            HStack(spacing: 6) {
                                Text(tag)
                                if draftState.selectedConditionTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .foregroundStyle(draftState.selectedConditionTags.contains(tag) ? .white : MegrumTheme.ink)
                            .background(
                                draftState.selectedConditionTags.contains(tag) ? MegrumTheme.lavender : .white.opacity(0.72),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("メッセージ") {
                TextEditor(text: $draftState.message)
                    .frame(minHeight: 96)
                    .overlay(alignment: .topLeading) {
                        if draftState.message.isEmpty {
                            Text("変更したい条件を相手に伝える")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Button {
                    Task {
                        await createCounterProposal()
                    }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("この条件で再打診")
                        }
                    }
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                }
                .disabled(!canSubmit || isSubmitting)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas)
        .navigationTitle("条件を変えて再打診")
        .megrumInlineNavigationTitle()
    }

    private func toggleConditionTag(_ tag: String) {
        draftState.toggleConditionTag(tag)
    }

    private func createCounterProposal() async {
        guard let viewerID else {
            return
        }
        guard let input = proposal.counterProposalInput(
            from: viewerID,
            exchangeMethod: draftState.exchangeMethod,
            conditionTags: orderedConditionTags,
            message: draftState.submittedMessage
        ) else {
            return
        }

        let created = await appState.createProposal(input)
        if created {
            dismiss()
        }
    }
}
