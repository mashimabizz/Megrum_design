import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI

struct OwnProfileEditForm: View {
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
