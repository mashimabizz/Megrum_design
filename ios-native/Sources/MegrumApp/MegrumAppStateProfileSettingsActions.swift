import Foundation
import MegrumCore

extension MegrumAppState {
    public func completeAccountSetup(
        displayName: String,
        prefecture: String?,
        oshiSelections: [AccountSetupOshiInput] = []
    ) async -> Bool {
        guard !isSavingAccountSetup else {
            return false
        }
        let trimmedDisplayName = MegrumAppStateInputNormalizer.trimmedText(displayName)
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "表示名を入力してください"
            return false
        }
        guard !oshiSelections.isEmpty else {
            errorMessage = "推しを選択してください"
            return false
        }

        isSavingAccountSetup = true
        errorMessage = nil

        do {
            let savedViewer = try await repository.completeAccountSetup(
                AccountSetupInput(
                    displayName: trimmedDisplayName,
                    prefecture: MegrumAppStateInputNormalizer.prefecture(prefecture),
                    oshiSelections: oshiSelections
                )
            )
            viewer = savedViewer
            userOshiSelections = UserOshiSelectionPersistenceMapper.selections(
                from: oshiSelections,
                userID: savedViewer.id
            )
            isSavingAccountSetup = false
            return true
        } catch {
            errorMessage = "プロフィールを保存できませんでした"
            isSavingAccountSetup = false
            return false
        }
    }

    public func updateOwnProfile(_ input: OwnProfileUpdateInput) async -> Bool {
        guard !isSavingOwnProfile else {
            return false
        }

        let normalizedHandle = MegrumAppStateInputNormalizer.profileHandle(input.handle)
        let trimmedDisplayName = MegrumAppStateInputNormalizer.trimmedText(input.displayName)
        guard let normalizedHandle else {
            errorMessage = "ユーザーIDを入力してください"
            return false
        }
        guard MegrumAppStateInputNormalizer.isValidProfileHandle(normalizedHandle) else {
            errorMessage = "ユーザーIDは半角英数字・_ の3〜20文字で入力してください"
            return false
        }
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "表示名を入力してください"
            return false
        }

        isSavingOwnProfile = true
        errorMessage = nil

        do {
            let savedViewer = try await repository.updateOwnProfile(
                OwnProfileUpdateInput(
                    handle: normalizedHandle,
                    displayName: trimmedDisplayName,
                    gender: input.gender,
                    prefecture: MegrumAppStateInputNormalizer.prefecture(input.prefecture),
                    paymentMethods: input.paymentMethods,
                    avatarURL: input.avatarURL,
                    avatarUpload: input.avatarUpload,
                    clearsAvatar: input.clearsAvatar
                )
            )
            viewer = savedViewer
            isSavingOwnProfile = false
            return true
        } catch {
            errorMessage = "プロフィールを保存できませんでした"
            isSavingOwnProfile = false
            return false
        }
    }
}
