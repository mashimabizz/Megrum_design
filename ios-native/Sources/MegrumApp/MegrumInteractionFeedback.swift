import MegrumDesign
import SwiftUI

#if os(iOS)
import UIKit
#endif

enum MegrumHaptics {
    static func longPress() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.72)
        #endif
    }

    static func selectionChanged() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
}

extension View {
    func megrumInteractionFeedback() -> some View {
        modifier(MegrumInteractionFeedbackModifier())
    }
}

private struct MegrumInteractionFeedbackModifier: ViewModifier {
    @State private var ripples: [MegrumTapRipple] = []

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(tapGesture)
            .overlay(alignment: .topLeading) {
                GeometryReader { proxy in
                    ForEach(ripples) { ripple in
                        MegrumTapRippleView(origin: ripple.location)
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                            .allowsHitTesting(false)
                    }
                }
                .allowsHitTesting(false)
            }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                addRipple(at: value.location)
            }
    }

    private func addRipple(at location: CGPoint) {
        let ripple = MegrumTapRipple(location: location)
        ripples.append(ripple)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 720_000_000)
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

private struct MegrumTapRipple: Identifiable, Equatable {
    let id = UUID()
    var location: CGPoint
}

private struct MegrumTapRippleView: View {
    var origin: CGPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(reduceTransparency ? 0.14 : 0.30),
                            MegrumTheme.sky.opacity(reduceTransparency ? 0.10 : 0.24),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: rippleDiameter * 0.52
                    )
                )

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(0.72),
                            MegrumTheme.sky.opacity(0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.2
                )
        }
        .frame(width: rippleDiameter, height: rippleDiameter)
        .scaleEffect(reduceMotion ? 0.98 : 0.22 + progress * 1.08)
        .opacity(1 - progress)
        .position(origin)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.12 : 0.62)) {
                progress = 1
            }
        }
    }

    private var rippleDiameter: CGFloat {
        reduceMotion ? 64 : 174
    }
}
