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
        meguriProfile _: MeguriProfile?,
        publicProfile: PublicUserProfile?,
        fallbackName: String? = nil,
        fallbackHandle: String? = nil,
        fallbackAvatarURL: URL? = nil
    ) -> MeguriProfileIdentity {
        // iter1226.296: めぐりプロフィール（カスタム名/アイコン）は廃止。
        // グルーム・めぐりメッセージは常にグッズ交換側のプロフィールだけを使い、
        // 旧めぐりプロフィールのアイコンには一切フォールバックしない。
        return MeguriProfileIdentity(
            userID: userID,
            displayName: publicProfile?.profile.displayName.nilIfBlank
                ?? fallbackName?.nilIfBlank
                ?? "ユーザー",
            handle: publicProfile?.profile.handle.nilIfBlank ?? fallbackHandle?.nilIfBlank,
            avatarID: nil,
            avatarURL: publicProfile?.profile.avatarURL ?? fallbackAvatarURL,
            usesPublicProfile: true
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
