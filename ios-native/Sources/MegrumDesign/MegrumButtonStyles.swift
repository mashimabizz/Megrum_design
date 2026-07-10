import SwiftUI

// MARK: - グラデーショントークン（iter1226.404）
// 単色ラベンダーの面塗りを減らし、Web版 PrimaryButton（linear-gradient(135deg, #a695d8, #a8d4e6)）
// と揃えた2色グラデを共通トークンにする。面積の大きい塗りはグラデ or 中立色、
// 単色ラベンダーは小さいアクセント（選択チェック・フォーカスリング・リンク文字）のみ。

public extension MegrumTheme {
    /// 主アクション用 2色グラデ（lavender→sky、135deg相当）。Web版 PrimaryButton と同一。
    static let primaryGradient = LinearGradient(
        colors: [lavender, sky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 強アクセント用グラデ（pink→濃ピンク）。ホーム需要行の「超求！」と同系。
    static let accentGradient = LinearGradient(
        colors: [pink, Color(red: 0.94, green: 0.35, blue: 0.55)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Welcome/ヒーロー用 3色グラデ。通常画面のボタンには使わない。
    static let heroGradient = LinearGradient(
        colors: [lavender, sky, pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 主ボタンの影色（Web版 shadow rgba(166,149,216,0.33) 相当）。
    static let primaryShadow = lavender.opacity(0.33)
}

// MARK: - 共通ボタンスタイル
// 新規ボタンは原則この3種（primary / secondary / iOS標準destructive）から選ぶ。
// ラベンダー枠線ボタンは廃止方針（iter1226.404）。

/// 主アクション：グラデ塗り・radius14・高さ52・押下スケール0.97・disabled時 opacity 0.5。
public struct MegrumPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private var height: CGFloat

    public init(height: CGFloat = 52) {
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                MegrumTheme.primaryGradient,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .shadow(
                color: isEnabled ? MegrumTheme.primaryShadow : .clear,
                radius: 14, x: 0, y: 4
            )
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// 従アクション：ink 5% の中立塗り・枠線なし・radius14。
public struct MegrumSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private var height: CGFloat

    public init(height: CGFloat = 52) {
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink.opacity(0.82))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                MegrumTheme.ink.opacity(configuration.isPressed ? 0.09 : 0.05),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == MegrumPrimaryButtonStyle {
    /// 主アクション（グラデ・radius14・高さ52）。
    static var megrumPrimary: MegrumPrimaryButtonStyle { MegrumPrimaryButtonStyle() }

    static func megrumPrimary(height: CGFloat) -> MegrumPrimaryButtonStyle {
        MegrumPrimaryButtonStyle(height: height)
    }
}

public extension ButtonStyle where Self == MegrumSecondaryButtonStyle {
    /// 従アクション（中立塗り・radius14・高さ52）。
    static var megrumSecondary: MegrumSecondaryButtonStyle { MegrumSecondaryButtonStyle() }

    static func megrumSecondary(height: CGFloat) -> MegrumSecondaryButtonStyle {
        MegrumSecondaryButtonStyle(height: height)
    }
}
