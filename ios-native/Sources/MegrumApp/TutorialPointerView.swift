import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// デモ実演用の指アイコン。位置は親がアニメーション付きで動かす。
/// `isPressed` でタップ中の縮み＋波紋を表現する。
struct TutorialPointerView: View {
    var isPressed: Bool = false

    var body: some View {
        ZStack {
            if isPressed {
                Circle()
                    .stroke(MegrumTheme.lavender.opacity(0.55), lineWidth: 3)
                    .frame(width: 54, height: 54)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                .overlay {
                    Image(systemName: "hand.point.up.left")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.85))
                }
                .scaleEffect(isPressed ? 0.86 : 1.0)
                .rotationEffect(.degrees(-12))
                // 指先（左上）がタップ点に来るように少し右下へずらす。
                .offset(x: 13, y: 17)
        }
        .allowsHitTesting(false)
    }
}

/// シーン内で指の動きを台本化するための小さなヘルパー。
/// 例：`await choreo.move(to: p1); await choreo.tap()`
@MainActor
final class TutorialPointerChoreographer: ObservableObject {
    @Published var position: CGPoint = .zero
    @Published var isPressed = false
    @Published var isVisible = false

    private var reduceMotion: Bool {
        #if canImport(UIKit)
        UIAccessibility.isReduceMotionEnabled
        #else
        false
        #endif
    }

    func appear(at point: CGPoint) {
        position = point
        withAnimation(.easeOut(duration: reduceMotion ? 0 : 0.2)) {
            isVisible = true
        }
    }

    func move(to point: CGPoint, duration: Double = 0.5) async {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) {
            position = point
        }
        try? await Task.sleep(nanoseconds: UInt64((reduceMotion ? 0.05 : duration) * 1_000_000_000))
    }

    func tap() async {
        withAnimation(.easeOut(duration: 0.12)) { isPressed = true }
        try? await Task.sleep(nanoseconds: 180_000_000)
        withAnimation(.easeIn(duration: 0.16)) { isPressed = false }
        try? await Task.sleep(nanoseconds: 220_000_000)
    }

    /// ドラッグ演技：押したまま移動して離す。
    func drag(to point: CGPoint, duration: Double = 0.7) async {
        withAnimation(.easeOut(duration: 0.12)) { isPressed = true }
        try? await Task.sleep(nanoseconds: 160_000_000)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) {
            position = point
        }
        try? await Task.sleep(nanoseconds: UInt64((reduceMotion ? 0.05 : duration) * 1_000_000_000))
        withAnimation(.easeIn(duration: 0.16)) { isPressed = false }
        try? await Task.sleep(nanoseconds: 180_000_000)
    }

    func hide() {
        withAnimation(.easeIn(duration: 0.15)) {
            isVisible = false
        }
    }
}

/// シーンに指レイヤーを重ねるための共通コンテナ。
struct TutorialPointerLayer: View {
    @ObservedObject var choreo: TutorialPointerChoreographer

    var body: some View {
        ZStack {
            if choreo.isVisible {
                TutorialPointerView(isPressed: choreo.isPressed)
                    .position(choreo.position)
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
    }
}
