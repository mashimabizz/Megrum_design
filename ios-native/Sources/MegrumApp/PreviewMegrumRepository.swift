import Foundation
import MegrumCore
import MegrumData

public struct PreviewMegrumRepository: MegrumRepository {
    public init() {}

    public static func resetTradePhotoLocalStoreForTesting() async {
        await PreviewTradePhotoLocalStore.shared.reset()
    }

    public func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: NativePreviewData.viewer,
            inventory: NativePreviewData.inventory,
            wishes: NativePreviewData.wishes,
            listings: NativePreviewData.listings,
            proposals: NativePreviewData.proposals,
            grooms: NativePreviewData.grooms,
            threads: NativePreviewData.threads
        )
    }

    public func loadHomeCandidateSections() async throws -> HomeCandidateSections {
        let matchedItems = NativePreviewData.homeMatchedItems
        let possibleItems = NativePreviewData.homePossibleItems
        var conditionSignalsByItemID = HomeCandidateConditionSignalDefaults.previewSignals(
            matchedItems: matchedItems,
            possibleItems: possibleItems
        )
        for item in matchedItems where item.ownerID == NativePreviewData.partnerID {
            conditionSignalsByItemID[item.id]?.individualListingSelection = HomeDiscoveryFixtures.miiIndividualListingSelection
        }
        return HomeCandidateSections(
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            conditionSignalsByItemID: conditionSignalsByItemID
        )
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        UserProfile(
            id: NativePreviewData.viewer.id,
            handle: normalizedHandle(input.handle),
            displayName: input.displayName,
            bio: NativePreviewData.viewer.bio,
            avatarURL: NativePreviewData.viewer.avatarURL,
            gender: input.gender,
            prefecture: input.prefecture,
            birthDate: input.birthDate,
            age: ProfileBirthDateCodec.age(from: input.birthDate) ?? NativePreviewData.viewer.age,
            paymentMethods: NativePreviewData.viewer.paymentMethods,
            paymentNote: NativePreviewData.viewer.paymentNote,
            accountStatus: .active
        )
    }

    public func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile {
        let avatarURL: URL?
        if input.avatarUpload != nil {
            avatarURL = URL(string: "https://preview.megrum.jp/profile-photo.jpg")
        } else if input.clearsAvatar {
            avatarURL = nil
        } else {
            avatarURL = input.avatarURL ?? NativePreviewData.viewer.avatarURL
        }

        return UserProfile(
            id: NativePreviewData.viewer.id,
            handle: normalizedHandle(input.handle),
            displayName: input.displayName,
            bio: input.bio,
            avatarURL: avatarURL,
            gender: input.gender,
            prefecture: input.prefecture,
            birthDate: input.birthDate,
            age: ProfileBirthDateCodec.age(from: input.birthDate) ?? NativePreviewData.viewer.age,
            paymentMethods: input.paymentMethods,
            paymentNote: NativePreviewData.viewer.paymentNote,
            accountStatus: .active
        )
    }

    public func loadPaymentSettings() async throws -> UserPaymentSettings? {
        NativePreviewData.paymentSettings
    }

    public func savePaymentSettings(_ settings: UserPaymentSettings) async throws -> (profile: UserProfile, settings: UserPaymentSettings) {
        let normalized = settings.normalized(for: NativePreviewData.viewer.id)
        let profile = UserProfile(
            id: NativePreviewData.viewer.id,
            handle: NativePreviewData.viewer.handle,
            displayName: NativePreviewData.viewer.displayName,
            bio: NativePreviewData.viewer.bio,
            avatarURL: NativePreviewData.viewer.avatarURL,
            gender: NativePreviewData.viewer.gender,
            prefecture: NativePreviewData.viewer.prefecture,
            birthDate: NativePreviewData.viewer.birthDate,
            age: NativePreviewData.viewer.age,
            paymentMethods: normalized.methods,
            paymentNote: normalized.otherNote,
            accountStatus: .active
        )
        return (profile, normalized)
    }

    private func normalizedHandle(_ handle: String) -> String {
        var normalized = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.first == "@" {
            normalized.removeFirst()
        }
        return normalized
    }

}
