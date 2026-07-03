import Foundation

enum HomeDiscoveryPrimaryTab: String, CaseIterable, Identifiable {
    case candidates
    case mutual

    var id: String { rawValue }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    static var visibleTabs: [HomeDiscoveryPrimaryTab] {
        [.candidates]
    }

    var title: String {
        switch self {
        case .candidates:
            "マッチ候補"
        case .mutual:
            "相互マッチ(β版)"
        }
    }
}
