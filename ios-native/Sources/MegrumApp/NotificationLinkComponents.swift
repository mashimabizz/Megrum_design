import Foundation

struct NotificationLinkComponents {
    let rawPath: String
    let segments: [String]
    let lowercaseSegments: [String]
    private let queryItems: [String: String]

    init?(_ linkPath: String?) {
        let rawPath = linkPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawPath.isEmpty else {
            return nil
        }

        self.rawPath = rawPath
        let components = URLComponents(string: rawPath)
        let path = Self.normalizedPath(from: rawPath, components: components)
        segments = path
            .split(separator: "/")
            .map { String($0).removingPercentEncoding ?? String($0) }
            .filter { !$0.isEmpty }
        lowercaseSegments = segments.map { $0.lowercased() }

        var queryItems: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            queryItems[item.name.lowercased()] = item.value ?? ""
        }
        self.queryItems = queryItems
    }

    func queryValue(_ keys: String...) -> String? {
        for key in keys {
            if let value = queryItems[key.lowercased()] {
                return value
            }
        }
        return nil
    }

    func segment(at index: Int) -> String? {
        guard segments.indices.contains(index) else {
            return nil
        }
        return segments[index].nilIfBlank
    }

    func segment(after lowercaseHead: String) -> String? {
        guard let index = lowercaseSegments.firstIndex(of: lowercaseHead) else {
            return nil
        }
        return segment(at: index + 1)
    }

    var firstUUIDLikeSegment: String? {
        segments.first { UUID(uuidString: $0) != nil }
    }

    var assistanceKind: NotificationTradeAssistanceKind {
        queryValue("kind")?.lowercased() == NotificationTradeAssistanceKind.late.rawValue ? .late : .cancel
    }

    var fallbackTab: MegrumTab {
        let lowercasedPath = rawPath.lowercased()
        if lowercasedPath.contains("meguri")
            || lowercasedPath.contains("groom")
            || lowercasedPath.contains("board") {
            return .meguri
        }
        if lowercasedPath.contains("proposal")
            || lowercasedPath.contains("trade")
            || lowercasedPath.contains("transaction")
            || lowercasedPath.contains("deal")
            || lowercasedPath.contains("dispute") {
            return .trades
        }
        if lowercasedPath.contains("inventory") || lowercasedPath.contains("goods") {
            return .inventory
        }
        if lowercasedPath.contains("wish") {
            return .wish
        }
        return .home
    }

    private static func normalizedPath(
        from rawPath: String,
        components: URLComponents?
    ) -> String {
        guard let components else {
            return rawPath.components(separatedBy: "?").first ?? rawPath
        }

        var pathParts: [String] = []
        if components.scheme != nil, let host = components.host, !host.isEmpty {
            pathParts.append(host)
        }
        pathParts.append(contentsOf: components.path.split(separator: "/").map(String.init))

        let path = pathParts.joined(separator: "/")
        if path.isEmpty {
            return rawPath.components(separatedBy: "?").first ?? rawPath
        }
        return "/" + path
    }
}
