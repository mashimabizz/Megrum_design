import Foundation
import MegrumCore

struct OwnProfileEditDraft: Equatable, Sendable {
    var handle: String
    var displayName: String
    var bio: String
    var prefecture: String
    var gender: UserGender?
    var birthDate: Date?
    var paymentMethods: [UserPaymentMethod]
    var existingAvatarURL: URL?
    var localAvatarData: Data?
    var localAvatarContentType: String?
    var clearsAvatar: Bool

    static let empty = OwnProfileEditDraft(
        handle: "",
        displayName: "",
        bio: "",
        prefecture: "",
        gender: .female,
        birthDate: nil,
        paymentMethods: []
    )

    init(
        handle: String,
        displayName: String,
        bio: String = "",
        prefecture: String,
        gender: UserGender?,
        birthDate: Date? = nil,
        paymentMethods: [UserPaymentMethod] = [],
        existingAvatarURL: URL? = nil,
        localAvatarData: Data? = nil,
        localAvatarContentType: String? = nil,
        clearsAvatar: Bool = false
    ) {
        self.handle = handle
        self.displayName = displayName
        self.bio = bio
        self.prefecture = prefecture
        self.gender = Self.editableGender(gender)
        self.birthDate = birthDate
        self.paymentMethods = Self.normalizedPaymentMethods(paymentMethods)
        self.existingAvatarURL = existingAvatarURL
        self.localAvatarData = localAvatarData
        self.localAvatarContentType = localAvatarContentType
        self.clearsAvatar = clearsAvatar
    }

    init(summary: OwnProfileSummary) {
        self.handle = summary.handle
        self.displayName = summary.displayName
        self.bio = summary.bio ?? ""
        self.prefecture = summary.prefecture ?? ""
        self.gender = Self.editableGender(summary.gender)
        self.birthDate = summary.birthDate
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

    var normalizedBio: String {
        MegrumAppStateInputNormalizer.trimmedText(bio)
    }

    var normalizedPrefecture: String {
        MegrumAppStateInputNormalizer.trimmedText(prefecture)
    }

    var normalized: OwnProfileEditDraft {
        OwnProfileEditDraft(
            handle: normalizedHandle,
            displayName: normalizedDisplayName,
            bio: normalizedBio,
            prefecture: normalizedPrefecture,
            gender: Self.editableGender(gender),
            birthDate: birthDate,
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

    static func editableGender(_ gender: UserGender?) -> UserGender {
        gender == .male ? .male : .female
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
