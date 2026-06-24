import Foundation

enum HomeDiscoveryPrimaryTab: String, CaseIterable, Identifiable {
    case mutual
    case candidates
    case timeline

    var id: String { rawValue }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    var title: String {
        switch self {
        case .mutual:
            "相互にマッチ"
        case .candidates:
            "マッチ候補"
        case .timeline:
            "募集タイムライン"
        }
    }
}
