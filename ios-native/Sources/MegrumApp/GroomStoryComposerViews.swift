import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GroomStoryComposerScreen: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedCreationCoordinate: MegrumLocationCoordinate?
    @Binding var draftPhotoData: Data?
    @Binding var draftPhotoContentType: String
    var isPreparingPhoto: Bool
    var isCreating: Bool
    var canUseCamera: Bool
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var onRequestLocation: () -> Void
    var onOpenCamera: () -> Void
    var onPublish: (Data, String, String?, MegrumLocationCoordinate) async -> Bool
    var onDiscard: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var captionText = ""
    @State private var toastMessage: String?
    @State private var toastID = UUID()

    private var hasPhotoDraft: Bool {
        draftPhotoData != nil
    }

    private var canCreateAtSelectedLocation: Bool {
        MeguriAccessPolicy.canCreateAt(
            selectedCreationCoordinate,
            currentCoordinate: currentCoordinate
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button("閉じる", systemImage: "xmark", action: closeComposer)
                        .labelStyle(.iconOnly)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                    .buttonStyle(.plain)

                    Spacer()

                    Text(hasPhotoDraft ? "投稿前の確認" : "グルームに追加")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)

                ScrollView {
                    if let draftPhotoData {
                        finalLocationStep(photoData: draftPhotoData)
                    } else {
                        photoSelectionStep
                    }
                }

                Spacer()

                Text("投稿したグルームは近くの人にだけ表示されます。正確な位置は表示しません。")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
                    .padding(.bottom, 24)
            }

            if let toastMessage {
                VStack {
                    Spacer()
                    MeguriToastView(message: toastMessage)
                        .padding(.bottom, 92)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear(perform: seedSelectedCoordinateForFinalStepIfNeeded)
        .onChange(of: currentCoordinate) { _, _ in
            seedSelectedCoordinateForFinalStepIfNeeded()
        }
    }

    private var photoSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("先に写真を決める")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("撮影・選択した写真を確認してから、最後に地図上の表示位置を決めます。")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button(action: openCameraIfPossible) {
                    GroomComposerActionTile(
                        title: "カメラで撮る",
                        subtitle: cameraSubtitle,
                        systemImage: "camera.fill",
                        isLoading: isPreparingPhoto
                    )
                }
                .buttonStyle(.plain)
                .disabled(isPreparingPhoto || isCreating)
                .opacity(canUseCamera ? 1 : 0.48)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    GroomComposerActionTile(
                        title: "写真を選ぶ",
                        subtitle: "写真が決まったら場所選択へ",
                        systemImage: "photo.on.rectangle.angled",
                        isLoading: isPreparingPhoto
                    )
                }
                .buttonStyle(.plain)
                .disabled(isPreparingPhoto || isCreating)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private func finalLocationStep(photoData: Data) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("最後に置く場所を決める")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("この写真が地図上に表示される見え方を確認しながら、半径1km以内にピンを立ててください。")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }

            GroomDraftPhotoPreview(photoData: photoData, caption: captionText.nilIfBlank)

            TextField("写真に添えるひとこと", text: $captionText, axis: .vertical)
                .lineLimit(1...3)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .padding(14)
                .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(MegrumTheme.ink)

            MeguriCreationLocationPicker(
                title: "地図での表示プレビュー",
                subtitle: "現在地から半径1km以内の地図上をタップして選択",
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                preview: .groom(imageData: photoData, caption: captionText.nilIfBlank),
                selectedCoordinate: $selectedCreationCoordinate,
                onRequestLocation: onRequestLocation,
                onOutOfRange: showToast
            )
            .padding(14)
            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            Button(action: publishDraftPhoto) {
                Group {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("この場所に投稿する")
                    }
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!canCreateAtSelectedLocation || isCreating)
            .opacity(canCreateAtSelectedLocation && !isCreating ? 1 : 0.48)

            Button("写真を選び直す", systemImage: "arrow.counterclockwise", action: resetPhotoDraft)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear(perform: seedSelectedCoordinateForFinalStepIfNeeded)
    }

    private var cameraSubtitle: String {
        if !canUseCamera {
            return "この端末では利用不可"
        }
        return "写真が決まったら場所選択へ"
    }

    private func openCameraIfPossible() {
        guard canUseCamera else {
            showToast("この端末ではカメラを利用できません。写真から選択してください。")
            return
        }
        onOpenCamera()
    }

    private func publishDraftPhoto() {
        guard let draftPhotoData else {
            showToast("投稿する写真を選択してください")
            return
        }
        guard let selectedCreationCoordinate else {
            if currentCoordinate == nil {
                onRequestLocation()
            }
            showToast("最後に地図上でピンを立ててください")
            return
        }
        if currentCoordinate == nil {
            onRequestLocation()
        }
        guard canCreateAtSelectedLocation else {
            showToast(
                MeguriAccessPolicy.creationLocationMessage(
                    selectedCoordinate: selectedCreationCoordinate,
                    currentCoordinate: currentCoordinate
                )
            )
            return
        }
        Task {
            let published = await onPublish(
                draftPhotoData,
                draftPhotoContentType,
                captionText.nilIfBlank,
                selectedCreationCoordinate
            )
            guard published else {
                return
            }
            onDiscard()
            dismiss()
        }
    }

    private func seedSelectedCoordinateForFinalStepIfNeeded() {
        guard hasPhotoDraft else {
            return
        }
        guard selectedCreationCoordinate == nil else {
            return
        }
        selectedCreationCoordinate = currentCoordinate
    }

    private func resetPhotoDraft() {
        draftPhotoData = nil
        draftPhotoContentType = "image/jpeg"
        selectedPhotoItem = nil
        selectedCreationCoordinate = nil
        captionText = ""
    }

    private func closeComposer() {
        onDiscard()
        dismiss()
    }

    private func showToast(_ message: String) {
        let toastID = UUID()
        self.toastID = toastID
        withAnimation(.smooth(duration: 0.18)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard self.toastID == toastID else {
                return
            }
            withAnimation(.smooth(duration: 0.18)) {
                toastMessage = nil
            }
        }
    }
}

private struct GroomDraftPhotoPreview: View {
    var photoData: Data
    var caption: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            #if canImport(UIKit)
            if let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                photoFallback
            }
            #else
            photoFallback
            #endif

            if let caption {
                Text(caption)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.36), in: Capsule())
                    .padding(14)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var photoFallback: some View {
        Rectangle()
            .fill(MegrumTheme.lavender.opacity(0.20))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

private struct GroomComposerActionTile: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    }

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 128)

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)
        }
    }
}
