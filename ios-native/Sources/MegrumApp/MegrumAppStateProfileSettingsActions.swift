import Foundation
import MegrumCore

extension MegrumAppState {
    public func completeAccountSetup(
        handle: String,
        displayName: String,
        prefecture: String?,
        birthDate: Date?,
        gender: UserGender?,
        oshiSelections: [AccountSetupOshiInput] = []
    ) async -> Bool {
        await completeAccountSetup(
            AccountSetupInput(
                handle: handle,
                displayName: displayName,
                gender: gender,
                prefecture: prefecture,
                birthDate: birthDate,
                oshiSelections: oshiSelections
            )
        )
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async -> Bool {
        guard !isSavingAccountSetup else {
            return false
        }
        guard let normalizedHandle = MegrumAppStateInputNormalizer.accountSetupHandle(
            input.handle,
            userID: viewer?.id
        ) else {
            errorMessage = "プロフィールを読み込めませんでした"
            return false
        }
        let trimmedDisplayName = MegrumAppStateInputNormalizer.accountSetupDisplayName(
            input.displayName,
            fallbackHandle: normalizedHandle
        )
        if let birthDate = input.birthDate,
           birthDate > Date() {
            errorMessage = "生年月日は今日以前の日付を選択してください"
            return false
        }
        guard AccountSetupGenderOptions.contains(input.gender) else {
            errorMessage = "性別を選択してください"
            return false
        }
        guard !input.oshiSelections.isEmpty else {
            errorMessage = "推しを選択してください"
            return false
        }

        isSavingAccountSetup = true
        errorMessage = nil

        do {
            let savedViewer = try await repository.completeAccountSetup(
                AccountSetupInput(
                    handle: normalizedHandle,
                    displayName: trimmedDisplayName,
                    gender: input.gender,
                    prefecture: MegrumAppStateInputNormalizer.prefecture(input.prefecture),
                    birthDate: input.birthDate,
                    oshiSelections: input.oshiSelections
                )
            )
            viewer = savedViewer
            userOshiSelections = UserOshiSelectionPersistenceMapper.selections(
                from: input.oshiSelections,
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
        let trimmedBio = MegrumAppStateInputNormalizer.optionalText(input.bio)
        let normalizedGender = OwnProfileEditDraft.editableGender(input.gender)
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
        if (trimmedBio?.count ?? 0) > 500 {
            errorMessage = "自己紹介は500文字以内で入力してください"
            return false
        }
        if let birthDate = input.birthDate,
           birthDate > Date() {
            errorMessage = "生年月日は今日以前の日付を選択してください"
            return false
        }

        isSavingOwnProfile = true
        errorMessage = nil

        do {
            let savedViewer = try await repository.updateOwnProfile(
                OwnProfileUpdateInput(
                    handle: normalizedHandle,
                    displayName: trimmedDisplayName,
                    bio: trimmedBio,
                    gender: normalizedGender,
                    prefecture: MegrumAppStateInputNormalizer.prefecture(input.prefecture),
                    birthDate: input.birthDate,
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
