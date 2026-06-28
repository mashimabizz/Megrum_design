import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct PaymentSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.megrumSlidePresentationDismiss) private var slideDismiss
    @FocusState private var focusedField: PaymentSettingsField?
    @State private var draft = PaymentSettingsDraft.empty
    @State private var validationMessage: String?
    @State private var hasUserEditedDraft = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PaymentSettingsSectionTitle("対応できる方法")
                PaymentSettingsMethodsCard(
                    selectedMethods: draft.methods,
                    otherNote: otherNoteBinding,
                    focusedField: $focusedField,
                    onToggleMethod: toggleMethod
                )

                if draft.contains(.bankTransfer) {
                    PaymentSettingsSectionTitle("銀行振込の受け取り口座")
                    PaymentSettingsBankCard(
                        bankName: textBinding(\.bankName),
                        bankBranchName: textBinding(\.bankBranchName),
                        bankAccountType: textBinding(\.bankAccountType),
                        bankAccountNumber: textBinding(\.bankAccountNumber),
                        bankAccountHolder: textBinding(\.bankAccountHolder),
                        focusedField: $focusedField
                    )
                }

                PaymentSettingsValidationErrorView(
                    validationMessage: validationMessage,
                    appErrorMessage: appState.errorMessage
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 104)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("支払い方法の設定")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
                .font(.body.weight(.semibold))
            }
            #endif
        }
        .safeAreaInset(edge: .bottom) {
            PaymentSettingsBottomBar(
                isSaving: appState.isSavingPaymentSettings,
                onCancel: closeScreen,
                onSave: save
            )
        }
        .task {
            applyCurrentValues(force: true)
            await appState.loadPaymentSettings()
            applyCurrentValues()
        }
        .onChange(of: appState.viewer) {
            applyCurrentValues()
        }
        .onChange(of: appState.paymentSettings) {
            applyCurrentValues()
        }
        .onChange(of: draft) {
            validationMessage = nil
        }
    }

    private func toggleMethod(_ method: UserPaymentMethod) {
        var next = draft
        next.set(method, isSelected: !draft.contains(method))
        draft = next
        hasUserEditedDraft = true
        MegrumHaptics.selectionChanged()
    }

    private var otherNoteBinding: Binding<String> {
        Binding(
            get: { draft.otherNote },
            set: {
                draft.otherNote = PaymentSettingsDraft.limitedOtherNote($0)
                hasUserEditedDraft = true
            }
        )
    }

    private func textBinding(_ keyPath: WritableKeyPath<PaymentSettingsDraft, String>) -> Binding<String> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: {
                draft[keyPath: keyPath] = $0
                hasUserEditedDraft = true
            }
        )
    }

    private func applyCurrentValues(force: Bool = false) {
        guard force || !hasUserEditedDraft else {
            return
        }
        draft = PaymentSettingsDraft(settings: appState.paymentSettings, viewer: appState.viewer)
    }

    private func save() {
        let normalized = draft.normalized
        if let message = normalized.validationMessage {
            validationMessage = message
            return
        }
        guard let userID = appState.viewer?.id else {
            validationMessage = "プロフィールを読み込めませんでした"
            return
        }

        focusedField = nil
        Task {
            if await appState.savePaymentSettings(normalized.settings(userID: userID)) {
                hasUserEditedDraft = false
                closeScreen()
            }
        }
    }

    private func closeScreen() {
        if let onClose {
            onClose()
        } else if let slideDismiss {
            slideDismiss()
        } else {
            dismiss()
        }
    }

}
