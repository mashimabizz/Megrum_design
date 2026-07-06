import Foundation
import MegrumCore

extension UserProfile {
    /// 部分select由来のプロフィールで viewer を上書きする時に、欠けている項目を
    /// 既存プロフィールから補完する。生年月日・自己紹介などが「未設定」に
    /// 化けるのを防ぐ（iter1226.334）。
    func fillingMissingProfileFields(from existing: UserProfile) -> UserProfile {
        var merged = self
        if merged.birthDate == nil {
            merged.birthDate = existing.birthDate
            merged.age = merged.age ?? existing.age
        }
        if merged.bio == nil {
            merged.bio = existing.bio
        }
        return merged
    }
}
