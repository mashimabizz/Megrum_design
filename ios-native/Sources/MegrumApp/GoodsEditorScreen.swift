import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI

enum GoodsEditorMode: String, CaseIterable, Identifiable {
    case create
    case edit
    case readonly

    var id: String { rawValue }

    var badgeTitle: String {
        switch self {
        case .create:
            "NEW"
        case .edit:
            "EDIT"
        case .readonly:
            "詳細のみ"
        }
    }
}

enum GoodsEditorRoute: Identifiable {
    case create(GoodsEntryKind)
    case edit(GoodsItem, GoodsEntryKind)

    var id: String {
        switch self {
        case let .create(kind):
            "create-\(kind.rawValue)"
        case let .edit(item, kind):
            "edit-\(kind.rawValue)-\(item.id.uuidString)"
        }
    }

    var mode: GoodsEditorMode {
        switch self {
        case .create:
            .create
        case .edit:
            .edit
        }
    }

    var kind: GoodsEntryKind {
        switch self {
        case let .create(kind), let .edit(_, kind):
            kind
        }
    }

    var item: GoodsItem? {
        switch self {
        case .create:
            nil
        case let .edit(item, _):
            item
        }
    }
}

enum GoodsEditorStatus: String, CaseIterable, Identifiable, Equatable {
    case forTrade = "for_trade"
    case keep
    case wishActive = "active"
    case wishAchieved = "achieved"

    var id: String { rawValue }

    static func defaultStatus(for kind: GoodsEntryKind) -> GoodsEditorStatus {
        kind == .inventory ? .forTrade : .wishActive
    }

    static func options(for kind: GoodsEntryKind) -> [GoodsEditorStatus] {
        switch kind {
        case .inventory:
            [.forTrade, .keep]
        case .wish:
            [.wishActive, .wishAchieved]
        }
    }

    func isValid(for kind: GoodsEntryKind) -> Bool {
        Self.options(for: kind).contains(self)
    }

    var title: String {
        switch self {
        case .forTrade:
            "譲る候補"
        case .keep:
            "自分用キープ"
        case .wishActive:
            "探し中"
        case .wishAchieved:
            "入手済み"
        }
    }

    var systemImage: String {
        switch self {
        case .forTrade:
            "arrow.left.arrow.right.circle"
        case .keep:
            "archivebox"
        case .wishActive:
            "heart"
        case .wishAchieved:
            "checkmark.seal"
        }
    }
}

enum GoodsEditorSaveBlocker: Equatable, Identifiable {
    case editPersistence
    case memberPersistence
    case tagPersistence
    case photoPersistence
    case statusPersistence(GoodsEditorStatus)

    var id: String {
        switch self {
        case .editPersistence:
            "edit"
        case .memberPersistence:
            "member"
        case .tagPersistence:
            "tags"
        case .photoPersistence:
            "photo"
        case let .statusPersistence(status):
            "status-\(status.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .editPersistence:
            "既存グッズの更新APIが未接続"
        case .memberPersistence:
            "メンバー保存が未接続"
        case .tagPersistence:
            "グッズタグ保存が未接続"
        case .photoPersistence:
            "写真アップロード保存が未接続"
        case let .statusPersistence(status):
            "「\(status.title)」保存が未接続"
        }
    }

    var message: String {
        switch self {
        case .editPersistence:
            "現在の共通境界には create / archive / delete のみがあり、更新用の状態・repository API がありません。"
        case .memberPersistence:
            "`GoodsEntryInput` に memberID / characterID がないため、選択を保存できません。"
        case .tagPersistence:
            "`goods_inventory_tags` の読み書き境界がSwift Native側に未追加です。"
        case .photoPersistence:
            "`photo_urls` とStorage uploadを保存する境界が未追加です。"
        case .statusPersistence:
            "`GoodsEntryInput` は在庫を `for_trade`、Wishを `wanted` として作成する最小境界のままです。"
        }
    }
}

struct GoodsEditorDraft: Equatable {
    var mode: GoodsEditorMode
    var entryKind: GoodsEntryKind
    var title: String
    var groupID: UUID?
    var memberID: UUID?
    var goodsTypeID: UUID?
    var quantity: Int
    var status: GoodsEditorStatus
    var tagNames: [String]
    var hasLocalPhoto: Bool
    var existingItemID: UUID?

    init(mode: GoodsEditorMode = .create, entryKind: GoodsEntryKind = .inventory, item: GoodsItem? = nil) {
        self.mode = mode
        self.entryKind = entryKind
        self.title = item?.title ?? ""
        self.groupID = item?.groupID
        self.memberID = item?.memberID
        self.goodsTypeID = item?.goodsTypeID
        self.quantity = max(1, min(item?.quantity ?? 1, 999))
        self.status = Self.defaultStatus(mode: mode, entryKind: entryKind)
        self.tagNames = Self.normalizedTags(item?.tags.map(\.name) ?? [])
        self.hasLocalPhoto = item?.imageURL != nil
        self.existingItemID = item?.id
    }

    var isEditingExistingItem: Bool {
        mode != .create || existingItemID != nil
    }

    var normalizedQuantity: Int {
        max(1, min(quantity, 999))
    }

    mutating func setEntryKind(_ kind: GoodsEntryKind) {
        entryKind = kind
        if !status.isValid(for: kind) {
            status = Self.defaultStatus(mode: mode, entryKind: kind)
        }
    }

    mutating func addTag(_ rawTag: String) {
        let normalized = Self.normalizedTag(rawTag)
        guard let normalized, tagNames.count < 5 else {
            return
        }
        if !tagNames.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            tagNames.append(normalized)
        }
    }

    mutating func removeTag(_ tag: String) {
        tagNames.removeAll { $0 == tag }
    }

    func resolvedTitle(groupName: String?, memberName: String?, goodsTypeName: String?) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return [memberName, groupName, goodsTypeName]
            .compactMap { value in
                let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedValue?.isEmpty == false ? trimmedValue : nil
            }
            .joined(separator: " ")
    }

    func createInput(groupName: String? = nil, memberName: String? = nil, goodsTypeName: String? = nil) -> GoodsEntryInput? {
        guard mode == .create,
              blockingReasons.isEmpty,
              let groupID,
              let goodsTypeID
        else {
            return nil
        }
        let resolved = resolvedTitle(groupName: groupName, memberName: memberName, goodsTypeName: goodsTypeName)
        guard !resolved.isEmpty else {
            return nil
        }
        return GoodsEntryInput(
            kind: entryKind,
            title: resolved,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            quantity: normalizedQuantity
        )
    }

    var blockingReasons: [GoodsEditorSaveBlocker] {
        var reasons: [GoodsEditorSaveBlocker] = []
        if isEditingExistingItem {
            reasons.append(.editPersistence)
        }
        if memberID != nil {
            reasons.append(.memberPersistence)
        }
        if !tagNames.isEmpty {
            reasons.append(.tagPersistence)
        }
        if hasLocalPhoto {
            reasons.append(.photoPersistence)
        }
        if status != Self.defaultStatus(mode: mode, entryKind: entryKind) {
            reasons.append(.statusPersistence(status))
        }
        return reasons
    }

    static func defaultStatus(mode: GoodsEditorMode, entryKind: GoodsEntryKind) -> GoodsEditorStatus {
        if mode == .readonly {
            return entryKind == .inventory ? .forTrade : .wishActive
        }
        return GoodsEditorStatus.defaultStatus(for: entryKind)
    }

    private static func normalizedTags(_ tags: [String]) -> [String] {
        tags.reduce(into: []) { result, tag in
            guard result.count < 5, let normalized = normalizedTag(tag) else {
                return
            }
            if !result.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
                result.append(normalized)
            }
        }
    }

    private static func normalizedTag(_ tag: String) -> String? {
        let normalized = tag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : String(normalized.prefix(40))
    }
}

struct GoodsEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var route: GoodsEditorRoute

    @Environment(\.dismiss) private var dismiss
    @State private var draft: GoodsEditorDraft
    @State private var tagDraft = ""
    @State private var didAssignDefaults = false
    @FocusState private var focusedField: Field?
    #if canImport(PhotosUI)
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    private enum Field {
        case title
        case tag
    }

    init(appState: MegrumAppState, route: GoodsEditorRoute) {
        self.appState = appState
        self.route = route
        _draft = State(initialValue: GoodsEditorDraft(mode: route.mode, entryKind: route.kind, item: route.item))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                modeSection
                photoSection
                titleSection
                groupSection
                memberSection
                goodsTypeSection
                quantitySection
                statusSection
                tagsSection
                unsupportedSection
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            await loadChoices()
        }
        .onChange(of: appState.oshiGroups) { _, _ in
            assignDefaultsIfNeeded()
        }
        .onChange(of: appState.goodsTypes) { _, _ in
            assignDefaultsIfNeeded()
        }
        .onChange(of: draft.groupID) { _, newValue in
            Task {
                await loadMembers(for: newValue)
            }
        }
    }

    private var navigationTitle: String {
        if draft.mode == .edit {
            return draft.entryKind == .inventory ? "在庫を編集" : "Wishを編集"
        }
        return draft.entryKind == .inventory ? "在庫に追加" : "Wishに追加"
    }

    private var selectedGroup: OshiGroup? {
        guard let groupID = draft.groupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == groupID }
    }

    private var selectedMember: OshiCharacter? {
        guard let memberID = draft.memberID else {
            return nil
        }
        return appState.oshiCharacters.first { $0.id == memberID }
    }

    private var selectedGoodsType: GoodsType? {
        guard let goodsTypeID = draft.goodsTypeID else {
            return nil
        }
        return appState.goodsTypes.first { $0.id == goodsTypeID }
    }

    private var resolvedTitlePreview: String {
        draft.resolvedTitle(
            groupName: selectedGroup?.name,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    private var canSave: Bool {
        draft.createInput(
            groupName: selectedGroup?.name,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name
        ) != nil && !appState.isCreatingGoodsEntry
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: draft.entryKind == .inventory ? "shippingbox" : "heart")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(headerGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(navigationTitle)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(draft.mode.badgeTitle)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }

            Text("RN版の写真・タグ・メンバー・状態をSwift UIへ寄せた入力面です。未接続の項目は保存前に理由を表示します。")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modeSection: some View {
        editorSection(title: "登録先", systemImage: "tray.and.arrow.down") {
            Picker("登録先", selection: Binding(
                get: { draft.entryKind },
                set: { draft.setEntryKind($0) }
            )) {
                Text("在庫（譲）").tag(GoodsEntryKind.inventory)
                Text("Wish（求）").tag(GoodsEntryKind.wish)
            }
            .pickerStyle(.segmented)
            .disabled(draft.mode != .create)
        }
    }

    private var photoSection: some View {
        editorSection(title: "写真", systemImage: "camera") {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(photoGradient)
                    .aspectRatio(draft.entryKind == .inventory ? 0.78 : 1.45, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: draft.hasLocalPhoto ? "photo.fill.on.rectangle.fill" : "photo")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.82))
                            Text(draft.hasLocalPhoto ? "写真を選択済み" : "未選択")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 16, y: 8)

                HStack(spacing: 10) {
                    #if canImport(PhotosUI)
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("写真を選ぶ", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                    .tint(MegrumTheme.lavender)
                    .disabled(draft.mode == .readonly)
                    .onChange(of: selectedPhotoItem) { _, newValue in
                        draft.hasLocalPhoto = newValue != nil
                    }
                    #else
                    Button {
                        draft.hasLocalPhoto = true
                    } label: {
                        Label("写真を選ぶ", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                    .tint(MegrumTheme.lavender)
                    .disabled(draft.mode == .readonly)
                    #endif

                    Button {
                    } label: {
                        Label("カメラ", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                }

                Text("PhotosPickerはローカル選択までです。Storage upload と photo_urls 保存が入るまでは、写真選択中の保存を止めます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    private var titleSection: some View {
        editorSection(title: "名前", systemImage: "text.cursor") {
            VStack(alignment: .leading, spacing: 10) {
                #if os(iOS)
                TextField("例：ランダムトレカ A", text: $draft.title)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.done)
                    .megrumTextFieldStyle()
                #else
                TextField("例：ランダムトレカ A", text: $draft.title)
                    .focused($focusedField, equals: .title)
                    .megrumTextFieldStyle()
                #endif

                Text(resolvedTitlePreview.isEmpty ? "未入力時はグループと種別から名前を作ります。" : "保存名: \(resolvedTitlePreview)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    private var groupSection: some View {
        editorSection(title: "グループ", systemImage: "person.2") {
            VStack(alignment: .leading, spacing: 10) {
                if appState.isLoadingOshiGroups {
                    ProgressView()
                        .controlSize(.small)
                }

                Picker("グループ", selection: $draft.groupID) {
                    Text("選択してください").tag(UUID?.none)
                    ForEach(appState.oshiGroups) { group in
                        Text(group.name).tag(Optional(group.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(MegrumTheme.lavender)
            }
        }
    }

    private var memberSection: some View {
        editorSection(title: "メンバー / キャラ", systemImage: "person.crop.circle") {
            VStack(alignment: .leading, spacing: 10) {
                if appState.isLoadingOshiCharacters {
                    ProgressView()
                        .controlSize(.small)
                }

                Picker("メンバー", selection: $draft.memberID) {
                    Text("指定なし").tag(UUID?.none)
                    ForEach(appState.oshiCharacters) { member in
                        Text(member.name).tag(Optional(member.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(MegrumTheme.lavender)
                .disabled(draft.groupID == nil)

                Text("現行の作成境界には character_id がないため、選択すると保存は保留になります。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    private var goodsTypeSection: some View {
        editorSection(title: "グッズ種別", systemImage: "square.grid.2x2") {
            VStack(alignment: .leading, spacing: 10) {
                if appState.isLoadingGoodsTypes {
                    ProgressView()
                        .controlSize(.small)
                }

                Picker("グッズ種別", selection: $draft.goodsTypeID) {
                    Text("選択してください").tag(UUID?.none)
                    ForEach(appState.goodsTypes) { goodsType in
                        Text(goodsType.name).tag(Optional(goodsType.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(MegrumTheme.lavender)
            }
        }
    }

    private var quantitySection: some View {
        editorSection(title: "数量", systemImage: "number") {
            Stepper(value: $draft.quantity, in: 1...999) {
                HStack {
                    Text("個数")
                        .font(.headline.weight(.black))
                    Spacer()
                    Text("\(draft.normalizedQuantity)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
        }
    }

    private var statusSection: some View {
        editorSection(title: "状態", systemImage: "checkmark.seal") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(GoodsEditorStatus.options(for: draft.entryKind)) { status in
                    Button {
                        draft.status = status
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: status.systemImage)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(draft.status == status ? .white : MegrumTheme.lavender)
                                .frame(width: 34, height: 34)
                                .background(
                                    draft.status == status ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.12),
                                    in: Circle()
                                )
                            Text(status.title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(MegrumTheme.ink)
                            Spacer()
                            if draft.status == status {
                                Image(systemName: "checkmark")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(MegrumTheme.lavender)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var tagsSection: some View {
        editorSection(title: "タグ", systemImage: "tag") {
            VStack(alignment: .leading, spacing: 12) {
                if draft.tagNames.isEmpty {
                    Text("タグなし")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MegrumTheme.muted)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(draft.tagNames, id: \.self) { tag in
                            Button {
                                draft.removeTag(tag)
                            } label: {
                                HStack(spacing: 5) {
                                    Text("#\(tag)")
                                    Image(systemName: "xmark")
                                        .font(.caption.weight(.black))
                                }
                                .font(.caption.weight(.black))
                                .foregroundStyle(MegrumTheme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.white.opacity(0.9), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 10) {
                    TextField("例：会場限定", text: $tagDraft)
                        .focused($focusedField, equals: .tag)
                        .submitLabel(.done)
                        .onSubmit(addCurrentTag)
                        .megrumTextFieldStyle()
                    Button("追加", action: addCurrentTag)
                        .buttonStyle(.bordered)
                        .tint(MegrumTheme.lavender)
                        .disabled(tagDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.tagNames.count >= 5)
                }

                Text("タグは5件まで入力できます。保存には `goods_inventory_tags` 境界の追加が必要です。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    @ViewBuilder
    private var unsupportedSection: some View {
        if !draft.blockingReasons.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("保存前に接続が必要です", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)

                ForEach(draft.blockingReasons) { reason in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reason.title)
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(reason.message)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(MegrumTheme.pink.opacity(0.14), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(MegrumTheme.pink.opacity(0.32), lineWidth: 1)
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                await save()
            }
        } label: {
            HStack(spacing: 10) {
                if appState.isCreatingGoodsEntry {
                    ProgressView()
                        .tint(.white)
                }
                Text(saveButtonTitle)
                    .font(.headline.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .tint(MegrumTheme.lavender)
        .disabled(!canSave)
    }

    private var saveButtonTitle: String {
        if draft.mode == .edit {
            return "更新APIが未接続です"
        }
        if appState.isCreatingGoodsEntry {
            return "保存しています"
        }
        return draft.entryKind == .inventory ? "在庫を登録" : "Wishを登録"
    }

    private func editorSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.58), lineWidth: 1)
        }
    }

    private func loadChoices() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        assignDefaultsIfNeeded()
        await loadMembers(for: draft.groupID)
        focusedField = draft.mode == .create ? .title : nil
    }

    private func assignDefaultsIfNeeded() {
        guard draft.mode == .create, !didAssignDefaults else {
            return
        }
        if draft.groupID == nil {
            draft.groupID = appState.oshiGroups.first?.id
        }
        if draft.goodsTypeID == nil {
            draft.goodsTypeID = appState.goodsTypes.first?.id
        }
        didAssignDefaults = draft.groupID != nil && draft.goodsTypeID != nil
    }

    private func loadMembers(for groupID: UUID?) async {
        guard let groupID,
              let group = appState.oshiGroups.first(where: { $0.id == groupID })
        else {
            draft.memberID = nil
            return
        }
        await appState.loadOshiCharacters(group: group)
        if let memberID = draft.memberID,
           !appState.oshiCharacters.contains(where: { $0.id == memberID }) {
            draft.memberID = nil
        }
    }

    private func addCurrentTag() {
        draft.addTag(tagDraft)
        tagDraft = ""
    }

    private func save() async {
        guard let input = draft.createInput(
            groupName: selectedGroup?.name,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name
        ) else {
            return
        }
        let saved = await appState.createGoodsEntry(input)
        if saved {
            dismiss()
        }
    }

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.lavender, MegrumTheme.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var photoGradient: LinearGradient {
        LinearGradient(
            colors: [
                MegrumTheme.sky.opacity(0.62),
                MegrumTheme.lavender.opacity(0.72),
                MegrumTheme.pink.opacity(0.54)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct FlowLayout<Content: View>: View {
    var spacing: CGFloat = 8
    var content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: spacing)], alignment: .leading, spacing: spacing) {
            content
        }
    }
}
