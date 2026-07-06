import SwiftUI

/// ガイドツアーでスポットライトを当てる対象UIの識別子。
enum TutorialAnchorID: Hashable, Sendable {
    case homeSectionUserTag
    case homeSectionUser
    case homeSectionHaves
    case inventoryAddButton
    case wishAddButton
    case listingAddButton
    case tradesStageBar
}

/// スポットライト対象ビューの frame（Anchor<CGRect>）をルートまで伝播させる PreferenceKey。
/// `HomeDiscoveryTabSwitcher` の同型パターンを踏襲。
struct TutorialAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [TutorialAnchorID: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [TutorialAnchorID: Anchor<CGRect>],
        nextValue: () -> [TutorialAnchorID: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

extension View {
    /// この View をガイドツアーのスポットライト対象として登録する。
    func tutorialAnchor(_ id: TutorialAnchorID) -> some View {
        anchorPreference(key: TutorialAnchorPreferenceKey.self, value: .bounds) { anchor in
            [id: anchor]
        }
    }

    /// id が nil のときは何もしない条件付きアンカー。
    @ViewBuilder
    func tutorialAnchor(ifPresent id: TutorialAnchorID?) -> some View {
        if let id {
            tutorialAnchor(id)
        } else {
            self
        }
    }
}
