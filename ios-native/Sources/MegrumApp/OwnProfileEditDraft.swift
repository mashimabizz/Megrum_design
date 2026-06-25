import Foundation
import MegrumCore

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

func ownProfileAvatarUploadError(for upload: GoodsPhotoUpload) -> String? {
    upload.data.count > goodsEditorMaxPhotoUploadBytes ? "アイコン画像は10MB以下にしてください" : nil
}
