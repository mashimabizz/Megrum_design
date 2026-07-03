import Foundation
import SwiftUI

struct RemoteImageSelection: Identifiable, Equatable {
    var url: URL
    var evidencePhotoID: UUID?
    var canDeleteEvidencePhoto = false

    var id: String {
        [
            url.absoluteString,
            evidencePhotoID?.uuidString ?? "image"
        ].joined(separator: "#")
    }
}

struct FullScreenRemoteImageView: View {
    var url: URL
    var onDismiss: (() -> Void)?
    var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var presentationState = FullScreenRemoteImagePresentationState()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture(perform: dismissImage)

            Group {
                if url.isFileURL {
                    interactiveImage {
                        LocalURLImage(url: url, contentMode: .fit) {
                            failureContent
                        }
                    }
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            interactiveImage {
                                image
                                    .resizable()
                                    .scaledToFit()
                            }
                        case .failure:
                            failureContent
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .scaleEffect(presentationState.imagePresentationScale)
            .opacity(presentationState.contentOpacity)

            topControls
        }
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                presentationState.show()
            }
        }
    }

    private var backgroundOpacity: Double {
        presentationState.backgroundOpacity
    }

    private var topControls: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    dismissImage()
                } label: {
                    Label("閉じる", systemImage: "xmark")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .frame(height: 38)
                        .background(.white.opacity(0.16), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("閉じる")

                Spacer()

                if let onDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("削除する", systemImage: "trash")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(.red.opacity(0.8), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("削除する")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(.black.opacity(0.24))

            Spacer(minLength: 0)
        }
        .opacity(presentationState.contentOpacity)
    }

    private var failureContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 34, weight: .bold))
            Text("画像を読み込めませんでした")
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.86))
    }

    private func interactiveImage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(presentationState.scale)
            .offset(x: presentationState.imageOffset.width, y: presentationState.imageOffset.height)
            .gesture(zoomGesture.simultaneously(with: imageDragGesture))
            .onTapGesture(count: 2) {
                presentationState.resetZoom()
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                presentationState.updateMagnification(value)
            }
            .onEnded { _ in
                presentationState.endMagnification()
            }
    }

    private var imageDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                presentationState.updateDrag(translation: value.translation)
            }
            .onEnded { value in
                if presentationState.isZoomed {
                    presentationState.finishZoomedDrag()
                } else if presentationState.shouldDismissAfterDrag(predictedEndTranslation: value.predictedEndTranslation) {
                    dismissImage()
                } else {
                    withAnimation(.snappy(duration: 0.22)) {
                        presentationState.resetDismissDragOffset()
                    }
                }
            }
    }

    private func dismissImage() {
        withAnimation(.easeOut(duration: 0.16)) {
            presentationState.prepareDismissal()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            if let onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        }
    }
}
