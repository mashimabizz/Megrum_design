import Foundation
import MegrumCore

struct AddressSettingsDraftState: Equatable {
    var recipientName = ""
    var postalCode = ""
    var prefecture = ""
    var city = ""
    var line1 = ""
    var line2 = ""
    var phoneNumber = ""
    var lastAppliedPostalCode = ""
    var inputErrorMessage: String?

    func mailingAddress(userID: UUID) -> MailingAddress {
        MailingAddress(
            userID: userID,
            recipientName: recipientName.trimmingCharacters(in: .whitespacesAndNewlines),
            postalCode: MegrumAppStateInputNormalizer.postalCode(postalCode),
            prefecture: prefecture.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            line1: line1.trimmingCharacters(in: .whitespacesAndNewlines),
            line2: line2.nilIfBlank,
            phoneNumber: phoneNumber.nilIfBlank
        )
    }

    mutating func apply(address: MailingAddress?) {
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

    mutating func normalizePostalCodeInput(_ value: String) -> String {
        let normalized = MegrumAppStateInputNormalizer.postalCode(value)
        if normalized != value {
            postalCode = normalized
        }
        return normalized
    }

    func shouldLookupPostalCode(_ value: String) -> Bool {
        value.count == 7 && value != lastAppliedPostalCode
    }

    mutating func apply(postalCodeAddress address: PostalCodeAddress) {
        prefecture = address.prefecture
        city = address.city
        line1 = address.line1Suggestion
        lastAppliedPostalCode = address.postalCode
    }

    mutating func setValidationMessage(_ message: String?) {
        inputErrorMessage = message
    }

    mutating func clearInputError() {
        inputErrorMessage = nil
    }
}
