import SwiftUI

public enum MegrumTheme {
    public static let lavender = Color(red: 0.651, green: 0.584, blue: 0.847)
    public static let sky = Color(red: 0.659, green: 0.831, blue: 0.902)
    public static let pink = Color(red: 0.953, green: 0.773, blue: 0.831)
    public static let ink = Color(red: 0.212, green: 0.188, blue: 0.286)
    public static let muted = Color(red: 0.584, green: 0.557, blue: 0.643)
    public static let ok = Color(red: 0.286, green: 0.690, blue: 0.443)
    public static let canvas = Color(red: 0.984, green: 0.976, blue: 0.988)
}

public struct LiquidGlassSearchButton: View {
    private let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @GestureState private var pressLocation: CGPoint?
    @State private var isPressed = false

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        let gesture = DragGesture(minimumDistance: 0)
            .updating($pressLocation) { value, state, _ in
                state = value.location
            }
            .onChanged { _ in
                if !isPressed {
                    withAnimation(.easeOut(duration: reduceMotion ? 0.01 : 0.1)) {
                        isPressed = true
                    }
                }
            }
            .onEnded { value in
                let isTap = abs(value.translation.width) < 12 && abs(value.translation.height) < 12
                withAnimation(.spring(response: reduceMotion ? 0.01 : 0.32, dampingFraction: 0.84)) {
                    isPressed = false
                }
                if isTap {
                    action()
                }
            }

        ZStack {
            Circle()
                .fill(reduceTransparency ? Color.white.opacity(0.94) : Color.white.opacity(0.26))
                .background(materialLayer)
                .overlay(innerHighlight)
                .overlay(specularHighlight)
                .shadow(color: .black.opacity(isPressed ? 0.12 : 0.18), radius: isPressed ? 14 : 22, y: isPressed ? 8 : 16)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 3, y: 1)
                .accessibilityHidden(true)
        }
        .frame(width: 72, height: 72)
        .scaleEffect(isPressed ? 0.975 : 1)
        .offset(x: dragOffset.width, y: dragOffset.height)
        .contentShape(Circle())
        .gesture(gesture)
        .accessibilityLabel("検索")
        .accessibilityAddTraits(.isButton)
    }

    private var materialLayer: some View {
        Circle()
            .fill(reduceTransparency ? AnyShapeStyle(Color.white.opacity(0.95)) : AnyShapeStyle(.ultraThinMaterial))
    }

    private var innerHighlight: some View {
        Circle()
            .strokeBorder(Color.white.opacity(isPressed ? 0.76 : 0.54), lineWidth: 1)
            .padding(1)
    }

    private var specularHighlight: some View {
        GeometryReader { proxy in
            let point = pressLocation ?? CGPoint(x: proxy.size.width * 0.32, y: proxy.size.height * 0.24)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isPressed ? 0.64 : 0.46),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0)
                        ],
                        center: UnitPoint(x: point.x / max(proxy.size.width, 1), y: point.y / max(proxy.size.height, 1)),
                        startRadius: 1,
                        endRadius: isPressed ? 54 : 42
                    )
                )
        }
        .clipShape(Circle())
    }

    private var dragOffset: CGSize {
        guard let point = pressLocation, !reduceMotion else {
            return .zero
        }
        return CGSize(width: (point.x - 36) * 0.055, height: (point.y - 36) * 0.055)
    }
}
