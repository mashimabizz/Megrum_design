import Foundation
import MegrumCore
import MegrumData

public struct PreviewMegrumRepository: MegrumRepository {
    private let subscriptionState: UserSubscriptionState

    public init(subscriptionState: UserSubscriptionState = .free) {
        self.subscriptionState = subscriptionState
    }

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
            threads: NativePreviewData.threads,
            subscriptionState: subscriptionState
        )
    }

    public func loadSubscriptionState() async throws -> UserSubscriptionState {
        subscriptionState
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

    public func loadExchangeSettings(userID: UUID) async throws -> HomeDefaultExchangeSettings? {
        if userID == NativePreviewData.partnerID {
            return HomeDefaultExchangeSettings(
                preference: .both,
                localPrefecture: "東京都",
                localDateKeys: ["2026-07-03", "2026-07-05"],
                localDateDetails: [
                    "2026-07-03": HomeExchangeLocalDateDetail(prefecture: "東京都", memo: "渋谷駅周辺"),
                    "2026-07-05": HomeExchangeLocalDateDetail(prefecture: "東京都", memo: "会場付近")
                ],
                mailShippingFee: .negotiate,
                mailShippingDays: .twoToFourDays
            )
        }
        if userID == NativePreviewData.viewer.id {
            return HomeDefaultExchangeSettings.standard
        }
        return nil
    }

    public func saveExchangeSettings(_ settings: HomeDefaultExchangeSettings) async throws -> HomeDefaultExchangeSettings {
        settings
    }

    private func normalizedHandle(_ handle: String) -> String {
        var normalized = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.first == "@" {
            normalized.removeFirst()
        }
        return normalized
    }

}
