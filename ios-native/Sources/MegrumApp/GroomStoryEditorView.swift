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
    @State private var draftTextScale: CGFloat = 1
    @State private var draftRotationDegrees: Double = 0
    @State private var selectedTextColor: GroomStoryTextColor = .white
    @State private var editingOverlayID: UUID?
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
                    editingOverlayID: editingOverlayID,
                    draggingOverlayID: $draggingOverlayID,
                    isHoveringDeleteTarget: $isHoveringDeleteTarget,
                    onDelete: deleteOverlay,
                    onEdit: beginEditingTextOverlay,
                    onTapCanvas: { location, size in
                        beginTextInput(at: location, in: size)
                    }
                )
                .frame(width: canvasFrame.width, height: canvasFrame.height)
                .position(x: canvasFrame.midX, y: canvasFrame.midY)

                if isTextInputPresented {
                    GroomStoryTextInputLayer(
                        canvasFrame: canvasFrame,
                        safeAreaInsets: proxy.safeAreaInsets,
                        text: $draftText,
                        selectedColor: selectedTextColor,
                        textScale: $draftTextScale,
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
                            y: proxy.size.height - proxy.safeAreaInsets.bottom - 32
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !isTextInputPresented {
                    GroomStoryEditorTopChrome(
                        safeAreaInsets: proxy.safeAreaInsets,
                        onClose: onClose
                    )
                    .transition(.opacity)

                    GroomStoryPublishControl(
                        isCreating: isCreating,
                        onPublish: onPublish
                    )
                    .position(
                        x: proxy.size.width - proxy.safeAreaInsets.trailing - 38,
                        y: proxy.size.height - proxy.safeAreaInsets.bottom - 46
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.18), value: isTextInputPresented)
            .animation(.smooth(duration: 0.18), value: draggingOverlayID)
        }
        .safeAreaInset(edge: .bottom) {
            if isTextInputPresented {
                GroomStoryTextColorToolbar(selectedColor: $selectedTextColor)
                .padding(.horizontal, 22)
                .padding(.bottom, 8)
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
            x: 0.50,
            y: min(max(location.y / max(canvasSize.height, 1), 0.12), 0.84)
        )
        draftTextScale = 1
        draftRotationDegrees = 0
        editingOverlayID = nil
        withAnimation(.smooth(duration: 0.16)) {
            isTextInputPresented = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            isTextFieldFocused = true
        }
    }

    private func beginEditingTextOverlay(_ overlay: GroomStoryTextOverlay) {
        guard !isCreating else {
            return
        }
        draftText = overlay.text
        draftTextPosition = overlay.normalizedPosition
        draftTextScale = overlay.scale
        draftRotationDegrees = overlay.rotationDegrees
        selectedTextColor = overlay.color
        editingOverlayID = overlay.id
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
        let editedOverlayID = editingOverlayID
        withAnimation(.smooth(duration: 0.16)) {
            isTextFieldFocused = false
            isTextInputPresented = false
            editingOverlayID = nil
        }
        guard !trimmedText.isEmpty else {
            return
        }
        if let editedOverlayID,
           let index = textOverlays.firstIndex(where: { $0.id == editedOverlayID }) {
            textOverlays[index].text = trimmedText
            textOverlays[index].normalizedPosition = draftTextPosition.groomStoryClamped
            textOverlays[index].color = selectedTextColor
            textOverlays[index].scale = min(max(draftTextScale, 0.55), 2.6)
            textOverlays[index].rotationDegrees = draftRotationDegrees
            return
        }
        textOverlays.append(
            GroomStoryTextOverlay(
                text: trimmedText,
                normalizedPosition: draftTextPosition,
                color: selectedTextColor,
                scale: draftTextScale,
                rotationDegrees: draftRotationDegrees
            )
        )
    }

    private func deleteOverlay(_ id: UUID) {
        withAnimation(.smooth(duration: 0.18)) {
            textOverlays.removeAll { $0.id == id }
            if editingOverlayID == id {
                editingOverlayID = nil
            }
        }
    }
}

private enum GroomStoryEditorLayout {
    static func canvasFrame(in size: CGSize, safeAreaInsets: EdgeInsets) -> CGRect {
        CGRect(origin: .zero, size: size)
    }
}

private struct GroomStoryEditableCanvas: View {
    var photoData: Data
    @Binding var textOverlays: [GroomStoryTextOverlay]
    var editingOverlayID: UUID?
    @Binding var draggingOverlayID: UUID?
    @Binding var isHoveringDeleteTarget: Bool
    var onDelete: (UUID) -> Void
    var onEdit: (GroomStoryTextOverlay) -> Void
    var onTapCanvas: (CGPoint, CGSize) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                GroomStoryPhotoCanvas(photoData: photoData)

                ForEach($textOverlays) { $overlay in
                    if overlay.id != editingOverlayID {
                        GroomStoryEditableTextOverlay(
                            overlay: $overlay,
                            canvasSize: proxy.size,
                            draggingOverlayID: $draggingOverlayID,
                            isHoveringDeleteTarget: $isHoveringDeleteTarget,
                            onDelete: onDelete,
                            onEdit: onEdit
                        )
                    }
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
    var onEdit: (GroomStoryTextOverlay) -> Void

    @State private var dragStartPosition: CGPoint?
    @State private var scaleStart: CGFloat = 1
    @State private var rotationStartDegrees: Double = 0
    @State private var isMagnifying = false
    @State private var isRotating = false
    @State private var hasExceededDragThreshold = false

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
        .simultaneousGesture(rotationGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(GroomStoryCanvasCoordinateSpace.name))
            .onChanged { value in
                if dragStartPosition == nil {
                    dragStartPosition = overlay.normalizedPosition
                    hasExceededDragThreshold = false
                }
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance > 6 || hasExceededDragThreshold else {
                    return
                }
                hasExceededDragThreshold = true
                draggingOverlayID = overlay.id
                let basePosition = dragStartPosition ?? overlay.normalizedPosition
                overlay.normalizedPosition = CGPoint(
                    x: basePosition.x + value.translation.width / max(canvasSize.width, 1),
                    y: basePosition.y + value.translation.height / max(canvasSize.height, 1)
                )
                .groomStoryClamped
                isHoveringDeleteTarget = overlay.normalizedPosition.y > 0.84
            }
            .onEnded { _ in
                let shouldEdit = !hasExceededDragThreshold
                let shouldDelete = overlay.normalizedPosition.y > 0.84
                dragStartPosition = nil
                draggingOverlayID = nil
                isHoveringDeleteTarget = false
                hasExceededDragThreshold = false
                if shouldDelete {
                    onDelete(overlay.id)
                } else if shouldEdit {
                    onEdit(overlay)
                }
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if !isMagnifying {
                    scaleStart = overlay.scale
                    isMagnifying = true
                }
                overlay.scale = min(max(scaleStart * value, 0.55), 2.6)
            }
            .onEnded { _ in
                scaleStart = overlay.scale
                isMagnifying = false
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                if !isRotating {
                    rotationStartDegrees = overlay.rotationDegrees
                    isRotating = true
                }
                overlay.rotationDegrees = rotationStartDegrees + value.degrees
            }
            .onEnded { _ in
                rotationStartDegrees = overlay.rotationDegrees
                isRotating = false
            }
    }
}

private struct GroomStoryTextInputLayer: View {
    var canvasFrame: CGRect
    var safeAreaInsets: EdgeInsets
    @Binding var text: String
    var selectedColor: GroomStoryTextColor
    @Binding var textScale: CGFloat
    var position: CGPoint
    var isFocused: FocusState<Bool>.Binding
    var onCommit: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            inputField

            GroomStoryVerticalTextSizeControl(textScale: $textScale)
                .frame(width: 46, height: 196)
                .position(
                    x: canvasFrame.minX + safeAreaInsets.leading + 34,
                    y: canvasFrame.midY
                )

            Button("完了", action: onCommit)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .contentShape(Capsule())
                .padding(.top, safeAreaInsets.top + 12)
                .padding(.trailing, 22)
        }
    }

    private var inputField: some View {
        TextField("", text: $text, axis: .vertical)
            .font(.system(size: inputFontSize, weight: .regular, design: .rounded))
            .foregroundStyle(selectedColor.color)
            .shadow(color: selectedColor.shadowColor, radius: 4, x: 0, y: 2)
            .multilineTextAlignment(.center)
            .lineLimit(1...7)
            .focused(isFocused)
            .onSubmit(onCommit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: inputFieldWidth, alignment: .center)
            .position(inputFieldPosition)
    }

    private var inputFieldWidth: CGFloat {
        min(360, max(190, canvasFrame.width - 58))
    }

    private var inputFieldPosition: CGPoint {
        CGPoint(
            x: canvasFrame.midX,
            y: canvasFrame.minY + position.y * canvasFrame.height
        )
    }

    private var inputFontSize: CGFloat {
        min(max(46 * textScale, 30), 104)
    }
}

private struct GroomStoryEditorTopChrome: View {
    var safeAreaInsets: EdgeInsets
    var onClose: () -> Void

    var body: some View {
        ZStack {
            GroomStoryCircleButton(
                systemImage: "xmark",
                accessibilityLabel: "閉じる",
                action: onClose
            )
            .position(x: safeAreaInsets.leading + 28, y: topButtonY)
        }
    }

    private var topButtonY: CGFloat {
        safeAreaInsets.top + 16
    }
}

private struct GroomStoryCircleButton: View {
    var systemImage: String
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct GroomStoryVerticalTextSizeControl: View {
    @Binding var textScale: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let height = max(proxy.size.height, 1)
            let normalized = normalizedTextScale
            let knobY = height * (1 - normalized)

            ZStack {
                GroomStoryTextSizeTrackShape()
                    .fill(.white.opacity(0.34))
                    .overlay {
                        GroomStoryTextSizeTrackShape()
                            .stroke(.white.opacity(0.58), lineWidth: 1)
                    }

                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 3)
                    .position(x: proxy.size.width / 2, y: min(max(knobY, 9), height - 9))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateScale(from: value.location.y, height: height)
                    }
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("文字サイズ")
        .accessibilityValue("\(Int(textScale * 100))パーセント")
    }

    private var normalizedTextScale: CGFloat {
        (min(max(textScale, 0.65), 2.20) - 0.65) / (2.20 - 0.65)
    }

    private func updateScale(from y: CGFloat, height: CGFloat) {
        let clampedY = min(max(y, 0), height)
        let normalized = 1 - clampedY / max(height, 1)
        textScale = 0.65 + normalized * (2.20 - 0.65)
    }
}

private struct GroomStoryTextSizeTrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.minY + 2))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 4, y: rect.minY + 2),
            control: CGPoint(x: rect.midX, y: rect.minY - 4)
        )
        path.closeSubpath()
        return path
    }
}

private struct GroomStoryDeleteTarget: View {
    var isActive: Bool

    var body: some View {
        Image(systemName: "trash")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(isActive ? MegrumTheme.conditionExact : .black.opacity(0.28), in: Circle())
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: 1.6)
            }
    }
}

private enum GroomStoryCanvasCoordinateSpace {
    static let name = "groom-story-canvas"
}
