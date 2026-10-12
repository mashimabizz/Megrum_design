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
    @State private var editingState = PaymentSettingsEditingState()
    @State private var accountEditor: PaymentAccountEditorContext?

    var body: some View {
        ScrollView {
            PaymentSettingsFormContent(
                draft: editingState.draft,
                otherNote: otherNoteBinding,
                focusedField: $focusedField,
                validationMessage: editingState.validationMessage,
                appErrorMessage: appState.errorMessage,
                onToggleMethod: toggleMethod,
                onAddAccount: startAddingAccount,
                onEditAccount: startEditingAccount,
                onDeleteAccount: deleteAccount
            )
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 104)
        }
        .sheet(item: $accountEditor) { context in
            PaymentSettingsBankAccountEditorSheet(
                account: context.account,
                isNew: context.isNew,
                onSave: { saved in
                    if context.isNew {
                        editingState.appendAccount(saved)
                    } else {
                        editingState.updateAccount(saved)
                    }
                },
                onCancel: {}
            )
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
    }

    private func toggleMethod(_ method: UserPaymentMethod) {
        editingState.toggleMethod(method)
        MegrumHaptics.selectionChanged()
    }

    private var otherNoteBinding: Binding<String> {
        Binding(
            get: { editingState.draft.otherNote },
            set: {
                editingState.updateOtherNote($0)
            }
        )
    }

    private func startAddingAccount() {
        focusedField = nil
        accountEditor = PaymentAccountEditorContext(
            account: BankReceivingAccount(accountType: "普通"),
            isNew: true
        )
    }

    private func startEditingAccount(_ account: BankReceivingAccount) {
        focusedField = nil
        accountEditor = PaymentAccountEditorContext(account: account, isNew: false)
    }

    private func deleteAccount(_ id: UUID) {
        editingState.removeAccount(id: id)
        MegrumHaptics.selectionChanged()
    }

    private func applyCurrentValues(force: Bool = false) {
        editingState.applyCurrentValues(
            settings: appState.paymentSettings,
            viewer: appState.viewer,
            force: force
        )
    }

    private func save() {
        guard let settings = editingState.settingsForSave(viewerID: appState.viewer?.id) else {
            return
        }

        focusedField = nil
        Task {
            if await appState.savePaymentSettings(settings) {
                editingState.markSaveSucceeded()
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
