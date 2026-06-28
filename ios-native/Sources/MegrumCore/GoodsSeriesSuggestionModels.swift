import Foundation

public struct GoodsSeriesSuggestionImage: Equatable, Sendable {
    public var data: Data?
    public var contentType: String?
    public var imageURL: URL?

    public init(data: Data, contentType: String = "image/jpeg") {
        self.data = data
        self.contentType = contentType
        self.imageURL = nil
    }

    public init(imageURL: URL) {
        self.data = nil
        self.contentType = nil
        self.imageURL = imageURL
    }

    public var hasSource: Bool {
        if let data, !data.isEmpty {
            return true
        }
        return imageURL != nil
    }
}

public struct GoodsSeriesSuggestionInput: Equatable, Sendable {
    public var images: [GoodsSeriesSuggestionImage]
    public var groupName: String?
    public var memberName: String?
    public var goodsTypeName: String?
    public var existingCandidateNames: [String]

    public init(
        images: [GoodsSeriesSuggestionImage],
        groupName: String? = nil,
        memberName: String? = nil,
        goodsTypeName: String? = nil,
        existingCandidateNames: [String] = []
    ) {
        self.images = images
        self.groupName = groupName
        self.memberName = memberName
        self.goodsTypeName = goodsTypeName
        self.existingCandidateNames = existingCandidateNames
    }
}
