import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct AddressSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var saveButtonTitle = "保存する"
    var onSaveCompleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AddressSettingsField?

    @State private var draftState = AddressSettingsDraftState()
    @State private var postalCodeLookupTask: Task<Void, Never>?
    /// 郵便番号照会が成功して自動入力された回数。フォーム側のフラッシュ表示トリガー。
    @State private var autoFillPulse = 0
    /// 照会失敗時の手入力案内。郵便番号を編集し直したら消す。
    @State private var postalLookupNotice: String?

    private var draftAddress: MailingAddress {
        draftState.mailingAddress(userID: appState.viewer?.id ?? NativePreviewData.viewerID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AddressSettingsHeader()
                AddressSettingsForm(
                    recipientName: $draftState.recipientName,
                    postalCode: $draftState.postalCode,
                    prefecture: $draftState.prefecture,
                    city: $draftState.city,
                    line1: $draftState.line1,
                    line2: $draftState.line2,
                    phoneNumber: $draftState.phoneNumber,
                    focusedField: $focusedField,
                    isLookingUpPostalCode: appState.isLookingUpPostalCode,
                    postalLookupNotice: postalLookupNotice,
                    autoFillPulse: autoFillPulse,
                    inputErrorMessage: draftState.inputErrorMessage,
                    appErrorMessage: appState.errorMessage,
                    onPostalCodeChange: handlePostalCodeChange
                )
                AddressSettingsSaveButton(
                    title: saveButtonTitle,
                    isSaving: appState.isSavingMailingAddress,
                    action: startSave
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("住所設定")
        .megrumInlineNavigationTitle()
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
        .task {
            await appState.loadMailingAddress()
            apply(address: appState.mailingAddress)
        }
        .onDisappear {
            postalCodeLookupTask?.cancel()
        }
        .onChange(of: appState.mailingAddress) { _, address in
            draftState.apply(address: address)
        }
        .onChange(of: draftAddress) { _, _ in
            draftState.clearInputError()
        }
    }

    private func startSave() {
        Task { await save() }
    }

    private func save() async {
        focusedField = nil
        draftState.setValidationMessage(MailingAddressDraftValidator.validationMessage(for: draftAddress))
        guard draftState.inputErrorMessage == nil else {
            return
        }

        if await appState.saveMailingAddress(draftAddress) {
            draftState.clearInputError()
            onSaveCompleted?()
            dismiss()
        }
    }

    private func apply(address: MailingAddress?) {
        draftState.apply(address: address)
    }

    private func handlePostalCodeChange(_ value: String) {
        let normalized = draftState.normalizePostalCodeInput(value)
        postalLookupNotice = nil
        schedulePostalCodeLookup(normalized)
    }

    private func schedulePostalCodeLookup(_ value: String) {
        postalCodeLookupTask?.cancel()
        guard draftState.shouldLookupPostalCode(value) else {
            return
        }

        postalCodeLookupTask = Task { [value] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }
            guard let address = await appState.lookupPostalCode(value) else {
                if !Task.isCancelled {
                    postalLookupNotice = "郵便番号から住所が見つかりませんでした。手入力してください。"
                }
                return
            }
            guard !Task.isCancelled else {
                return
            }
            draftState.apply(postalCodeAddress: address)
            // 自動入力の成功を触覚＋フィールドのフラッシュで伝える（iter1226.407）。
            MegrumHaptics.success()
            autoFillPulse += 1
        }
    }
}
