import Foundation

public enum GoodsReportReason: String, Codable, Sendable, CaseIterable, Identifiable {
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

public struct GoodsReportCreateInput: Equatable, Sendable {
    public var goodsItemID: UUID
    public var reportedUserID: UUID
    public var reason: GoodsReportReason
    public var note: String?

    public init(goodsItemID: UUID, reportedUserID: UUID, reason: GoodsReportReason, note: String? = nil) {
        self.goodsItemID = goodsItemID
        self.reportedUserID = reportedUserID
        self.reason = reason
        self.note = note
    }
}

public struct GoodsReportTicket: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var goodsItemID: UUID
    public var status: String
    public var submittedAt: Date

    public init(id: UUID, goodsItemID: UUID, status: String, submittedAt: Date = .now) {
        self.id = id
        self.goodsItemID = goodsItemID
        self.status = status
        self.submittedAt = submittedAt
    }
}
