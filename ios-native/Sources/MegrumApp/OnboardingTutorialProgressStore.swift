import Foundation

/// 初回ガイドツアーと「最初の3ステップ」ミッションの既読/完了状態を端末ローカルに保存する。
/// per-user キー（userID埋め込み）で、`MeguriRoomIdentityStore` と同じ慣例に揃えている。
enum OnboardingTutorialProgressStore {
    static func tourKey(userID: UUID) -> String {
        "onboarding.tour.completed.\(userID.uuidString.lowercased())"
    }

    static func missionKey(userID: UUID) -> String {
        "onboarding.mission.completed.\(userID.uuidString.lowercased())"
    }

    static func isTourCompleted(userID: UUID, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: tourKey(userID: userID))
    }

    static func markTourCompleted(userID: UUID, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: tourKey(userID: userID))
    }

    static func isMissionCompleted(userID: UUID, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: missionKey(userID: userID))
    }

    static func markMissionCompleted(userID: UUID, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: missionKey(userID: userID))
    }
}
