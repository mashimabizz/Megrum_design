import MegrumCore

public extension MegrumTab {
    init?(notificationLinkPath: String?) {
        guard let linkPath = notificationLinkPath?.lowercased(), !linkPath.isEmpty else {
            return nil
        }
        if linkPath.contains("meguri") || linkPath.contains("groom") {
            self = .meguri
        } else if linkPath.contains("proposal")
            || linkPath.contains("trade")
            || linkPath.contains("deal")
            || linkPath.contains("dispute") {
            self = .trades
        } else if linkPath.contains("inventory") || linkPath.contains("goods") {
            self = .inventory
        } else if linkPath.contains("wish") {
            self = .wish
        } else {
            self = .home
        }
    }
}
