import Foundation

enum HomeDiscoveryCardTitleStyle {
    case plain
    case member
    case memberTag
}

enum HomeDiscoveryCardTitleFormatter {
    static func title(
        for goods: HomeMockGoods?,
        fallback: String,
        style: HomeDiscoveryCardTitleStyle
    ) -> String {
        switch style {
        case .plain:
            return fallback
        case .member:
            if let name = goods?.masterDisplayName {
                return name
            }
            return fallbackTitle(goods?.title ?? fallback)
        case .memberTag:
            guard let goods else {
                return fallback
            }
            let member = goods.masterDisplayName ?? fallbackTitle(goods.title)
            if let tag = firstDisplayTag(for: goods) {
                return HomeDiscoveryTitleParser.joinedMemberTagTitle(member: member, tag: tag)
            }
            return member
        }
    }

    private static func firstDisplayTag(for goods: HomeMockGoods) -> String? {
        if let tag = goods.displayTags.first.flatMap(normalizedTag) {
            return tag
        }
        return normalizedTag(goods.subtitle)
    }

    private static func normalizedTag(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return trimmed.hasPrefix("#") ? trimmed : "#\(trimmed)"
    }

    private static func fallbackTitle(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "推し未設定" : trimmed
    }
}

enum HomeDiscoveryTitleParser {
    static func memberName(from title: String) -> String {
        if title.contains("×"),
           let leftSide = title.split(separator: "×", maxSplits: 1, omittingEmptySubsequences: true).first {
            return String(leftSide).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func memberTagTitle(from title: String) -> String {
        if title.contains("×") {
            let parts = title.split(separator: "×", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else {
                return title
            }
            return joinedMemberTagTitle(
                member: String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines),
                tag: String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func comparableMemberName(from title: String) -> String {
        memberName(from: title)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func joinedMemberTagTitle(member: String, tag: String) -> String {
        "\(member.trimmingCharacters(in: .whitespacesAndNewlines)) × \(tag.trimmingCharacters(in: .whitespacesAndNewlines))"
    }
}
