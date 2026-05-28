/**
 * Megrum ロゴ（モックアップ AOLogo 準拠）
 *
 * - 角丸正方形（borderRadius: size × 0.32）
 * - 2色グラデ（lavender → sky）
 * - 中央に「Mg」テキスト（Inter Tight）
 * - boxShadow: 0 8px 24px lavender 25%
 */
export function MegrumLogo({ size = 64 }: { size?: number }) {
  return (
    <div
      className="flex items-center justify-center font-extrabold text-white"
      style={{
        width: size,
        height: size,
        borderRadius: size * 0.32,
        background: "linear-gradient(135deg, #a695d8, #a8d4e6)",
        boxShadow: "0 8px 24px rgba(166, 149, 216, 0.25)",
        fontFamily: "var(--font-inter-tight), system-ui",
        fontSize: size * 0.42,
        letterSpacing: -1,
      }}
    >
      Mg
    </div>
  );
}
