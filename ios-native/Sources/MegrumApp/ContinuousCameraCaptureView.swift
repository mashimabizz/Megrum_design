import MegrumDesign
import SwiftUI
#if os(iOS)
import AVFoundation
import UIKit

/// 連続撮影カメラ（マイグッズ/ほしいものの複数枚登録用）。
/// シャッターを切るたびに onCapture が呼ばれ、左下にプレビューが出て
/// 左へシュッと消える。閉じるまで何枚でも連続で撮影できる。
struct ContinuousCameraCaptureView: View {
    var onCapture: (Data) -> Void
    var onFailure: (String) -> Void = { _ in }
    var onFinish: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = ContinuousCameraController()
    @State private var previewThumbnails: [CapturedThumbnail] = []
    @State private var capturedCount = 0

    struct CapturedThumbnail: Identifiable, Equatable {
        let id = UUID()
        let image: UIImage
        var isFlyingOut = false
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ContinuousCameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        finish()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("カメラを閉じる")

                    Spacer()

                    if capturedCount > 0 {
                        Text("\(capturedCount)枚")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.4), in: Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                ZStack(alignment: .bottomLeading) {
                    // 撮ったもののプレビュー（左下に出て、左画面外へシュッと抜ける）
                    ForEach(previewThumbnails) { thumbnail in
                        Image(uiImage: thumbnail.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 74, height: 74)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(.white.opacity(0.9), lineWidth: 2)
                            }
                            .offset(x: thumbnail.isFlyingOut ? -140 : 0)
                            .opacity(thumbnail.isFlyingOut ? 0 : 1)
                            .padding(.leading, 20)
                            .padding(.bottom, 6)
                    }

                    HStack {
                        Spacer()

                        Button(action: capture) {
                            ZStack {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 4)
                                    .frame(width: 76, height: 76)
                                Circle()
                                    .fill(.white)
                                    .frame(width: 62, height: 62)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(camera.isCapturing)
                        .opacity(camera.isCapturing ? 0.6 : 1)
                        .accessibilityLabel("撮影する")

                        Spacer()
                    }
                }
                .padding(.bottom, 14)

                Button {
                    finish()
                } label: {
                    Text(capturedCount > 0 ? "撮影を終える（\(capturedCount)枚）" : "撮影を終える")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            camera.start(onFailure: { message in
                onFailure(message)
                dismiss()
            })
        }
        .onDisappear {
            camera.stop()
        }
    }

    private func capture() {
        MegrumHaptics.buttonTap()
        camera.capturePhoto { data, image in
            onCapture(data)
            capturedCount += 1
            showThumbnail(image)
        }
    }

    private func showThumbnail(_ image: UIImage) {
        let thumbnail = CapturedThumbnail(image: image)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            previewThumbnails.append(thumbnail)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.32)) {
                if let index = previewThumbnails.firstIndex(where: { $0.id == thumbnail.id }) {
                    previewThumbnails[index].isFlyingOut = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                previewThumbnails.removeAll { $0.id == thumbnail.id }
            }
        }
    }

    private func finish() {
        onFinish()
        dismiss()
    }
}

/// AVCaptureSession のプレビュー表示。
private struct ContinuousCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context _: Context) -> PreviewHostView {
        let view = PreviewHostView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_: PreviewHostView, context _: Context) {}

    final class PreviewHostView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

/// セッションと撮影を管理するコントローラ。
@MainActor
final class ContinuousCameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var isCapturing = false

    private let output = AVCapturePhotoOutput()
    private var isConfigured = false
    private var captureCompletion: ((Data, UIImage) -> Void)?

    func start(onFailure: @escaping @MainActor (String) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun(onFailure: onFailure)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        self.configureAndRun(onFailure: onFailure)
                    } else {
                        onFailure("カメラへのアクセスが許可されていません")
                    }
                }
            }
        default:
            onFailure("設定アプリからカメラへのアクセスを許可してください")
        }
    }

    private static let sessionQueue = DispatchQueue(label: "megrum.continuous-camera.session")

    func stop() {
        let session = session
        Self.sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func capturePhoto(completion: @escaping (Data, UIImage) -> Void) {
        guard !isCapturing else {
            return
        }
        isCapturing = true
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    private func configureAndRun(onFailure: @escaping @MainActor (String) -> Void) {
        if !isConfigured {
            session.beginConfiguration()
            session.sessionPreset = .photo
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input),
                session.canAddOutput(output)
            else {
                session.commitConfiguration()
                onFailure("この端末ではカメラを利用できません")
                return
            }
            session.addInput(input)
            session.addOutput(output)
            session.commitConfiguration()
            isConfigured = true
        }
        let session = session
        Self.sessionQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }
}

extension ContinuousCameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in
            defer {
                isCapturing = false
                captureCompletion = nil
            }
            guard error == nil, let data, let image = UIImage(data: data) else {
                return
            }
            captureCompletion?(data, image)
        }
    }
}
#endif
