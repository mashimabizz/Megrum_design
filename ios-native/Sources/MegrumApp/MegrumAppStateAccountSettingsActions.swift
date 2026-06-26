import Foundation
import MegrumCore

extension MegrumAppState {
    public func loadMailingAddress() async {
        guard !isLoadingMailingAddress else {
            return
        }

        isLoadingMailingAddress = true
        errorMessage = nil
        do {
            mailingAddress = try await repository.loadMailingAddress()
        } catch {
            errorMessage = "住所を読み込めませんでした"
        }
        isLoadingMailingAddress = false
    }

    public func saveMailingAddress(_ address: MailingAddress) async -> Bool {
        guard !isSavingMailingAddress else {
            return false
        }
        guard address.isReady else {
            errorMessage = "宛名・郵便番号・都道府県・市区町村・番地を入力してください"
            return false
        }

        isSavingMailingAddress = true
        errorMessage = nil
        do {
            mailingAddress = try await repository.saveMailingAddress(address)
            isSavingMailingAddress = false
            return true
        } catch {
            errorMessage = "住所を保存できませんでした"
            isSavingMailingAddress = false
            return false
        }
    }

    public func loadPaymentSettings() async {
        guard !isLoadingPaymentSettings else {
            return
        }

        isLoadingPaymentSettings = true
        errorMessage = nil
        do {
            paymentSettings = try await repository.loadPaymentSettings()
        } catch {
            errorMessage = "支払い方法を読み込めませんでした"
        }
        isLoadingPaymentSettings = false
    }

    public func savePaymentSettings(_ settings: UserPaymentSettings) async -> Bool {
        guard !isSavingPaymentSettings else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを読み込めませんでした"
            return false
        }

        isSavingPaymentSettings = true
        errorMessage = nil
        do {
            let saved = try await repository.savePaymentSettings(settings.normalized(for: viewer.id))
            self.viewer = saved.profile
            self.paymentSettings = saved.settings
            isSavingPaymentSettings = false
            return true
        } catch {
            errorMessage = "支払い方法を保存できませんでした"
            isSavingPaymentSettings = false
            return false
        }
    }

    public func lookupPostalCode(_ postalCode: String) async -> PostalCodeAddress? {
        let normalizedPostalCode = MegrumAppStateInputNormalizer.postalCode(postalCode)
        guard normalizedPostalCode.count == 7 else {
            return nil
        }
        guard !isLookingUpPostalCode else {
            return nil
        }

        isLookingUpPostalCode = true
        errorMessage = nil
        defer {
            isLookingUpPostalCode = false
        }

        do {
            let address = try await repository.lookupAddress(postalCode: normalizedPostalCode)
            if address == nil {
                errorMessage = "郵便番号に一致する住所が見つかりませんでした"
            }
            return address
        } catch {
            errorMessage = "郵便番号から住所を取得できませんでした"
            return nil
        }
    }

    public func loadBlockedUsers() async {
        guard !isLoadingBlockedUsers else {
            return
        }

        isLoadingBlockedUsers = true
        errorMessage = nil
        do {
            blockedUsers = try await repository.loadBlockedUsers()
        } catch {
            errorMessage = "ブロックした人を読み込めませんでした"
        }
        isLoadingBlockedUsers = false
    }

    public func unblockUser(_ userID: UUID) async -> Bool {
        guard unblockingUserID == nil else {
            return false
        }

        unblockingUserID = userID
        errorMessage = nil
        do {
            try await repository.unblockUser(userID)
            blockedUsers = BlockedUserStateReducer.removing(
                userID: userID,
                from: blockedUsers
            )
            unblockingUserID = nil
            return true
        } catch {
            errorMessage = "ブロックを解除できませんでした"
            unblockingUserID = nil
            return false
        }
    }
}
