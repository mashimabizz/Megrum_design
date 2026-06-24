import Foundation
import MegrumCore

struct OwnProfileSummary: Equatable, Sendable {
    var displayName: String
    var handle: String
    var prefecture: String?
    var gender: UserGender?
    var paymentMethods: [UserPaymentMethod]
    var paymentNote: String?
    var avatarURL: URL?
    var inventoryCount: Int
    var wishCount: Int
    var activeTradeCount: Int
    var completedTradeCount: Int
    var listingCount: Int

    var prefectureText: String {
        prefecture.nilIfBlank ?? "未設定"
    }

    var handleText: String {
        "@\(handle)"
    }

    var genderText: String {
        gender?.label ?? "未設定"
    }

    var paymentMethodsText: String {
        UserPaymentMethod.displayText(for: paymentMethods, otherNote: paymentNote)
    }

    var activeTradeText: String {
        "\(activeTradeCount)件"
    }

    var completedTradeText: String {
        "\(completedTradeCount)"
    }

    var listingText: String {
        "\(listingCount)"
    }

    init?(
        viewer: UserProfile?,
        inventoryCount: Int,
        wishCount: Int,
        listingCount: Int = 0,
        proposals: [TradeProposal],
        localDraft: OwnProfileEditDraft? = nil
    ) {
        guard let viewer else {
            return nil
        }
        self.displayName = localDraft?.normalizedDisplayName ?? viewer.displayName
        self.handle = localDraft?.normalizedHandle ?? viewer.handle
        if let localDraft {
            self.prefecture = localDraft.normalizedPrefecture.nilIfBlank
        } else {
            self.prefecture = viewer.prefectureForDisplay
        }
        self.gender = localDraft?.gender ?? viewer.gender
        self.paymentMethods = localDraft?.paymentMethods ?? viewer.paymentMethods
        self.paymentNote = viewer.paymentNote
        if let localDraft {
            self.avatarURL = localDraft.visibleAvatarURL
        } else {
            self.avatarURL = viewer.avatarURL
        }
        self.inventoryCount = inventoryCount
        self.wishCount = wishCount
        self.listingCount = listingCount
        self.activeTradeCount = proposals.filter(\.status.isOwnProfileActiveTrade).count
        self.completedTradeCount = proposals.filter { $0.status == .completed }.count
    }
}

enum OwnProfileOshiTagPresentation {
    static let fallbackTitle = "推し未設定"

    static func tagItems(from selections: [UserOshiSelection]) -> [ProfileVisualTagItem] {
        let tags = PublicOshiTag.makeTags(from: selections)
        guard !tags.isEmpty else {
            return [
                ProfileVisualTagItem(
                    title: fallbackTitle,
                    colorKey: fallbackTitle
                )
            ]
        }

        return tags.map { tag in
            ProfileVisualTagItem(
                title: tag.title,
                colorKey: tag.colorKey
            )
        }
    }
}

struct OwnProfileEditDraft: Equatable, Sendable {
    var handle: String
    var displayName: String
    var prefecture: String
    var gender: UserGender?
    var paymentMethods: [UserPaymentMethod]
    var existingAvatarURL: URL?
    var localAvatarData: Data?
    var localAvatarContentType: String?
    var clearsAvatar: Bool

    static let empty = OwnProfileEditDraft(
        handle: "",
        displayName: "",
        prefecture: "",
        gender: nil,
        paymentMethods: []
    )

    init(
        handle: String,
        displayName: String,
        prefecture: String,
        gender: UserGender?,
        paymentMethods: [UserPaymentMethod] = [],
        existingAvatarURL: URL? = nil,
        localAvatarData: Data? = nil,
        localAvatarContentType: String? = nil,
        clearsAvatar: Bool = false
    ) {
        self.handle = handle
        self.displayName = displayName
        self.prefecture = prefecture
        self.gender = gender
        self.paymentMethods = Self.normalizedPaymentMethods(paymentMethods)
        self.existingAvatarURL = existingAvatarURL
        self.localAvatarData = localAvatarData
        self.localAvatarContentType = localAvatarContentType
        self.clearsAvatar = clearsAvatar
    }

    init(summary: OwnProfileSummary) {
        self.handle = summary.handle
        self.displayName = summary.displayName
        self.prefecture = summary.prefecture ?? ""
        self.gender = summary.gender
        self.paymentMethods = summary.paymentMethods
        self.existingAvatarURL = summary.avatarURL
        self.localAvatarData = nil
        self.localAvatarContentType = nil
        self.clearsAvatar = false
    }

    var normalizedHandle: String {
        MegrumAppStateInputNormalizer.profileHandle(handle) ?? ""
    }

    var normalizedDisplayName: String {
        MegrumAppStateInputNormalizer.trimmedText(displayName)
    }

    var normalizedPrefecture: String {
        MegrumAppStateInputNormalizer.trimmedText(prefecture)
    }

    var normalized: OwnProfileEditDraft {
        OwnProfileEditDraft(
            handle: normalizedHandle,
            displayName: normalizedDisplayName,
            prefecture: normalizedPrefecture,
            gender: gender,
            paymentMethods: Self.normalizedPaymentMethods(paymentMethods),
            existingAvatarURL: existingAvatarURL,
            localAvatarData: localAvatarData,
            localAvatarContentType: localAvatarContentType,
            clearsAvatar: clearsAvatar
        )
    }

    var avatarUpload: GoodsPhotoUpload? {
        guard let localAvatarData else {
            return nil
        }
        return GoodsPhotoUpload(data: localAvatarData, contentType: localAvatarContentType ?? "image/jpeg")
    }

    var hasLocalAvatarUpload: Bool {
        localAvatarData != nil
    }

    var hasVisibleAvatar: Bool {
        localAvatarData != nil || visibleAvatarURL != nil
    }

    var visibleAvatarURL: URL? {
        guard !clearsAvatar, localAvatarData == nil else {
            return nil
        }
        return existingAvatarURL
    }

    mutating func setLocalAvatarUpload(_ upload: GoodsPhotoUpload) {
        localAvatarData = upload.data
        localAvatarContentType = upload.contentType
        clearsAvatar = false
    }

    mutating func clearLocalAvatarUpload() {
        localAvatarData = nil
        localAvatarContentType = nil
    }

    mutating func deleteAvatar() {
        localAvatarData = nil
        localAvatarContentType = nil
        clearsAvatar = true
    }

    mutating func setPaymentMethod(_ method: UserPaymentMethod, isSelected: Bool) {
        if isSelected {
            paymentMethods.append(method)
        } else {
            paymentMethods.removeAll { $0 == method }
        }
        paymentMethods = Self.normalizedPaymentMethods(paymentMethods)
    }

    func containsPaymentMethod(_ method: UserPaymentMethod) -> Bool {
        paymentMethods.contains(method)
    }

    var validationError: String? {
        OwnProfileEditValidation.validationError(for: self)
    }

    var isValid: Bool {
        validationError == nil
    }

    private static func normalizedPaymentMethods(_ methods: [UserPaymentMethod]) -> [UserPaymentMethod] {
        UserPaymentMethod.allCases.filter { method in
            methods.contains(method)
        }
    }
}

enum OwnProfileEditValidation {
    static func validationError(for draft: OwnProfileEditDraft) -> String? {
        let handle = draft.normalizedHandle
        if !MegrumAppStateInputNormalizer.isValidProfileHandle(handle) {
            return "ユーザーIDは半角英数字・_ の3〜20文字で入力してください"
        }

        let displayName = draft.normalizedDisplayName
        if displayName.isEmpty || displayName.count > 50 {
            return "表示名は1〜50文字で入力してください"
        }

        let prefecture = draft.normalizedPrefecture
        if !prefecture.isEmpty && !OwnProfileEditValidation.japanPrefectures.contains(prefecture) {
            return "活動エリアは都道府県から選択してください"
        }

        return nil
    }

    static let japanPrefectures = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県",
        "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県",
        "奈良県", "和歌山県", "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県",
        "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]
}

func ownProfileAvatarUploadError(for upload: GoodsPhotoUpload) -> String? {
    upload.data.count > goodsEditorMaxPhotoUploadBytes ? "アイコン画像は10MB以下にしてください" : nil
}

private extension UserGender {
    var label: String {
        displayName
    }
}

private extension UserProfile {
    var prefectureForDisplay: String? {
        prefecture.nilIfBlank
    }
}

private extension ProposalStatus {
    var isOwnProfileActiveTrade: Bool {
        switch self {
        case .sent, .negotiating, .agreementOneSide, .agreed:
            true
        case .draft, .rejected, .expired, .cancelled, .completed:
            false
        }
    }
}
