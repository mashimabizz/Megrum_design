import Foundation
import MegrumCore
import MegrumData

extension SupabaseAccountProfilePersistence {
    static func viewerQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    static func fallbackViewerProfile(userID: UUID) -> UserProfile {
        UserProfile(
            id: userID,
            handle: "megrum",
            displayName: "Megrum",
            prefecture: nil,
            accountStatus: .onboarding
        )
    }

    static func resolvedAvatarUpdate(
        input: OwnProfileUpdateInput,
        uploadedAvatarURL: URL?
    ) -> ResolvedAvatarUpdate {
        ResolvedAvatarUpdate(
            url: uploadedAvatarURL ?? (input.clearsAvatar ? nil : input.avatarURL),
            shouldEncode: input.avatarUpload != nil || input.clearsAvatar || input.avatarURL != nil
        )
    }

    static func ownProfileUpdatePayload(
        input: OwnProfileUpdateInput,
        avatarUpdate: ResolvedAvatarUpdate
    ) -> UserOwnProfileUpdatePayload {
        UserOwnProfileUpdatePayload(
            handle: input.handle,
            displayName: input.displayName,
            bio: input.bio?.nilIfBlank,
            avatarUrl: avatarUpdate.url,
            shouldEncodeAvatarUrl: avatarUpdate.shouldEncode,
            gender: input.gender,
            primaryArea: input.prefecture,
            birthDate: ProfileBirthDateCodec.string(from: input.birthDate),
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            paymentMethods: input.paymentMethods
        )
    }

    static func legacyOwnProfileUpdatePayload(
        input: OwnProfileUpdateInput,
        avatarUpdate: ResolvedAvatarUpdate
    ) -> UserOwnProfileLegacyUpdatePayload {
        UserOwnProfileLegacyUpdatePayload(
            handle: input.handle,
            displayName: input.displayName,
            avatarUrl: avatarUpdate.url,
            shouldEncodeAvatarUrl: avatarUpdate.shouldEncode,
            gender: input.gender,
            primaryArea: input.prefecture,
            paymentMethods: input.paymentMethods
        )
    }

    static func mergedOwnProfile(
        storedProfile: UserProfile?,
        input: OwnProfileUpdateInput,
        userID: UUID,
        avatarURL: URL?
    ) -> UserProfile {
        guard let storedProfile else {
            return fallbackOwnProfile(input: input, userID: userID, avatarURL: avatarURL)
        }
        return UserProfile(
            id: storedProfile.id,
            handle: storedProfile.handle,
            displayName: storedProfile.displayName,
            bio: input.bio,
            avatarURL: storedProfile.avatarURL ?? avatarURL,
            gender: storedProfile.gender ?? input.gender,
            prefecture: storedProfile.prefecture,
            birthDate: input.birthDate,
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            paymentMethods: input.paymentMethods,
            paymentNote: storedProfile.paymentNote,
            accountStatus: storedProfile.accountStatus
        )
    }

    static func fallbackOwnProfile(
        input: OwnProfileUpdateInput,
        userID: UUID,
        avatarURL: URL?
    ) -> UserProfile {
        UserProfile(
            id: userID,
            handle: input.handle,
            displayName: input.displayName,
            bio: input.bio,
            avatarURL: avatarURL,
            gender: input.gender,
            prefecture: input.prefecture,
            birthDate: input.birthDate,
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            paymentMethods: input.paymentMethods,
            accountStatus: .active
        )
    }

    static func accountSetupSelections(
        from input: AccountSetupInput,
        userID: UUID
    ) -> [UserOshiSelection] {
        UserOshiSelectionPersistenceMapper.selections(
            from: input.oshiSelections,
            userID: userID
        )
    }

    static func accountSetupUpdatePayload(from input: AccountSetupInput) -> UserProfileUpdatePayload {
        UserProfileUpdatePayload(
            handle: input.handle,
            displayName: input.displayName,
            gender: input.gender,
            primaryArea: input.prefecture,
            birthDate: ProfileBirthDateCodec.string(from: input.birthDate),
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            accountStatus: AccountStatus.active.rawValue
        )
    }

    static func accountSetupUpsertPayload(
        from input: AccountSetupInput,
        userID: UUID,
        accountStatus: AccountStatus = .active
    ) -> UserProfileAccountSetupUpsertPayload {
        UserProfileAccountSetupUpsertPayload(
            id: userID,
            handle: input.handle,
            displayName: input.displayName,
            gender: input.gender,
            primaryArea: input.prefecture,
            birthDate: ProfileBirthDateCodec.string(from: input.birthDate),
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            accountStatus: accountStatus.rawValue
        )
    }

    static func accountSetupLegacyUpsertPayload(
        from input: AccountSetupInput,
        userID: UUID,
        accountStatus: AccountStatus = .active
    ) -> UserProfileAccountSetupLegacyUpsertPayload {
        UserProfileAccountSetupLegacyUpsertPayload(
            id: userID,
            handle: input.handle,
            displayName: input.displayName,
            gender: input.gender,
            primaryArea: input.prefecture,
            accountStatus: accountStatus.rawValue
        )
    }

    static func accountDeletionPayload(from input: AccountDeletionRequestInput) -> AccountDeletionRequestPayload {
        let normalized = input.normalized
        return AccountDeletionRequestPayload(
            reasons: normalized.reasons.map(\.rawValue),
            note: normalized.note
        )
    }

    static func fallbackAccountSetupProfile(
        input: AccountSetupInput,
        userID: UUID
    ) -> UserProfile {
        UserProfile(
            id: userID,
            handle: input.handle,
            displayName: input.displayName,
            gender: input.gender,
            prefecture: input.prefecture,
            birthDate: input.birthDate,
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            accountStatus: .active
        )
    }

    static let accountSetupProfileSelect = "id,handle,display_name,avatar_url,gender,primary_area,account_status"

    static func mergedAccountSetupProfile(
        storedProfile: UserProfile?,
        input: AccountSetupInput,
        userID: UUID
    ) -> UserProfile {
        guard let storedProfile else {
            return fallbackAccountSetupProfile(input: input, userID: userID)
        }
        return UserProfile(
            id: storedProfile.id,
            handle: storedProfile.handle,
            displayName: storedProfile.displayName,
            bio: storedProfile.bio,
            avatarURL: storedProfile.avatarURL,
            gender: storedProfile.gender ?? input.gender,
            prefecture: storedProfile.prefecture ?? input.prefecture,
            birthDate: input.birthDate,
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            paymentMethods: storedProfile.paymentMethods,
            paymentNote: storedProfile.paymentNote,
            accountStatus: storedProfile.accountStatus
        )
    }
}
