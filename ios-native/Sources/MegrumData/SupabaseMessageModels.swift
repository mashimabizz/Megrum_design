import Foundation
import MegrumCore

public enum SupabaseMessageClientError: Error, Equatable, Sendable {
    case invalidBody
    case invalidPhotoMessageType
    case invalidPhotoURL
    case invalidLocation
    case invalidMetadata
}

public enum SupabaseMessageArrivalStatus: String, CaseIterable, Sendable {
    case enroute
    case arrived
    case left

    var defaultBody: String {
        switch self {
        case .enroute:
            "向かっています"
        case .arrived:
            "到着しました"
        case .left:
            "離れました"
        }
    }
}

public enum SupabaseMessageLateMinutes: Int, CaseIterable, Sendable {
    case ten = 10
    case twenty = 20
    case thirty = 30
    case sixty = 60
    case ninety = 90

    public init(minutes: Int) throws {
        guard let value = Self(rawValue: minutes) else {
            throw SupabaseMessageClientError.invalidMetadata
        }
        self = value
    }

    var label: String {
        switch self {
        case .sixty:
            "1時間"
        case .ninety:
            "1時間以上"
        case .ten, .twenty, .thirty:
            "\(rawValue)分"
        }
    }
}

public enum SupabaseMessageSystemAction: String, Sendable {
    case cancelRequested = "cancel_requested"
    case cancelApproved = "cancel_approved"
    case lateNotice = "late_notice"
}

extension SupabaseMessageArrivalStatus {
    init(_ status: TradeArrivalStatus) {
        switch status {
        case .enroute:
            self = .enroute
        case .arrived:
            self = .arrived
        case .left:
            self = .left
        }
    }
}
