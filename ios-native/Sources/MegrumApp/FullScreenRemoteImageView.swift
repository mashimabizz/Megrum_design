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
    @State private var isVisible = false
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dismissDragOffset: CGFloat = 0

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
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)

            topControls
        }
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isVisible = true
            }
        }
    }

    private var backgroundOpacity: Double {
        guard isVisible else {
            return 0
        }
        let dragProgress = Double(min(dismissDragOffset, 220) / 320)
        return max(0.22, 0.58 - dragProgress * 0.28)
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
        .opacity(isVisible ? 1 : 0)
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
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height + dismissDragOffset)
            .gesture(zoomGesture.simultaneously(with: imageDragGesture))
            .onTapGesture(count: 2) {
                resetZoom()
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 4)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1.02 {
                    resetZoom()
                }
            }
    }

    private var imageDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                } else if value.translation.height > 0,
                          abs(value.translation.height) > abs(value.translation.width) {
                    dismissDragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if scale > 1 {
                    lastOffset = offset
                } else if dismissDragOffset > 96 || value.predictedEndTranslation.height > 160 {
                    dismissImage()
                } else {
                    withAnimation(.snappy(duration: 0.22)) {
                        dismissDragOffset = 0
                    }
                }
            }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
        dismissDragOffset = 0
    }

    private func dismissImage() {
        withAnimation(.easeOut(duration: 0.16)) {
            isVisible = false
            dismissDragOffset = 0
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
