import Foundation
import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI
#if os(iOS)
import UIKit
#endif

@MainActor
struct MeguriProfileSettingsSheet: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var draftState = MeguriProfileSettingsDraftState()
    @State private var isShowingAvatarSourceDialog = false
    @State private var avatarError: String?
#if canImport(PhotosUI)
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
#endif
#if os(iOS)
    @State private var isShowingCameraCapture = false
#endif

    private var currentProfile: MeguriProfile? {
        appState.meguriProfile
    }

    private var lockMessage: String? {
        guard let lockedUntil = currentProfile?.lockedUntil() else {
            return nil
        }
        return "次回は\(lockedUntil.formatted(date: .numeric, time: .omitted))以降に変更できます。"
    }

    private var canSave: Bool {
        draftState.canSave(isSaving: appState.isSavingMeguriProfile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headerSection
                identitySection
                nameSection
                avatarSection
                lockSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("めぐりプロフィール")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    if appState.isSavingMeguriProfile {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("保存")
                    }
                }
                .disabled(!canSave)
            }
        }
        .task {
            await appState.loadMeguriProfile(reportsFailure: false)
            hydrateDraft()
        }
        .onChange(of: appState.meguriProfile) { _, _ in
            hydrateDraftIfNeeded()
        }
#if canImport(PhotosUI)
        .photosPicker(
            isPresented: $isShowingPhotoPicker,
            selection: $selectedAvatarItem,
            matching: .images
        )
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
            } onFailure: { message in
                avatarError = message
            }
            .ignoresSafeArea()
        }
#endif
        .confirmationDialog("アイコンを変更", isPresented: $isShowingAvatarSourceDialog, titleVisibility: .visible) {
#if os(iOS)
            if canUseCamera {
                Button("写真を撮る") {
                    isShowingCameraCapture = true
                }
            }
#endif
#if canImport(PhotosUI)
            Button("アルバムから選ぶ") {
                isShowingPhotoPicker = true
            }
#endif
            Button("キャンセル", role: .cancel) {}
        }
        .alert("保存できませんでした", isPresented: Binding(
            get: { draftState.hasAlert },
            set: { if !$0 { draftState.clearAlert() } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(draftState.localAlertMessage ?? "")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .center, spacing: 10) {
            Button {
                isShowingAvatarSourceDialog = true
            } label: {
                editableAvatarPreview
                    .frame(width: 112, height: 98)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(draftState.usesPublicProfile)
            .accessibilityLabel("めぐりプロフィールのアイコンを変更")

            if let avatarError {
                Label(avatarError, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.conditionPossible)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var editableAvatarPreview: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarPreviewImage
                .frame(width: 76, height: 76)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.86), lineWidth: 2)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 6)

            if draftState.usesPublicProfile {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(MegrumTheme.lavender, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(.black, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            }
        }
        .padding(.bottom, 2)
        .frame(width: 112, height: 98)
    }

    @ViewBuilder
    private var avatarPreviewImage: some View {
        if draftState.usesPublicProfile {
            OwnProfileAvatarImage(
                avatarURL: appState.viewer?.avatarURL,
                localData: nil,
                initial: syncedPublicDisplayName,
                size: 76,
                showsChrome: false
            )
        } else if draftState.hasCustomAvatar {
            OwnProfileAvatarImage(
                avatarURL: draftState.visibleAvatarURL,
                localData: draftState.localAvatarData,
                initial: draftState.avatarFallback,
                size: 76,
                showsChrome: false
            )
        } else {
            MeguriProfileAvatarView(
                avatarID: draftState.selectedAvatarID,
                avatarURL: nil,
                fallback: draftState.avatarFallback,
                size: 76
            )
        }
    }

    private var identitySection: some View {
        Toggle(isOn: $draftState.usesPublicProfile) {
            VStack(alignment: .leading, spacing: 4) {
                Text("グッズ交換プロフィールと同じにする")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("ONにすると、めぐり内でもグッズ交換側の表示名とアイコンを使います。")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(MegrumTheme.lavender)
        .padding(16)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onChange(of: draftState.usesPublicProfile) { _, usesPublicProfile in
            if usesPublicProfile {
                draftState.syncPublicProfile(
                    displayName: appState.viewer?.displayName,
                    avatarURL: appState.viewer?.avatarURL
                )
            }
            avatarError = nil
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("名前")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            nameField

            Text(nameHelpText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var nameField: some View {
        if draftState.usesPublicProfile {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                Text(syncedPublicDisplayName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer(minLength: 0)
            }
            .padding(15)
            .background(
                Color.white.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        } else {
        #if os(iOS)
            TextField("例：まくはり民", text: $draftState.displayName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .padding(15)
                .background(
                    Color.white.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        #else
            TextField("例：まくはり民", text: $draftState.displayName)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .padding(15)
                .background(
                    Color.white.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        #endif
        }
    }

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アイコン")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if draftState.usesPublicProfile {
                Label("専用アイコンに戻したい時は、上のトグルをOFFにしてください。", systemImage: "info.circle.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                LazyVGrid(columns: avatarColumns, spacing: 14) {
                    ForEach(BoardAnonymousAvatarOption.options) { option in
                        avatarButton(option)
                    }
                }
            }
        }
    }

    private var avatarColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }

    private func avatarButton(_ option: BoardAnonymousAvatarOption) -> some View {
        Button {
            draftState.selectPresetAvatar(option.id)
            avatarError = nil
        } label: {
            VStack(spacing: 8) {
                BoardAnonymousAvatar(
                    option: option,
                    isSelected: draftState.selectedAvatarID == option.id,
                    size: 48
                )
                Text(option.title)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                .white.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title)を選択")
    }

    @ViewBuilder
    private var lockSection: some View {
        if let lockMessage {
            Label(lockMessage, systemImage: "lock.fill")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.pink)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    MegrumTheme.pink.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
    }

    private func hydrateDraftIfNeeded() {
        draftState.hydrateIfNeeded(
            profile: currentProfile,
            viewerDisplayName: appState.viewer?.displayName,
            viewerAvatarURL: appState.viewer?.avatarURL
        )
    }

    private func hydrateDraft() {
        draftState.hydrate(
            profile: currentProfile,
            viewerDisplayName: appState.viewer?.displayName,
            viewerAvatarURL: appState.viewer?.avatarURL
        )
    }

    private func save() {
        Task {
            let saved = await appState.saveMeguriProfile(
                displayName: draftState.displayNameForSave(
                    currentProfile: currentProfile,
                    syncedPublicDisplayName: syncedPublicDisplayName
                ),
                avatarID: draftState.avatarIDForSave(currentProfile: currentProfile),
                avatarURL: draftState.avatarURLForSave(currentProfile: currentProfile),
                avatarUpload: draftState.avatarUploadForSave(),
                clearsAvatarURL: draftState.clearsAvatarURLForSave(),
                usesPublicProfile: draftState.usesPublicProfile
            )
            if saved {
                dismiss()
            } else {
                draftState.setFailureMessage(appState.errorMessage)
            }
        }
    }

    private var syncedPublicDisplayName: String {
        appState.viewer?.displayName.nilIfBlank
            ?? draftState.displayName.nilIfBlank
            ?? "めぐりユーザー"
    }

    private var nameHelpText: String {
        if draftState.usesPublicProfile {
            return "グッズ交換側のプロフィールを変更すると、めぐり内の表示も自動で切り替わります。"
        }
        return "全ユーザーで同じ名前は使えません。変更できるのは1ヶ月に1回です。"
    }

    private var canUseCamera: Bool {
#if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
#else
        false
#endif
    }

    private func loadCapturedAvatar(_ data: Data) {
        let upload = GoodsPhotoUpload(data: data, contentType: "image/jpeg")
        applyAvatarUpload(upload)
    }

#if canImport(PhotosUI)
    private func loadSelectedAvatar(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                avatarError = "写真を読み込めませんでした"
                draftState.clearLocalAvatarUpload()
                return
            }
            applyAvatarUpload(normalizedPhotoUpload(from: data))
        } catch {
            avatarError = "写真を読み込めませんでした"
            draftState.clearLocalAvatarUpload()
        }
    }
#endif

    private func applyAvatarUpload(_ upload: GoodsPhotoUpload) {
        if let uploadError = ownProfileAvatarUploadError(for: upload) {
            avatarError = uploadError
            draftState.clearLocalAvatarUpload()
            return
        }
        draftState.setLocalAvatarUpload(upload)
        avatarError = nil
#if canImport(PhotosUI)
        selectedAvatarItem = nil
#endif
    }
}
