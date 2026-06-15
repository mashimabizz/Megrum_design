import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI

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
        trimmedNonEmpty(prefecture) ?? "未設定"
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
            self.prefecture = trimmedNonEmpty(localDraft.normalizedPrefecture)
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

private extension UserGender {
    var label: String {
        displayName
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

@MainActor
struct OwnProfileScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onClose: (() -> Void)?
    @State private var localDraft: OwnProfileEditDraft?
    @State private var editDraft = OwnProfileEditDraft.empty
    @State private var isProfileEditorPresented = false
    @State private var showsProfileCompletion = false
    @State private var selectedProfileTab: ProfileVisualTab = .goods
    @Environment(\.dismiss) private var dismiss

    private var summary: OwnProfileSummary? {
        OwnProfileSummary(
            viewer: appState.viewer,
            inventoryCount: appState.inventory.count,
            wishCount: appState.wishes.count,
            listingCount: appState.listings.count,
            proposals: appState.proposals,
            localDraft: localDraft
        )
    }

    var body: some View {
        ScrollView {
            OwnProfileContent(
                summary: summary,
                selectedProfileTab: $selectedProfileTab,
                profileBio: summary.map(profileBio) ?? "",
                profileChips: profileChips,
                profileGridItems: profileGridItems(for: selectedProfileTab),
                onClose: closePage,
                onEdit: openCurrentProfileEditor
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .sheet(isPresented: $isProfileEditorPresented) {
            NavigationStack {
                OwnProfileEditForm(
                    draft: $editDraft,
                    isSaving: appState.isSavingOwnProfile,
                    onSave: saveProfileDraft
                )
            }
        }
        .alert("プロフィールを更新しました", isPresented: $showsProfileCompletion) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("変更内容をこの画面に反映しました。")
        }
        .onChange(of: appState.viewer) {
            localDraft = nil
        }
        .task {
            await loadSupplementalProfileDataIfNeeded()
        }
    }

    private var profileChips: [String] {
        let selectionChips = appState.userOshiSelections
            .sorted { $0.priority < $1.priority }
            .compactMap { selection -> String? in
                let groupName = trimmedNonEmpty(selection.groupName) ?? trimmedNonEmpty(selection.oshiRequestName)
                let memberName = trimmedNonEmpty(selection.characterName) ?? trimmedNonEmpty(selection.characterRequestName)
                switch (groupName, memberName) {
                case let (.some(group), .some(member)):
                    return "\(group) / \(member)"
                case let (.some(group), .none):
                    return group
                case let (.none, .some(member)):
                    return member
                case (.none, .none):
                    return nil
                }
            }

        if !selectionChips.isEmpty {
            return selectionChips
        }
        return ["推し未設定"]
    }

    private func profileBio(_ summary: OwnProfileSummary) -> String {
        let parts = [
            summary.prefectureText,
            summary.genderText,
            summary.paymentMethodsText
        ].filter { !$0.isEmpty && $0 != "未設定" }
        guard !parts.isEmpty else {
            return "プロフィール情報を編集できます"
        }
        return parts.joined(separator: " / ")
    }

    private func profileGridItems(for tab: ProfileVisualTab) -> [ProfileVisualGridItem] {
        switch tab {
        case .goods:
            return appState.inventory.map { item in
                ProfileVisualGridItem(id: item.id, title: item.title, imageURL: item.imageURL)
            }
        case .listings:
            return listingGridItems()
        case .wish:
            return appState.wishes.map { item in
                ProfileVisualGridItem(id: item.id, title: item.title, imageURL: item.imageURL)
            }
        }
    }

    private func listingGridItems() -> [ProfileVisualGridItem] {
        let inventoryByID = Dictionary(uniqueKeysWithValues: appState.inventory.map { ($0.id, $0) })
        return appState.listings.compactMap { listing in
            guard let firstHave = listing.haves.first,
                  let item = inventoryByID[firstHave.itemID] else {
                return nil
            }
            return ProfileVisualGridItem(id: listing.id, title: item.title, imageURL: item.imageURL)
        }
    }

    private func closePage() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func openCurrentProfileEditor() {
        guard let summary else {
            return
        }
        openProfileEditor(summary: summary)
    }

    private func openProfileEditor(summary: OwnProfileSummary) {
        editDraft = OwnProfileEditDraft(summary: summary)
        isProfileEditorPresented = true
    }

    private func loadSupplementalProfileDataIfNeeded() async {
        if appState.userOshiSelections.isEmpty {
            await appState.loadUserOshiSelections()
        }
        if appState.mailingAddress == nil {
            await appState.loadMailingAddress()
        }
    }

    private func saveProfileDraft(_ savedDraft: OwnProfileEditDraft) async -> Bool {
        let normalized = savedDraft.normalized
        let saved = await appState.updateOwnProfile(
            OwnProfileUpdateInput(
                handle: normalized.handle,
                displayName: normalized.displayName,
                gender: normalized.gender,
                prefecture: trimmedNonEmpty(normalized.prefecture),
                paymentMethods: normalized.paymentMethods,
                avatarURL: normalized.visibleAvatarURL,
                avatarUpload: normalized.avatarUpload,
                clearsAvatar: normalized.clearsAvatar
            )
        )

        if saved {
            localDraft = nil
            showsProfileCompletion = true
        }
        return saved
    }
}

private struct OwnProfileEditForm: View {
    @Binding var draft: OwnProfileEditDraft
    var isSaving = false
    var onSave: (OwnProfileEditDraft) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var avatarError: String?
#if canImport(PhotosUI)
    @State private var selectedAvatarItem: PhotosPickerItem?
#endif
#if os(iOS)
    @State private var isShowingCameraCapture = false
#endif

    var body: some View {
        Form {
            avatarSectionView

            OwnProfileEditProfileFields(
                draft: $draft,
                onSubmitSave: submitSave
            )

            if let error = draft.validationError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                }
            }
        }
        .navigationTitle("プロフィール編集")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    submitSave()
                }
                .disabled(!draft.isValid || isSaving || isSubmitting)
            }
        }
#if canImport(PhotosUI)
        .onChange(of: selectedAvatarItem) { _, item in
            Task {
                await loadSelectedAvatar(item)
            }
        }
#endif
#if os(iOS)
        .sheet(isPresented: $isShowingCameraCapture) {
            NativeCameraCaptureView { imageData in
                loadCapturedAvatar(imageData)
            }
            .ignoresSafeArea()
        }
#endif
    }

    @ViewBuilder
    private var avatarSectionView: some View {
#if canImport(PhotosUI)
        OwnProfileEditAvatarSection(
            draft: $draft,
            avatarError: avatarError,
            selectedAvatarItem: $selectedAvatarItem,
            onShowCamera: showCameraCapture,
            onDeleteAvatar: deleteAvatar
        )
#else
        OwnProfileEditAvatarSection(
            draft: $draft,
            avatarError: avatarError,
            onShowCamera: showCameraCapture,
            onDeleteAvatar: deleteAvatar
        )
#endif
    }

    private func submitSave() {
        Task {
            await save()
        }
    }

    private func showCameraCapture() {
#if os(iOS)
        isShowingCameraCapture = true
#endif
    }

    private func save() async {
        guard draft.isValid, !isSaving, !isSubmitting else {
            return
        }

        isSubmitting = true
        let saved = await onSave(draft.normalized)
        isSubmitting = false
        if saved {
            dismiss()
        }
    }

    private func deleteAvatar() {
        draft.deleteAvatar()
        avatarError = nil
#if canImport(PhotosUI)
        selectedAvatarItem = nil
#endif
    }

    private func loadCapturedAvatar(_ data: Data) {
        let upload = GoodsPhotoUpload(data: data, contentType: "image/jpeg")
        if let uploadError = ownProfileAvatarUploadError(for: upload) {
            draft.clearLocalAvatarUpload()
            avatarError = uploadError
            return
        }
        draft.setLocalAvatarUpload(upload)
        avatarError = nil
#if canImport(PhotosUI)
        selectedAvatarItem = nil
#endif
    }

#if canImport(PhotosUI)
    private func loadSelectedAvatar(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                draft.clearLocalAvatarUpload()
                avatarError = "写真を読み込めませんでした"
                return
            }
            let upload = normalizedPhotoUpload(from: data)
            if let uploadError = ownProfileAvatarUploadError(for: upload) {
                draft.clearLocalAvatarUpload()
                avatarError = uploadError
                return
            }
            draft.setLocalAvatarUpload(upload)
            avatarError = nil
        } catch {
            draft.clearLocalAvatarUpload()
            avatarError = "写真を読み込めませんでした"
        }
    }
#endif

}

private extension UserProfile {
    var prefectureForDisplay: String? {
        trimmedNonEmpty(prefecture)
    }
}

private func trimmedNonEmpty(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
}

func ownProfileAvatarUploadError(for upload: GoodsPhotoUpload) -> String? {
    upload.data.count > goodsEditorMaxPhotoUploadBytes ? "アイコン画像は10MB以下にしてください" : nil
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
