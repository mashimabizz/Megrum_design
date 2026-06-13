import SwiftUI

private struct GoodsEditorFailureAlertsModifier: ViewModifier {
    @Binding var lastSaveFailure: GoodsEditorSaveFailure?
    @Binding var deleteErrorMessage: String?
    var onRetry: () -> Void
    var onClearPhoto: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                "削除できませんでした",
                isPresented: Binding(
                    get: { deleteErrorMessage != nil },
                    set: { if !$0 { deleteErrorMessage = nil } }
                ),
                presenting: deleteErrorMessage
            ) { _ in
                Button("閉じる", role: .cancel) {}
            } message: { message in
                Text(message)
            }
            .alert(
                lastSaveFailure?.title ?? "保存できませんでした",
                isPresented: Binding(
                    get: { lastSaveFailure != nil },
                    set: { if !$0 { lastSaveFailure = nil } }
                ),
                presenting: lastSaveFailure
            ) { failure in
                Button("再試行", action: onRetry)
                if failure.includesPhotoUpload {
                    Button("写真を外す", role: .destructive, action: onClearPhoto)
                }
                Button("閉じる", role: .cancel) {}
            } message: { failure in
                Text(failure.message)
            }
    }
}

private struct GoodsEditorDialogsModifier: ViewModifier {
    @Binding var isShowingPhotoRemovalDialog: Bool
    @Binding var isShowingPhotoSourceDialog: Bool
    @Binding var isShowingPhotoLibraryPicker: Bool
    @Binding var isShowingCameraCapture: Bool
    @Binding var isConfirmingInventoryDelete: Bool
    var photoSourceDialogTitle: String
    var onClearPhoto: () -> Void
    var onDeleteInventory: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "写真の操作",
                isPresented: $isShowingPhotoRemovalDialog,
                titleVisibility: .visible
            ) {
                Button("選択した写真を外す", role: .destructive) {
                    onClearPhoto()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("保存前に選んだ写真だけを外します。ほかの入力内容は残ります。")
            }
            .confirmationDialog(
                photoSourceDialogTitle,
                isPresented: $isShowingPhotoSourceDialog,
                titleVisibility: .visible
            ) {
                #if os(iOS)
                Button("カメラで撮る") {
                    isShowingCameraCapture = true
                }
                #endif
                #if canImport(PhotosUI)
                Button("写真を選ぶ") {
                    isShowingPhotoLibraryPicker = true
                }
                #endif
                Button("閉じる", role: .cancel) {}
            } message: {
                Text("登録する画像を選んでください。")
            }
            .confirmationDialog(
                "このマイグッズを削除しますか？",
                isPresented: $isConfirmingInventoryDelete,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive, action: onDeleteInventory)
                Button("閉じる", role: .cancel) {}
            } message: {
                Text("一覧から外します。過去に譲った履歴は削除できません。")
            }
    }
}

private struct GoodsEditorTradingCardBulkSourceDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onPickCamera: () -> Void
    var onPickPhotoLibrary: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "トレカ専用 AIで一括登録",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                #if os(iOS)
                Button("カメラで撮る", action: onPickCamera)
                #endif
                #if canImport(PhotosUI)
                Button("写真を選ぶ", action: onPickPhotoLibrary)
                #endif
                Button("閉じる", role: .cancel) {}
            } message: {
                Text("濃い無地の背景にトレカを少し離して並べた写真を選んでください。端末内でカード枠を検出し、1枚ずつ追加します。")
            }
    }
}

extension View {
    func goodsEditorFailureAlerts(
        lastSaveFailure: Binding<GoodsEditorSaveFailure?>,
        deleteErrorMessage: Binding<String?>,
        onRetry: @escaping () -> Void,
        onClearPhoto: @escaping () -> Void
    ) -> some View {
        modifier(
            GoodsEditorFailureAlertsModifier(
                lastSaveFailure: lastSaveFailure,
                deleteErrorMessage: deleteErrorMessage,
                onRetry: onRetry,
                onClearPhoto: onClearPhoto
            )
        )
    }

    func goodsEditorDialogs(
        isShowingPhotoRemovalDialog: Binding<Bool>,
        isShowingPhotoSourceDialog: Binding<Bool>,
        isShowingPhotoLibraryPicker: Binding<Bool>,
        isShowingCameraCapture: Binding<Bool>,
        isConfirmingInventoryDelete: Binding<Bool>,
        photoSourceDialogTitle: String,
        onClearPhoto: @escaping () -> Void,
        onDeleteInventory: @escaping () -> Void
    ) -> some View {
        modifier(
            GoodsEditorDialogsModifier(
                isShowingPhotoRemovalDialog: isShowingPhotoRemovalDialog,
                isShowingPhotoSourceDialog: isShowingPhotoSourceDialog,
                isShowingPhotoLibraryPicker: isShowingPhotoLibraryPicker,
                isShowingCameraCapture: isShowingCameraCapture,
                isConfirmingInventoryDelete: isConfirmingInventoryDelete,
                photoSourceDialogTitle: photoSourceDialogTitle,
                onClearPhoto: onClearPhoto,
                onDeleteInventory: onDeleteInventory
            )
        )
    }

    func goodsEditorTradingCardBulkSourceDialog(
        isPresented: Binding<Bool>,
        onPickCamera: @escaping () -> Void,
        onPickPhotoLibrary: @escaping () -> Void
    ) -> some View {
        modifier(
            GoodsEditorTradingCardBulkSourceDialogModifier(
                isPresented: isPresented,
                onPickCamera: onPickCamera,
                onPickPhotoLibrary: onPickPhotoLibrary
            )
        )
    }
}
