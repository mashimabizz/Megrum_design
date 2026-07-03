import MegrumDesign
import SwiftUI

@MainActor
struct AccountDeletionScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onCompleted: () -> Void
    @FocusState private var isNoteFocused: Bool
    @State private var draftState = AccountDeletionDraftState()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                switch draftState.step {
                case .warning:
                    AccountDeletionWarningContent(ongoingTradeCount: ongoingTradeCount)
                case .reasons:
                    reasonForm
                }

                validationErrorView
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 108)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("退会")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isNoteFocused = false
                }
                .font(.body.weight(.semibold))
            }
            #endif
        }
        .confirmationDialog(
            "退会しますか？",
            isPresented: $draftState.showsFinalConfirmation,
            titleVisibility: .visible
        ) {
            Button("退会する", role: .destructive) {
                submit()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("退会申請後はアカウントが削除申請中になり、Megrumの通常利用ができなくなります。")
        }
        .onChange(of: draftState.selectedReasons) {
            draftState.clearValidationMessage()
        }
        .onChange(of: draftState.note) {
            draftState.clearValidationMessage()
        }
    }

    private var header: some View {
        AccountDeletionStepHeader(step: draftState.step)
    }

    private var reasonForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 0) {
                ForEach(AccountDeletionReason.allCases) { reason in
                    AccountDeletionReasonRow(
                        reason: reason,
                        isSelected: draftState.selectedReasons.contains(reason)
                    ) {
                        toggle(reason)
                    }
                    if reason != AccountDeletionReason.allCases.last {
                        Divider()
                            .padding(.leading, 18)
                    }
                }
            }
            .accountDeletionCardStyle()

            VStack(alignment: .leading, spacing: 10) {
                Text("メモ")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: noteBinding)
                        .focused($isNoteFocused)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(minHeight: 128)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .scrollContentBackground(.hidden)
                        .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if draftState.note.isEmpty {
                        Text("任意で詳しく教えてください")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted.opacity(0.62))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                }

                HStack {
                    Text("個人情報や取引相手を特定できる内容は書かないでください。")
                    Spacer()
                    Text("\(draftState.note.count)/\(AccountDeletionDraftValidator.noteMaxLength)")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            }
            .accountDeletionCardStyle()
        }
    }

    @ViewBuilder
    private var validationErrorView: some View {
        if let validationMessage = draftState.validationMessage {
            AccountDeletionAlertLabel(message: validationMessage)
        } else if let errorMessage = appState.errorMessage {
            AccountDeletionAlertLabel(message: errorMessage)
        }
    }

    private var bottomBar: some View {
        AccountDeletionBottomBar(
            step: draftState.step,
            isRequesting: appState.isRequestingAccountDeletion,
            ongoingTradeCount: ongoingTradeCount,
            onBack: returnToWarningStep,
            onPrimaryAction: primaryAction
        )
    }

    private var ongoingTradeCount: Int {
        AccountDeletionEligibility
            .ongoingProposals(in: appState.proposals, viewerID: appState.viewer?.id)
            .count
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { draftState.note },
            set: { draftState.setNote($0) }
        )
    }

    private func primaryAction() {
        switch draftState.step {
        case .warning:
            guard ongoingTradeCount == 0 else {
                draftState.setOngoingTradeValidationMessage()
                return
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                draftState.moveToReasonsStep()
            }
        case .reasons:
            guard draftState.validateReasonsStep() else {
                return
            }
            isNoteFocused = false
            draftState.requestFinalConfirmation()
        }
    }

    private func returnToWarningStep() {
        withAnimation(.easeInOut(duration: 0.18)) {
            draftState.returnToWarningStep()
        }
    }

    private func submit() {
        let input = draftState.submissionInput

        Task {
            if await appState.requestAccountDeletion(input) {
                onCompleted()
            }
        }
    }

    private func toggle(_ reason: AccountDeletionReason) {
        draftState.toggle(reason)
        MegrumHaptics.selectionChanged()
    }
}
