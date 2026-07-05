import MegrumCore

enum OwnProfileOshiTagPresentation {
    static let fallbackTitle = "推し未設定"

    static func tagItems(from selections: [UserOshiSelection]) -> [ProfileVisualTagItem] {
        let tags = PublicOshiTag.makeTags(from: selections)
        guard !tags.isEmpty else {
            return [
                ProfileVisualTagItem(
                    title: fallbackTitle,
                    colorKey: fallbackTitle
                )
            ]
        }

        return tags.map { tag in
            ProfileVisualTagItem(
                title: tag.title,
                colorKey: tag.colorKey,
                kind: tag.characterID == nil ? .group : .member
            )
        }
    }
}
