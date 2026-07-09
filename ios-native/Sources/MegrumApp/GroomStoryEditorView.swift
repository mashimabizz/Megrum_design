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
            // キーボード表示時に背景グルームが押し上げられて移動/縮小しないようにする。
            .ignoresSafeArea(.keyboard, edges: .bottom)
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

    var body: some View {
        GroomStoryOverlayText(
            overlay: overlay,
            canvasSize: canvasSize
        )
        .modifier(
            GroomStoryTextManipulationModifier(
                canvasSize: canvasSize,
                overlay: $overlay,
                draggingOverlayID: $draggingOverlayID,
                isHoveringDeleteTarget: $isHoveringDeleteTarget,
                onDelete: onDelete,
                onEdit: onEdit
            )
        )
        .position(
            x: overlay.normalizedPosition.x * canvasSize.width,
            y: overlay.normalizedPosition.y * canvasSize.height
        )
        .scaleEffect(draggingOverlayID == overlay.id ? 1.04 : 1)
    }
}

/// 文字オーバーレイの移動/拡大縮小/回転を担う。iOSではUIKitのジェスチャ認識器を同時認識で束ね、
/// インスタのストーリー編集と同じく「1本目で移動 → 途中で2本目を置くとそのままピンチ/回転もできる」
/// 操作感にする。UIKitが無い環境（テストホスト等）では操作なしのフォールバック。
private struct GroomStoryTextManipulationModifier: ViewModifier {
    var canvasSize: CGSize
    @Binding var overlay: GroomStoryTextOverlay
    @Binding var draggingOverlayID: UUID?
    @Binding var isHoveringDeleteTarget: Bool
    var onDelete: (UUID) -> Void
    var onEdit: (GroomStoryTextOverlay) -> Void

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content.overlay {
            GroomStoryTextGestureSurface(
                canvasSize: canvasSize,
                overlay: $overlay,
                draggingOverlayID: $draggingOverlayID,
                isHoveringDeleteTarget: $isHoveringDeleteTarget,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
        #else
        content
        #endif
    }
}

#if canImport(UIKit)
private struct GroomStoryTextGestureSurface: UIViewRepresentable {
    var canvasSize: CGSize
    @Binding var overlay: GroomStoryTextOverlay
    @Binding var draggingOverlayID: UUID?
    @Binding var isHoveringDeleteTarget: Bool
    var onDelete: (UUID) -> Void
    var onEdit: (GroomStoryTextOverlay) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.maximumNumberOfTouches = 2
        pan.delegate = context.coordinator

        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinch.delegate = context.coordinator

        let rotation = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotation(_:))
        )
        rotation.delegate = context.coordinator

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator

        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(rotation)
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: GroomStoryTextGestureSurface
        private var activeManipulations = 0
        private var lastPanTouchCount = 0

        init(_ parent: GroomStoryTextGestureSurface) {
            self.parent = parent
        }

        func gestureRecognizer(
            _ gesture: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            // 移動・拡大縮小・回転は同時に効かせる。タップ（＝編集を開く）だけは他と同時にしない。
            if gesture is UITapGestureRecognizer || other is UITapGestureRecognizer {
                return false
            }
            return true
        }

        private func beginManipulation() {
            if activeManipulations == 0 {
                parent.draggingOverlayID = parent.overlay.id
            }
            activeManipulations += 1
        }

        private func endManipulation() {
            activeManipulations = max(0, activeManipulations - 1)
            if activeManipulations == 0 {
                parent.draggingOverlayID = nil
                parent.isHoveringDeleteTarget = false
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let host = gesture.view else { return }
            // 端末回転で座標系が傾かないよう、常にwindow基準の移動量を使う。
            let reference = host.window ?? host
            switch gesture.state {
            case .began:
                beginManipulation()
                lastPanTouchCount = gesture.numberOfTouches
                gesture.setTranslation(.zero, in: reference)
            case .changed:
                if gesture.numberOfTouches != lastPanTouchCount {
                    // 指を足す/離すと重心が飛ぶので、その1フレームは移動を無視して基準を取り直す。
                    lastPanTouchCount = gesture.numberOfTouches
                    gesture.setTranslation(.zero, in: reference)
                    return
                }
                let translation = gesture.translation(in: reference)
                gesture.setTranslation(.zero, in: reference)
                let width = max(parent.canvasSize.width, 1)
                let height = max(parent.canvasSize.height, 1)
                var position = parent.overlay.normalizedPosition
                position.x += translation.x / width
                position.y += translation.y / height
                parent.overlay.normalizedPosition = position.groomStoryClamped
                parent.isHoveringDeleteTarget = parent.overlay.normalizedPosition.y > 0.84
            case .ended, .cancelled, .failed:
                let shouldDelete = parent.overlay.normalizedPosition.y > 0.84
                let overlayID = parent.overlay.id
                endManipulation()
                lastPanTouchCount = 0
                if shouldDelete {
                    parent.onDelete(overlayID)
                }
            default:
                break
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                beginManipulation()
            case .changed:
                let next = parent.overlay.scale * gesture.scale
                gesture.scale = 1
                parent.overlay.scale = min(max(next, 0.55), 2.6)
            case .ended, .cancelled, .failed:
                endManipulation()
            default:
                break
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            switch gesture.state {
            case .began:
                beginManipulation()
            case .changed:
                parent.overlay.rotationDegrees += Double(gesture.rotation) * 180 / .pi
                gesture.rotation = 0
            case .ended, .cancelled, .failed:
                endManipulation()
            default:
                break
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            parent.onEdit(parent.overlay)
        }
    }
}
#endif

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
            // 文字以外をタップしたら（キーボードを下げるだけでなく）「完了」と同じく確定する。
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCommit)

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
