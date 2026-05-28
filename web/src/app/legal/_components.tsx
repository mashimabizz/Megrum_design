/**
 * iter83: 法的画面の共通コンポーネント（legal-pages.jsx の LP* 準拠）
 *
 * 注：表示テキストは既存モックアップから移植。本番展開時は notes/17_legal_alignment.md
 * の規約原典 (.docx) と整合させてアップデートすること。
 */

export function LPInfoBox({
  children,
  tone = "info",
}: {
  children: React.ReactNode;
  tone?: "info" | "warn";
}) {
  return (
    <div
      className={`mb-4 rounded-[12px] border px-3.5 py-3 text-[12px] leading-[1.7] ${
        tone === "warn"
          ? "border-[#d9826b40] bg-[#fff5f0] text-[#3a324a]"
          : "border-[#a695d855] bg-[#a695d80a] text-[#3a324a]"
      }`}
    >
      {children}
    </div>
  );
}

export function LPArticle({
  num,
  title,
  children,
}: {
  num: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mb-4">
      <div className="mb-1.5 flex items-baseline gap-2">
        <span className="text-[11px] font-extrabold tracking-[0.4px] text-[#a695d8]">
          {num}
        </span>
        <span className="text-[14px] font-bold text-[#3a324a]">{title}</span>
      </div>
      <div className="text-[12.5px] leading-[1.85] text-[#3a324a]">
        {children}
      </div>
    </section>
  );
}

export function LPDataRow({
  label,
  value,
  isLast,
}: {
  label: string;
  value: React.ReactNode;
  isLast?: boolean;
}) {
  return (
    <div
      className={`flex items-start gap-3 px-1 py-3 ${
        isLast ? "" : "border-b border-[#3a324a08]"
      }`}
    >
      <div className="w-[100px] flex-shrink-0 text-[11px] font-bold text-[#3a324a8c]">
        {label}
      </div>
      <div className="flex-1 text-[12.5px] leading-[1.65] text-[#3a324a]">
        {value}
      </div>
    </div>
  );
}

export function LPFooter({ updatedAt }: { updatedAt: string }) {
  return (
    <div className="border-t border-[#3a324a14] pb-8 pt-4 text-right text-[11px] leading-[1.7] text-[#3a324a8c]">
      {updatedAt}
      <br />
      Megrum 運営者
    </div>
  );
}
