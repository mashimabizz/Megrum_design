import Foundation
import MegrumCore

enum PaymentSettingsResolver {
    static func methods(settings: UserPaymentSettings?, viewer: UserProfile?) -> [UserPaymentMethod] {
        let settingsMethods = UserPaymentMethod.normalized(settings?.methods ?? [])
        guard settingsMethods.isEmpty else {
            return settingsMethods
        }
        return UserPaymentMethod.normalized(viewer?.paymentMethods ?? [])
    }

    static func otherNote(settings: UserPaymentSettings?, viewer: UserProfile?) -> String? {
        settings?.otherNote?.nilIfBlank ?? viewer?.paymentNote?.nilIfBlank
    }

    static func hasAnyData(settings: UserPaymentSettings?, viewer: UserProfile?) -> Bool {
        settings?.hasAnyData == true
            || !UserPaymentMethod.normalized(viewer?.paymentMethods ?? []).isEmpty
            || viewer?.paymentNote?.nilIfBlank != nil
    }
}
