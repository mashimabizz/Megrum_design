import Foundation
import MegrumCore
import MegrumData

@MainActor
extension MegrumAppState {
    public func loadMeguriProfile(reportsFailure: Bool = true) async {
        guard let viewerID = viewer?.id, !isLoadingMeguriProfile else {
            return
        }

        isLoadingMeguriProfile = true
        defer { isLoadingMeguriProfile = false }

        do {
            let profile = try await repository.loadMeguriProfile(userID: viewerID)
            meguriProfile = profile
            if let profile {
                meguriProfilesByUserID[viewerID] = profile
            }
        } catch {
            if reportsFailure {
                errorMessage = "めぐりプロフィールを読み込めませんでした"
            }
        }
    }

    public func loadMeguriProfiles(userIDs: Set<UUID>, reportsFailure: Bool = false) async {
        let missingIDs = userIDs.subtracting(Set(meguriProfilesByUserID.keys))
        guard !missingIDs.isEmpty else {
            return
        }

        do {
            let profiles = try await repository.loadMeguriProfiles(userIDs: missingIDs)
            for profile in profiles {
                meguriProfilesByUserID[profile.userID] = profile
                if profile.userID == viewer?.id {
                    meguriProfile = profile
                }
            }
        } catch {
            if reportsFailure {
                errorMessage = "めぐりプロフィールを読み込めませんでした"
            }
        }
    }

    public func saveMeguriProfile(
        displayName: String,
        avatarID: String,
        avatarURL: URL? = nil,
        avatarUpload: GoodsPhotoUpload? = nil,
        clearsAvatarURL: Bool = false,
        usesPublicProfile: Bool = false
    ) async -> Bool {
        guard !isSavingMeguriProfile else {
            return false
        }

        let input: MeguriProfileUpdateInput
        do {
            input = try MeguriProfileValidation.validate(
                displayName: displayName,
                avatarID: avatarID,
                avatarURL: avatarURL,
                avatarUpload: avatarUpload,
                clearsAvatarURL: clearsAvatarURL,
                usesPublicProfile: usesPublicProfile,
                existingProfile: meguriProfile
            )
        } catch let error as MeguriProfileValidationError {
            errorMessage = error.meguriProfileMessage
            return false
        } catch {
            errorMessage = "めぐりプロフィールを保存できませんでした"
            return false
        }

        isSavingMeguriProfile = true
        defer { isSavingMeguriProfile = false }
        do {
            let saved = try await repository.saveMeguriProfile(input)
            meguriProfile = saved
            meguriProfilesByUserID[saved.userID] = saved
            return true
        } catch let error as SupabaseMeguriProfileClientError {
            errorMessage = error.meguriProfileMessage
            return false
        } catch {
            errorMessage = "めぐりプロフィールを保存できませんでした"
            return false
        }
    }
}

private extension MeguriProfileValidationError {
    var meguriProfileMessage: String {
        switch self {
        case .invalidDisplayName:
            "名前は1〜\(MeguriProfile.maximumDisplayNameLength)文字で入力してください"
        case let .lockedUntil(date):
            "めぐりプロフィールは1ヶ月に1回だけ変更できます。次回は\(date.formatted(date: .numeric, time: .omitted))以降に変更できます"
        }
    }
}

private extension SupabaseMeguriProfileClientError {
    var meguriProfileMessage: String {
        switch self {
        case .duplicatedDisplayName:
            "この名前はすでに使われています"
        case .changeLocked:
            "めぐりプロフィールは1ヶ月に1回だけ変更できます"
        case .malformedResponse:
            "めぐりプロフィールを保存できませんでした"
        }
    }
}
