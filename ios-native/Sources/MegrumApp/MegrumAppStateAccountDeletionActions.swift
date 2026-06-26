import Foundation
import MegrumCore

extension MegrumAppState {
    public func requestAccountDeletion(_ input: AccountDeletionRequestInput) async -> Bool {
        guard !isRequestingAccountDeletion else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを読み込めませんでした"
            return false
        }
        guard AccountDeletionEligibility.canRequestDeletion(
            proposals: proposals,
            viewerID: viewer.id
        ) else {
            errorMessage = "現在進行中の取引があるため退会できません"
            return false
        }

        let normalizedInput = input.normalized
        guard !normalizedInput.reasons.isEmpty else {
            errorMessage = AccountDeletionDraftValidator.missingReasonMessage
            return false
        }

        isRequestingAccountDeletion = true
        errorMessage = nil

        do {
            _ = try await repository.requestAccountDeletion(normalizedInput)
            self.viewer = UserProfile(
                id: viewer.id,
                handle: viewer.handle,
                displayName: viewer.displayName,
                bio: viewer.bio,
                avatarURL: viewer.avatarURL,
                gender: viewer.gender,
                prefecture: viewer.prefecture,
                birthDate: viewer.birthDate,
                age: viewer.age,
                paymentMethods: viewer.paymentMethods,
                paymentNote: viewer.paymentNote,
                accountStatus: .deletionRequested
            )
            isRequestingAccountDeletion = false
            return true
        } catch {
            errorMessage = "退会申請を送信できませんでした"
            isRequestingAccountDeletion = false
            return false
        }
    }
}
