import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GroomStoryEditorView: View {
    var photoData: Data
    @Binding var textOverlays: [GroomStoryTextOverlay]
    var isCreating: Bool
    var onClose: () -> Void
    var onPublish: () -> Void

    @FocusState private var isTextFieldFocused: Bool
    @State private var isTextInputPresented = false
    @State private var draftText = ""
    @State private var draftTextPosition = CGPoint(x: 0.50, y: 0.45)
    @State private var selectedTextColor: GroomStoryTextColor = .white
    @State private var draggingOverlayID: UUID?
    @State private var isHoveringDeleteTarget = false

    var body: some View {
        GeometryReader { proxy in
            let canvasFrame = GroomStoryEditorLayout.canvasFrame(
                in: proxy.size,
                safeAreaInsets: proxy.safeAreaInsets
            )

            ZStack {
                Color.black.ignoresSafeArea()

                GroomStoryEditableCanvas(
                    photoData: photoData,
                    textOverlays: $textOverlays,
                    draggingOverlayID: $draggingOverlayID,
                    isHoveringDeleteTarget: $isHoveringDeleteTarget,
                    onDelete: deleteOverlay,
                    onTapCanvas: { location, size in
                        beginTextInput(at: location, in: size)
                    }
                )
                .frame(width: canvasFrame.width, height: canvasFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .position(x: canvasFrame.midX, y: canvasFrame.midY)

                if isTextInputPresented {
                    GroomStoryTextInputLayer(
                        canvasFrame: canvasFrame,
                        text: $draftText,
                        selectedColor: selectedTextColor,
                        position: draftTextPosition,
                        isFocused: $isTextFieldFocused,
                        onCommit: commitDraftText
                    )
                    .transition(.opacity)
                }

                if draggingOverlayID != nil {
                    GroomStoryDeleteTarget(isActive: isHoveringDeleteTarget)
                        .position(
                            x: canvasFrame.midX,
                            y: canvasFrame.maxY - 78
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !isTextInputPresented {
                    GroomStoryEditorTopChrome(
                        canvasFrame: canvasFrame,
                        onClose: onClose,
                        onAddText: {
                            beginTextInput(
                                at: CGPoint(x: canvasFrame.width * 0.50, y: canvasFrame.height * 0.42),
                                in: canvasFrame.size
                            )
                        }
                    )
                    .transition(.opacity)

                    GroomStoryPublishControl(
                        isCreating: isCreating,
                        onPublish: onPublish
                    )
                    .position(
                        x: proxy.size.width - 52,
                        y: proxy.size.height - proxy.safeAreaInsets.bottom - 40
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.18), value: isTextInputPresented)
            .animation(.smooth(duration: 0.18), value: draggingOverlayID)
        }
        .safeAreaInset(edge: .bottom) {
            if isTextInputPresented {
                GroomStoryTextColorToolbar(
                    selectedColor: $selectedTextColor
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func beginTextInput(at location: CGPoint, in canvasSize: CGSize) {
        guard !isCreating else {
            return
        }
        draftText = ""
        draftTextPosition = CGPoint(
            x: min(max(location.x / max(canvasSize.width, 1), 0.12), 0.88),
            y: min(max(location.y / max(canvasSize.height, 1), 0.12), 0.84)
        )
        withAnimation(.smooth(duration: 0.16)) {
            isTextInputPresented = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            isTextFieldFocused = true
        }
    }

    private func commitDraftText() {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.smooth(duration: 0.16)) {
            isTextFieldFocused = false
            isTextInputPresented = false
        }
        guard !trimmedText.isEmpty else {
            return
        }
        textOverlays.append(
            GroomStoryTextOverlay(
                text: trimmedText,
                normalizedPosition: draftTextPosition,
                color: selectedTextColor
            )
        )
    }

    private func deleteOverlay(_ id: UUID) {
        withAnimation(.smooth(duration: 0.18)) {
            textOverlays.removeAll { $0.id == id }
        }
    }
}

private enum GroomStoryEditorLayout {
    static func canvasFrame(in size: CGSize, safeAreaInsets: EdgeInsets) -> CGRect {
        let top = safeAreaInsets.top + 52
        let bottom = safeAreaInsets.bottom + 96
        let height = max(420, size.height - top - bottom)
        return CGRect(x: 0, y: top, width: size.width, height: height)
    }
}

private struct GroomStoryEditableCanvas: View {
    var photoData: Data
    @Binding var textOverlays: [GroomStoryTextOverlay]
    @Binding var draggingOverlayID: UUID?
    @Binding var isHoveringDeleteTarget: Bool
    var onDelete: (UUID) -> Void
    var onTapCanvas: (CGPoint, CGSize) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                GroomStoryPhotoCanvas(photoData: photoData)

                ForEach($textOverlays) { $overlay in
                    GroomStoryEditableTextOverlay(
                        overlay: $overlay,
                        canvasSize: proxy.size,
                        draggingOverlayID: $draggingOverlayID,
                        isHoveringDeleteTarget: $isHoveringDeleteTarget,
                        onDelete: onDelete
                    )
                }
            }
            .coordinateSpace(name: GroomStoryCanvasCoordinateSpace.name)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        onTapCanvas(value.location, proxy.size)
                    }
            )
        }
    }
}

private struct GroomStoryEditableTextOverlay: View {
    @Binding var overlay: GroomStoryTextOverlay
    var canvasSize: CGSize
    @Binding var draggingOverlayID: UUID?
    @Binding var isHoveringDeleteTarget: Bool
    var onDelete: (UUID) -> Void

    @State private var dragStartPosition: CGPoint?
    @State private var scaleStart: CGFloat = 1

    var body: some View {
        GroomStoryOverlayText(
            overlay: overlay,
            canvasSize: canvasSize
        )
        .position(
            x: overlay.normalizedPosition.x * canvasSize.width,
            y: overlay.normalizedPosition.y * canvasSize.height
        )
        .scaleEffect(draggingOverlayID == overlay.id ? 1.04 : 1)
        .gesture(dragGesture)
        .simultaneousGesture(magnificationGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(GroomStoryCanvasCoordinateSpace.name))
            .onChanged { value in
                if dragStartPosition == nil {
                    dragStartPosition = overlay.normalizedPosition
                    draggingOverlayID = overlay.id
                }
                let basePosition = dragStartPosition ?? overlay.normalizedPosition
                overlay.normalizedPosition = CGPoint(
                    x: basePosition.x + value.translation.width / max(canvasSize.width, 1),
                    y: basePosition.y + value.translation.height / max(canvasSize.height, 1)
                )
                .groomStoryClamped
                isHoveringDeleteTarget = overlay.normalizedPosition.y > 0.78
            }
            .onEnded { _ in
                let shouldDelete = overlay.normalizedPosition.y > 0.78
                dragStartPosition = nil
                draggingOverlayID = nil
                isHoveringDeleteTarget = false
                if shouldDelete {
                    onDelete(overlay.id)
                }
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                overlay.scale = min(max(scaleStart * value, 0.55), 2.6)
            }
            .onEnded { _ in
                scaleStart = overlay.scale
            }
    }
}

private struct GroomStoryTextInputLayer: View {
    var canvasFrame: CGRect
    @Binding var text: String
    var selectedColor: GroomStoryTextColor
    var position: CGPoint
    var isFocused: FocusState<Bool>.Binding
    var onCommit: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            inputField

            Button("完了", action: onCommit)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .contentShape(Capsule())
                .padding(.top, canvasFrame.minY + 20)
                .padding(.trailing, 22)
        }
    }

    private var inputField: some View {
        TextField("", text: $text)
            .font(.system(size: 46, weight: .regular, design: .rounded))
            .foregroundStyle(selectedColor.color)
            .shadow(color: selectedColor.shadowColor, radius: 4, x: 0, y: 2)
            .focused(isFocused)
            .onSubmit(onCommit)
            .frame(width: inputFieldWidth, alignment: .leading)
            .position(inputFieldPosition)
    }

    private var inputFieldWidth: CGFloat {
        min(340, max(180, canvasFrame.width - 48))
    }

    private var inputFieldPosition: CGPoint {
        CGPoint(
            x: canvasFrame.minX + position.x * canvasFrame.width,
            y: canvasFrame.minY + position.y * canvasFrame.height
        )
    }
}

private struct GroomStoryEditorTopChrome: View {
    var canvasFrame: CGRect
    var onClose: () -> Void
    var onAddText: () -> Void

    var body: some View {
        ZStack {
            GroomStoryCircleButton(
                systemImage: "xmark",
                accessibilityLabel: "閉じる",
                action: onClose
            )
            .position(x: canvasFrame.minX + 46, y: canvasFrame.minY + 50)

            Button(action: onAddText) {
                Text("Aa")
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(.black.opacity(0.44), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("テキストを追加")
            .position(x: canvasFrame.maxX - 46, y: canvasFrame.minY + 50)
        }
    }
}

private struct GroomStoryCircleButton: View {
    var systemImage: String
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(.black.opacity(0.44), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct GroomStoryPublishControl: View {
    var isCreating: Bool
    var onPublish: () -> Void

    var body: some View {
        Button(action: onPublish) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.27, green: 0.36, blue: 1.00))

                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 64, height: 64)
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
        .accessibilityLabel("投稿する")
    }
}

private struct GroomStoryTextColorToolbar: View {
    @Binding var selectedColor: GroomStoryTextColor

    var body: some View {
        HStack(spacing: 14) {
            ForEach(GroomStoryTextColor.allCases) { color in
                Button {
                    selectedColor = color
                } label: {
                    Circle()
                        .fill(color.color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: selectedColor == color ? 3 : 1)
                        }
                        .overlay {
                            if color == .white {
                                Circle()
                                    .stroke(.black.opacity(0.22), lineWidth: 1)
                                    .padding(3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(color.accessibilityName)にする")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(.black.opacity(0.70), in: Capsule())
    }
}

private struct GroomStoryDeleteTarget: View {
    var isActive: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("ドラッグして削除")
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Image(systemName: "trash")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .background(isActive ? MegrumTheme.conditionExact : .black.opacity(0.22), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
        }
    }
}

private enum GroomStoryCanvasCoordinateSpace {
    static let name = "groom-story-canvas"
}
