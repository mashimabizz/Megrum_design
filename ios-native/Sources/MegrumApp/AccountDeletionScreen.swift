import MegrumDesign
import SwiftUI

@MainActor
struct AccountDeletionScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onCompleted: () -> Void
    @FocusState private var isNoteFocused: Bool
    @State private var step: AccountDeletionStep = .warning
    @State private var selectedReasons: Set<AccountDeletionReason> = []
    @State private var note = ""
    @State private var validationMessage: String?
    @State private var showsFinalConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                switch step {
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
            isPresented: $showsFinalConfirmation,
            titleVisibility: .visible
        ) {
            Button("退会する", role: .destructive) {
                submit()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("退会申請後はアカウントが削除申請中になり、Megrumの通常利用ができなくなります。")
        }
        .onChange(of: selectedReasons) {
            validationMessage = nil
        }
        .onChange(of: note) {
            validationMessage = nil
        }
    }

    private var header: some View {
        AccountDeletionStepHeader(step: step)
    }

    private var reasonForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 0) {
                ForEach(AccountDeletionReason.allCases) { reason in
                    AccountDeletionReasonRow(
                        reason: reason,
                        isSelected: selectedReasons.contains(reason)
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

                    if note.isEmpty {
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
                    Text("\(note.count)/\(AccountDeletionDraftValidator.noteMaxLength)")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            }
            .accountDeletionCardStyle()
        }
    }

    @ViewBuilder
    private var validationErrorView: some View {
        if let validationMessage {
            AccountDeletionAlertLabel(message: validationMessage)
        } else if let errorMessage = appState.errorMessage {
            AccountDeletionAlertLabel(message: errorMessage)
        }
    }

    private var bottomBar: some View {
        AccountDeletionBottomBar(
            step: step,
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
            get: { note },
            set: { note = String($0.prefix(AccountDeletionDraftValidator.noteMaxLength)) }
        )
    }

    private func primaryAction() {
        switch step {
        case .warning:
            guard ongoingTradeCount == 0 else {
                validationMessage = "現在進行中の取引があるため退会できません"
                return
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                step = .reasons
            }
        case .reasons:
            if let message = AccountDeletionDraftValidator.validationMessage(
                reasons: Array(selectedReasons),
                note: note
            ) {
                validationMessage = message
                return
            }
            isNoteFocused = false
            showsFinalConfirmation = true
        }
    }

    private func returnToWarningStep() {
        withAnimation(.easeInOut(duration: 0.18)) {
            step = .warning
        }
    }

    private func submit() {
        let input = AccountDeletionRequestInput(
            reasons: Array(selectedReasons),
            note: note
        ).normalized

        Task {
            if await appState.requestAccountDeletion(input) {
                onCompleted()
            }
        }
    }

    private func toggle(_ reason: AccountDeletionReason) {
        if selectedReasons.contains(reason) {
            selectedReasons.remove(reason)
        } else {
            selectedReasons.insert(reason)
        }
        MegrumHaptics.selectionChanged()
    }
}
