import Foundation

public enum UserReportReason: String, Codable, Sendable, CaseIterable, Identifiable {
    case spam
    case harassment
    case fakeItem = "fake_item"
    case privacy
    case unsafe
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .spam:
            "スパム・宣伝"
        case .harassment:
            "嫌がらせ"
        case .fakeItem:
            "偽物・説明と違う"
        case .privacy:
            "個人情報が含まれる"
        case .unsafe:
            "危険・不適切"
        case .other:
            "その他"
        }
    }
}

public struct UserReportCreateInput: Equatable, Sendable {
    public var targetUserID: UUID
    public var reason: UserReportReason
    public var note: String?

    public init(targetUserID: UUID, reason: UserReportReason, note: String? = nil) {
        self.targetUserID = targetUserID
        self.reason = reason
        self.note = note
    }
}

public struct UserReportTicket: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var targetUserID: UUID
    public var status: String
    public var submittedAt: Date

    public init(id: UUID, targetUserID: UUID, status: String, submittedAt: Date = .now) {
        self.id = id
        self.targetUserID = targetUserID
        self.status = status
        self.submittedAt = submittedAt
    }
}
