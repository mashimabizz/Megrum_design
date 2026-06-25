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

    @State private var recipientName = ""
    @State private var postalCode = ""
    @State private var prefecture = ""
    @State private var city = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var phoneNumber = ""
    @State private var postalCodeLookupTask: Task<Void, Never>?
    @State private var lastAppliedPostalCode = ""
    @State private var inputErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                form
                saveButton
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
            apply(address: address)
        }
        .onChange(of: draftAddress) { _, _ in
            inputErrorMessage = nil
        }
    }

    private var header: some View {
        AddressSettingsHeader()
    }

    private var form: some View {
        AddressSettingsForm(
            recipientName: $recipientName,
            postalCode: $postalCode,
            prefecture: $prefecture,
            city: $city,
            line1: $line1,
            line2: $line2,
            phoneNumber: $phoneNumber,
            focusedField: $focusedField,
            isLookingUpPostalCode: appState.isLookingUpPostalCode,
            inputErrorMessage: inputErrorMessage,
            appErrorMessage: appState.errorMessage,
            onPostalCodeChange: handlePostalCodeChange
        )
    }

    private var saveButton: some View {
        AddressSettingsSaveButton(
            title: saveButtonTitle,
            isSaving: appState.isSavingMailingAddress
        ) {
            Task { await save() }
        }
    }

    private var draftAddress: MailingAddress {
        MailingAddress(
            userID: appState.viewer?.id ?? NativePreviewData.viewerID,
            recipientName: recipientName.trimmingCharacters(in: .whitespacesAndNewlines),
            postalCode: MegrumAppStateInputNormalizer.postalCode(postalCode),
            prefecture: prefecture.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            line1: line1.trimmingCharacters(in: .whitespacesAndNewlines),
            line2: line2.nilIfBlank,
            phoneNumber: phoneNumber.nilIfBlank
        )
    }

    private func save() async {
        focusedField = nil
        inputErrorMessage = MailingAddressDraftValidator.validationMessage(for: draftAddress)
        guard inputErrorMessage == nil else {
            return
        }

        if await appState.saveMailingAddress(draftAddress) {
            inputErrorMessage = nil
            onSaveCompleted?()
            dismiss()
        }
    }

    private func apply(address: MailingAddress?) {
        guard let address else {
            return
        }
        recipientName = address.recipientName
        postalCode = address.postalCode
        prefecture = address.prefecture
        city = address.city
        line1 = address.line1
        line2 = address.line2 ?? ""
        phoneNumber = address.phoneNumber ?? ""
        lastAppliedPostalCode = address.postalCode
    }

    private func handlePostalCodeChange(_ value: String) {
        let normalized = MegrumAppStateInputNormalizer.postalCode(value)
        if normalized != value {
            postalCode = normalized
        }
        schedulePostalCodeLookup(normalized)
    }

    private func schedulePostalCodeLookup(_ value: String) {
        postalCodeLookupTask?.cancel()
        guard value.count == 7, value != lastAppliedPostalCode else {
            return
        }

        postalCodeLookupTask = Task { [value] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }
            guard let address = await appState.lookupPostalCode(value) else {
                return
            }
            guard !Task.isCancelled else {
                return
            }
            prefecture = address.prefecture
            city = address.city
            line1 = address.line1Suggestion
            lastAppliedPostalCode = address.postalCode
        }
    }
}
