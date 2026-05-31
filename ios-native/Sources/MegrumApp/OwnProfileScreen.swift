import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct OwnProfileSummary: Equatable, Sendable {
    var displayName: String
    var handle: String
    var prefecture: String?
    var gender: UserGender?
    var avatarURL: URL?
    var inventoryCount: Int
    var wishCount: Int
    var activeTradeCount: Int

    var prefectureText: String {
        trimmedNonEmpty(prefecture) ?? "未設定"
    }

    var handleText: String {
        "@\(handle)"
    }

    var genderText: String {
        gender?.label ?? "未設定"
    }

    var activeTradeText: String {
        "\(activeTradeCount)件"
    }

    init?(
        viewer: UserProfile?,
        inventoryCount: Int,
        wishCount: Int,
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
        if let localDraft {
            self.avatarURL = localDraft.visibleAvatarURL
        } else {
            self.avatarURL = viewer.avatarURL
        }
        self.inventoryCount = inventoryCount
        self.wishCount = wishCount
        self.activeTradeCount = proposals.filter(\.status.isOwnProfileActiveTrade).count
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
    var existingAvatarURL: URL?
    var localAvatarData: Data?
    var localAvatarContentType: String?
    var clearsAvatar: Bool

    static let empty = OwnProfileEditDraft(handle: "", displayName: "", prefecture: "", gender: nil)

    init(
        handle: String,
        displayName: String,
        prefecture: String,
        gender: UserGender?,
        existingAvatarURL: URL? = nil,
        localAvatarData: Data? = nil,
        localAvatarContentType: String? = nil,
        clearsAvatar: Bool = false
    ) {
        self.handle = handle
        self.displayName = displayName
        self.prefecture = prefecture
        self.gender = gender
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
        self.existingAvatarURL = summary.avatarURL
        self.localAvatarData = nil
        self.localAvatarContentType = nil
        self.clearsAvatar = false
    }

    var normalizedHandle: String {
        let trimmed = handle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return String(trimmed.drop(while: { $0 == "@" }))
    }

    var normalizedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedPrefecture: String {
        prefecture.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalized: OwnProfileEditDraft {
        OwnProfileEditDraft(
            handle: normalizedHandle,
            displayName: normalizedDisplayName,
            prefecture: normalizedPrefecture,
            gender: gender,
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

    var validationError: String? {
        OwnProfileEditValidation.validationError(for: self)
    }

    var isValid: Bool {
        validationError == nil
    }
}

enum OwnProfileEditValidation {
    static func validationError(for draft: OwnProfileEditDraft) -> String? {
        let handle = draft.normalizedHandle
        if handle.range(of: #"^[a-z0-9_]{3,20}$"#, options: .regularExpression) == nil {
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
    @State private var localDraft: OwnProfileEditDraft?
    @State private var editDraft = OwnProfileEditDraft.empty
    @State private var isProfileEditorPresented = false
    @State private var showsProfileCompletion = false

    private var summary: OwnProfileSummary? {
        OwnProfileSummary(
            viewer: appState.viewer,
            inventoryCount: appState.inventory.count,
            wishCount: appState.wishes.count,
            proposals: appState.proposals,
            localDraft: localDraft
        )
    }

    var body: some View {
        List {
            if let summary {
                Section {
                    OwnProfileHeader(summary: summary)
                        .listRowInsets(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18))
                }

                Section("プロフィール") {
                    OwnProfileInfoRow(title: "ユーザーID", value: summary.handleText, systemImage: "at")
                    OwnProfileInfoRow(title: "性別", value: summary.genderText, systemImage: "person.2")
                    OwnProfileInfoRow(title: "活動エリア", value: summary.prefectureText, systemImage: "mappin.and.ellipse")
                }

                Section("いまの状態") {
                    OwnProfileMetricRow(title: "譲るもの", value: "\(summary.inventoryCount)件", systemImage: "shippingbox")
                    OwnProfileMetricRow(title: "Wish", value: "\(summary.wishCount)件", systemImage: "heart")
                    OwnProfileMetricRow(title: "進行中のやりとり", value: summary.activeTradeText, systemImage: "arrow.left.arrow.right")
                }

                Section {
                    Button {
                        openProfileEditor(summary: summary)
                    } label: {
                        Label("基本プロフィールを編集", systemImage: "square.and.pencil")
                    }

                    NavigationLink {
                        AccountSetupScreen(appState: appState, mode: .edit)
                    } label: {
                        Label("推し設定を編集", systemImage: "sparkles")
                    }
                } footer: {
                    Text("表示名、ユーザーID、性別、活動エリアと、複数の推しを確認できます。")
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "プロフィールを読み込めません",
                        systemImage: "person.crop.circle",
                        description: Text("ログイン状態を確認してからもう一度開いてください。")
                    )
                }
            }
        }
        .navigationTitle("自分のプロフィール")
        .megrumInlineNavigationTitle()
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
    }

    private func openProfileEditor(summary: OwnProfileSummary) {
        editDraft = OwnProfileEditDraft(summary: summary)
        isProfileEditorPresented = true
    }

    private func saveProfileDraft(_ savedDraft: OwnProfileEditDraft) async -> Bool {
        let normalized = savedDraft.normalized
        let saved = await appState.updateOwnProfile(
            OwnProfileUpdateInput(
                handle: normalized.handle,
                displayName: normalized.displayName,
                gender: normalized.gender,
                prefecture: trimmedNonEmpty(normalized.prefecture),
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
    @FocusState private var focusedField: Field?
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
            avatarSection

            Section("基本情報") {
                handleField
                displayNameField
            }

            Section("公開情報") {
                Picker("性別", selection: $draft.gender) {
                    Text("未設定").tag(UserGender?.none)
                    ForEach(UserGender.allCases) { option in
                        Text(option.label).tag(Optional(option))
                    }
                }

                prefecturePicker
            }

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
                    Task {
                        await save()
                    }
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
    private var avatarSection: some View {
        Section("アイコン画像") {
            HStack(alignment: .center, spacing: 16) {
                OwnProfileAvatarImage(
                    avatarURL: draft.visibleAvatarURL,
                    localData: draft.localAvatarData,
                    initial: draft.normalizedDisplayName.first.map(String.init) ?? "M",
                    size: 72
                )

                VStack(alignment: .leading, spacing: 10) {
#if canImport(PhotosUI)
                    PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                        Label("写真を選ぶ", systemImage: "photo")
                    }
#endif

#if os(iOS)
                    Button {
                        isShowingCameraCapture = true
                    } label: {
                        Label("カメラで撮影", systemImage: "camera")
                    }
#endif

                    if draft.hasVisibleAvatar || draft.clearsAvatar {
                        Button(role: .destructive) {
                            deleteAvatar()
                        } label: {
                            Label("アイコンを削除", systemImage: "trash")
                        }
                    }
                }
                .buttonStyle(.borderless)
            }

            if draft.hasLocalAvatarUpload {
                Label("保存すると新しいアイコンに更新されます", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(MegrumTheme.lavender)
            } else if draft.clearsAvatar {
                Label("保存するとアイコンを削除します", systemImage: "trash")
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            }

            if let avatarError {
                Label(avatarError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            }
        }
    }

    @ViewBuilder
    private var prefecturePicker: some View {
        #if os(iOS)
        Picker("活動エリア", selection: $draft.prefecture) {
            Text("指定なし").tag("")
            ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                Text(prefecture).tag(prefecture)
            }
        }
        .pickerStyle(.navigationLink)
        #else
        Picker("活動エリア", selection: $draft.prefecture) {
            Text("指定なし").tag("")
            ForEach(OwnProfileEditValidation.japanPrefectures, id: \.self) { prefecture in
                Text(prefecture).tag(prefecture)
            }
        }
        #endif
    }

    @ViewBuilder
    private var handleField: some View {
        #if os(iOS)
        TextField("ユーザーID", text: $draft.handle)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .handle)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .displayName
            }
        #else
        TextField("ユーザーID", text: $draft.handle)
            .focused($focusedField, equals: .handle)
            .onSubmit {
                focusedField = .displayName
            }
        #endif
    }

    @ViewBuilder
    private var displayNameField: some View {
        #if os(iOS)
        TextField("表示名", text: $draft.displayName)
            .focused($focusedField, equals: .displayName)
            .submitLabel(.done)
            .onSubmit {
                Task {
                    await save()
                }
            }
        #else
        TextField("表示名", text: $draft.displayName)
            .focused($focusedField, equals: .displayName)
            .onSubmit {
                Task {
                    await save()
                }
            }
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

    private enum Field {
        case handle
        case displayName
    }
}

private struct OwnProfileHeader: View {
    var summary: OwnProfileSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OwnProfileAvatarImage(
                avatarURL: summary.avatarURL,
                localData: nil,
                initial: initial,
                size: 78
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.displayName)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(summary.handleText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }

    private var initial: String {
        summary.displayName.first.map(String.init) ?? "M"
    }
}

private struct OwnProfileAvatarImage: View {
    var avatarURL: URL?
    var localData: Data?
    var initial: String
    var size: CGFloat

    var body: some View {
        ZStack {
            avatarContent
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.85), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        .accessibilityLabel("プロフィール画像")
    }

    @ViewBuilder
    private var avatarContent: some View {
#if canImport(UIKit)
        if let localData, let image = UIImage(data: localData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            remoteAvatar(url: avatarURL)
        } else {
            fallbackAvatar
        }
#elseif canImport(AppKit)
        if let localData, let image = NSImage(data: localData) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            remoteAvatar(url: avatarURL)
        } else {
            fallbackAvatar
        }
#else
        if let avatarURL {
            remoteAvatar(url: avatarURL)
        } else {
            fallbackAvatar
        }
#endif
    }

    private func remoteAvatar(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                fallbackAvatar
            }
        }
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.sky],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initial)
                .font(.system(size: size * 0.44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct OwnProfileInfoRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.trailing)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct OwnProfileMetricRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
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
