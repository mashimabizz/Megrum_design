import Foundation
import MegrumCore

struct MeguriProfileIdentity: Equatable, Sendable {
    var userID: UUID
    var displayName: String
    var handle: String?
    var avatarID: String?
    var avatarURL: URL?
    var usesPublicProfile: Bool
}

enum MeguriProfileIdentityResolver {
    static func identity(
        for userID: UUID,
        meguriProfile: MeguriProfile?,
        publicProfile: PublicUserProfile?,
        fallbackName: String? = nil,
        fallbackHandle: String? = nil,
        fallbackAvatarURL: URL? = nil
    ) -> MeguriProfileIdentity {
        // iter1226.296: めぐりプロフィール（カスタム名/アイコン）は廃止。
        // グルーム・めぐりメッセージは常にグッズ交換側のプロフィールを使う。
        return MeguriProfileIdentity(
            userID: userID,
            displayName: publicProfile?.profile.displayName.nilIfBlank
                ?? fallbackName?.nilIfBlank
                ?? meguriProfile?.displayName.nilIfBlank
                ?? "ユーザー",
            handle: publicProfile?.profile.handle.nilIfBlank ?? fallbackHandle?.nilIfBlank,
            avatarID: nil,
            avatarURL: publicProfile?.profile.avatarURL ?? fallbackAvatarURL ?? meguriProfile?.avatarURL,
            usesPublicProfile: true
        )
    }

    private static func legacyIdentity(
        for userID: UUID,
        meguriProfile: MeguriProfile?,
        publicProfile: PublicUserProfile?,
        fallbackName: String? = nil,
        fallbackHandle: String? = nil,
        fallbackAvatarURL: URL? = nil
    ) -> MeguriProfileIdentity {
        if meguriProfile?.usesPublicProfile == true {
            return MeguriProfileIdentity(
                userID: userID,
                displayName: publicProfile?.profile.displayName.nilIfBlank
                    ?? fallbackName?.nilIfBlank
                    ?? meguriProfile?.displayName.nilIfBlank
                    ?? "ユーザー",
                handle: publicProfile?.profile.handle.nilIfBlank ?? fallbackHandle?.nilIfBlank,
                avatarID: nil,
                avatarURL: publicProfile?.profile.avatarURL ?? fallbackAvatarURL ?? meguriProfile?.avatarURL,
                usesPublicProfile: true
            )
        }

        return MeguriProfileIdentity(
            userID: userID,
            displayName: meguriProfile?.displayName.nilIfBlank
                ?? fallbackName?.nilIfBlank
                ?? publicProfile?.profile.displayName.nilIfBlank
                ?? "めぐりユーザー",
            handle: meguriProfile == nil
                ? (publicProfile?.profile.handle.nilIfBlank ?? fallbackHandle?.nilIfBlank)
                : nil,
            avatarID: meguriProfile?.avatarID,
            avatarURL: meguriProfile?.avatarURL
                ?? (meguriProfile == nil ? (publicProfile?.profile.avatarURL ?? fallbackAvatarURL) : nil),
            usesPublicProfile: false
        )
    }
}

extension MegrumAppState {
    func meguriIdentity(
        for userID: UUID,
        fallbackName: String? = nil,
        fallbackHandle: String? = nil,
        fallbackAvatarURL: URL? = nil
    ) -> MeguriProfileIdentity {
        MeguriProfileIdentityResolver.identity(
            for: userID,
            meguriProfile: meguriProfile(for: userID),
            publicProfile: publicProfilesByUserID[userID],
            fallbackName: fallbackName,
            fallbackHandle: fallbackHandle,
            fallbackAvatarURL: fallbackAvatarURL
        )
    }
}
