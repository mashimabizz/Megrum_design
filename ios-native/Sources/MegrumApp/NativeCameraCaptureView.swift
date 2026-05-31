import SwiftUI

#if os(iOS)
import UIKit

struct NativeCameraCaptureView: View {
    var onCapture: (Data) -> Void
    var onFailure: (String) -> Void = { _ in }
    var onCancel: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessingCapture = false

    var body: some View {
        ZStack {
            NativeCameraPickerController(
                isProcessingCapture: $isProcessingCapture,
                onCapture: onCapture,
                onFailure: onFailure,
                onCancel: onCancel,
                dismiss: dismiss
            )

            if isProcessingCapture {
                NativeCameraProcessingView()
            }
        }
    }
}

private struct NativeCameraPickerController: UIViewControllerRepresentable {
    @Binding var isProcessingCapture: Bool
    var onCapture: (Data) -> Void
    var onFailure: (String) -> Void
    var onCancel: () -> Void
    var dismiss: DismissAction

    func makeUIViewController(context: Context) -> UIViewController {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return UIHostingController(rootView: NativeCameraUnavailableView {
                onFailure("この端末ではカメラを利用できません")
                dismiss()
            })
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isProcessingCapture: $isProcessingCapture,
            onCapture: onCapture,
            onFailure: onFailure,
            onCancel: onCancel,
            dismiss: dismiss
        )
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private var isProcessingCapture: Binding<Bool>
        private let onCapture: (Data) -> Void
        private let onFailure: (String) -> Void
        private let onCancel: () -> Void
        private let dismiss: DismissAction

        init(
            isProcessingCapture: Binding<Bool>,
            onCapture: @escaping (Data) -> Void,
            onFailure: @escaping (String) -> Void,
            onCancel: @escaping () -> Void,
            dismiss: DismissAction
        ) {
            self.isProcessingCapture = isProcessingCapture
            self.onCapture = onCapture
            self.onFailure = onFailure
            self.onCancel = onCancel
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            isProcessingCapture.wrappedValue = true
            guard let image = info[.originalImage] as? UIImage else {
                finishWithFailure("撮影した写真を読み込めませんでした")
                return
            }
            guard let data = image.jpegData(compressionQuality: 0.88) else {
                finishWithFailure("撮影した写真を保存できませんでした")
                return
            }
            isProcessingCapture.wrappedValue = false
            onCapture(data)
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
            dismiss()
        }

        private func finishWithFailure(_ message: String) {
            isProcessingCapture.wrappedValue = false
            onFailure(message)
            dismiss()
        }
    }
}

private struct NativeCameraUnavailableView: View {
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "camera.slash")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("カメラを利用できません")
                    .font(.headline)

                Text("この端末ではカメラを起動できません。写真から選択してください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onClose)
                }
            }
        }
    }
}

private struct NativeCameraProcessingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text("写真を準備しています")
                .font(.headline)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
#endif
