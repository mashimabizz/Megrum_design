import SwiftUI

enum AddressSettingsField {
    case recipientName
    case postalCode
    case prefecture
    case city
    case line1
    case line2
    case phoneNumber
}

struct AddressSettingsForm: View {
    @Binding var recipientName: String
    @Binding var postalCode: String
    @Binding var prefecture: String
    @Binding var city: String
    @Binding var line1: String
    @Binding var line2: String
    @Binding var phoneNumber: String
    var focusedField: FocusState<AddressSettingsField?>.Binding
    var isLookingUpPostalCode: Bool
    var inputErrorMessage: String?
    var appErrorMessage: String?
    var onPostalCodeChange: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("宛名", text: $recipientName)
                .focused(focusedField, equals: .recipientName)
                .textContentType(.name)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .postalCode }
                .megrumTextFieldStyle()

            HStack(spacing: 10) {
                TextField("郵便番号（ハイフンなし）", text: $postalCode)
                    .focused(focusedField, equals: .postalCode)
                    .textContentType(.postalCode)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .onChange(of: postalCode) { _, value in
                        onPostalCodeChange(value)
                    }

                if isLookingUpPostalCode {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .megrumTextFieldStyle()

            TextField("都道府県", text: $prefecture)
                .focused(focusedField, equals: .prefecture)
                .textContentType(.addressState)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .city }
                .megrumTextFieldStyle()

            TextField("市区町村", text: $city)
                .focused(focusedField, equals: .city)
                .textContentType(.addressCity)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .line1 }
                .megrumTextFieldStyle()

            TextField("番地・建物名", text: $line1)
                .focused(focusedField, equals: .line1)
                .textContentType(.streetAddressLine1)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .line2 }
                .megrumTextFieldStyle()

            TextField("補足住所（任意）", text: $line2)
                .focused(focusedField, equals: .line2)
                .textContentType(.streetAddressLine2)
                .submitLabel(.next)
                .onSubmit { focusedField.wrappedValue = .phoneNumber }
                .megrumTextFieldStyle()

            TextField("電話番号（任意）", text: $phoneNumber)
                .focused(focusedField, equals: .phoneNumber)
                .textContentType(.telephoneNumber)
                #if os(iOS)
                .keyboardType(.phonePad)
                #endif
                .megrumTextFieldStyle()

            if let inputErrorMessage {
                AddressSettingsErrorBanner(message: inputErrorMessage)
            } else if let appErrorMessage {
                AddressSettingsErrorBanner(message: appErrorMessage)
            }
        }
    }
}
