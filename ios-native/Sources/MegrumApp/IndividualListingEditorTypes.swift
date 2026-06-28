import Foundation
import MegrumCore

enum IndividualListingEditorStep: Int, CaseIterable, Identifiable {
    case haves = 1
    case options = 2
    case exchange = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .haves:
            "譲るものを選ぶ"
        case .options:
            "欲しいものを登録"
        case .exchange:
            "交換条件を設定する"
        }
    }
}

public enum IndividualListingHandoffDraft: String, CaseIterable, Identifiable, Sendable {
    case local
    case mail
    case both

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .local:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地交換・郵送OK"
        }
    }

    var symbolName: String {
        switch self {
        case .local:
            "hand.raised"
        case .mail:
            "envelope"
        case .both:
            "mappin.and.ellipse"
        }
    }
}

public enum IndividualListingShippingFeeDraft: String, CaseIterable, Identifiable, Sendable {
    case owner
    case partner
    case negotiate

    public var id: String { rawValue }

    static let selectableCases: [Self] = [.owner, .negotiate]

    var title: String {
        switch self {
        case .owner:
            "自己負担"
        case .partner:
            "相手負担"
        case .negotiate:
            "要相談"
        }
    }
}

public enum IndividualListingShippingDaysDraft: String, CaseIterable, Identifiable, Sendable {
    case oneDay
    case twoToFourDays
    case afterFiveDays

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay:
            "成立後1日以内"
        case .twoToFourDays:
            "2〜4日以内"
        case .afterFiveDays:
            "5日以降"
        }
    }
}

enum IndividualListingEditorMode: Equatable {
    case create(preselectedWishID: UUID?)
    case edit(IndividualListing)

    var isEditing: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
}

enum IndividualListingOptionKind: String, CaseIterable, Identifiable {
    case wish
    case condition
    case cash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wish:
            "Wishから選ぶ"
        case .condition:
            "条件から選ぶ"
        case .cash:
            "定価"
        }
    }
}

enum IndividualListingHaveOfferKind: String, CaseIterable, Identifiable {
    case goods
    case cash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goods:
            "譲から選ぶ"
        case .cash:
            "定価で選ぶ"
        }
    }
}

enum IndividualListingCashPricingMode: String, CaseIterable, Identifiable {
    case listPrice
    case specifiedAmount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .listPrice:
            "定価"
        case .specifiedAmount:
            "金額指定"
        }
    }
}
