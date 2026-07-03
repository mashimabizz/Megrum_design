import Foundation
import MegrumCore

struct MeguriProfileSettingsDraftState: Equatable {
    var displayName = ""
    var selectedAvatarID = BoardAnonymousAvatarOption.options[0].id
    var existingAvatarURL: URL?
    var localAvatarData: Data?
    var localAvatarContentType: String?
    var clearsAvatarURL = false
    var usesPublicProfile = false
    var localAlertMessage: String?

    var avatarFallback: String {
        displayName.nilIfBlank ?? "め"
    }

    var hasAlert: Bool {
        localAlertMessage != nil
    }

    func canSave(isSaving: Bool) -> Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSaving
    }

    var avatarUpload: GoodsPhotoUpload? {
        guard let localAvatarData else {
            return nil
        }
        return GoodsPhotoUpload(data: localAvatarData, contentType: localAvatarContentType ?? "image/jpeg")
    }

    var visibleAvatarURL: URL? {
        guard !clearsAvatarURL, localAvatarData == nil else {
            return nil
        }
        return existingAvatarURL
    }

    func displayNameForSave(currentProfile: MeguriProfile?, syncedPublicDisplayName: String) -> String {
        guard usesPublicProfile else {
            return displayName
        }
        return currentProfile?.displayName.nilIfBlank
            ?? syncedPublicDisplayName
    }

    func avatarIDForSave(currentProfile: MeguriProfile?) -> String {
        guard usesPublicProfile else {
            return selectedAvatarID
        }
        return currentProfile?.avatarID.nilIfBlank
            ?? selectedAvatarID
    }

    func avatarURLForSave(currentProfile: MeguriProfile?) -> URL? {
        guard usesPublicProfile else {
            return visibleAvatarURL
        }
        return currentProfile?.avatarURL
    }

    func avatarUploadForSave() -> GoodsPhotoUpload? {
        usesPublicProfile ? nil : avatarUpload
    }

    func clearsAvatarURLForSave() -> Bool {
        usesPublicProfile ? false : clearsAvatarURL
    }

    var hasCustomAvatar: Bool {
        localAvatarData != nil || visibleAvatarURL != nil
    }

    mutating func hydrate(profile: MeguriProfile?, viewerDisplayName: String?, viewerAvatarURL: URL?) {
        let usesViewerProfile = profile?.usesPublicProfile ?? false
        displayName = usesViewerProfile
            ? (viewerDisplayName ?? profile?.displayName ?? "")
            : (profile?.displayName
            ?? viewerDisplayName
            ?? "")
        selectedAvatarID = profile?.avatarID.nilIfBlank
            ?? BoardAnonymousAvatarOption.options[0].id
        existingAvatarURL = usesViewerProfile ? viewerAvatarURL : profile?.avatarURL
        localAvatarData = nil
        localAvatarContentType = nil
        clearsAvatarURL = false
        usesPublicProfile = usesViewerProfile
    }

    mutating func hydrateIfNeeded(profile: MeguriProfile?, viewerDisplayName: String?, viewerAvatarURL: URL?) {
        guard displayName.isBlank else {
            return
        }
        hydrate(profile: profile, viewerDisplayName: viewerDisplayName, viewerAvatarURL: viewerAvatarURL)
    }

    mutating func syncPublicProfile(displayName viewerDisplayName: String?, avatarURL viewerAvatarURL: URL?) {
        displayName = viewerDisplayName ?? displayName
        existingAvatarURL = viewerAvatarURL
        localAvatarData = nil
        localAvatarContentType = nil
        clearsAvatarURL = false
    }

    mutating func setFailureMessage(_ message: String?) {
        localAlertMessage = message ?? "めぐりプロフィールを保存できませんでした"
    }

    mutating func setLocalAvatarUpload(_ upload: GoodsPhotoUpload) {
        localAvatarData = upload.data
        localAvatarContentType = upload.contentType
        clearsAvatarURL = false
    }

    mutating func selectPresetAvatar(_ avatarID: String) {
        selectedAvatarID = avatarID
        localAvatarData = nil
        localAvatarContentType = nil
        clearsAvatarURL = existingAvatarURL != nil
    }

    mutating func clearLocalAvatarUpload() {
        localAvatarData = nil
        localAvatarContentType = nil
    }

    mutating func clearAlert() {
        localAlertMessage = nil
    }
}
