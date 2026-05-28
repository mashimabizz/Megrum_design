import Link from "next/link";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "ヘルプ・FAQ — Megrum",
};

/**
 * iter93: ヘルプ・FAQ + 運営問い合わせ
 *
 * 静的 FAQ。複雑な検索や記事システムは MVP 範囲外。
 */
export default function HelpPage() {
  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="ヘルプ・FAQ"
        sub="使い方・取引の流れ・よくある質問"
        backHref="/settings"
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        {/* 問い合わせ hero */}
        <div className="mb-3.5 rounded-[14px] border border-[#a695d840] bg-[linear-gradient(135deg,rgba(166,149,216,0.10),rgba(168,212,230,0.10))] px-3.5 py-3">
          <div className="text-[12.5px] font-extrabold text-[#3a324a]">
            お困りの場合は運営に直接ご連絡ください
          </div>
          <div className="mt-1 text-[11px] leading-relaxed text-[#3a324a8c]">
            FAQ にない内容や、取引のトラブルなどは下記の窓口から
            <br />
            受付：平日 10:00〜18:00（土日祝・年末年始を除く）
          </div>
          <div className="mt-2 flex gap-2">
            <a
              href="mailto:support@megrum.jp"
              className="rounded-[10px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-3 py-1.5 text-[11.5px] font-bold text-white shadow-[0_2px_5px_rgba(166,149,216,0.4)]"
            >
              ✉ support@megrum.jp
            </a>
          </div>
        </div>

        {/* 取引の流れ */}
        <Section label="取引の流れ">
          <Faq
            q="Megrum とは？"
            a="Megrum は K-POP / アニメ等の推し活グッズを現地で物々交換するためのマッチング・取引プラットフォームです。郵送ではなく対面交換が前提です。"
          />
          <Faq
            q="取引の基本フロー"
            a={
              <>
                ① ホーム画面でマッチを探す（または検索）
                <br />
                ② 相手に「打診」を送る
                <br />
                ③ 相手が承諾すると合意成立、取引チャットへ
                <br />
                ④ 当日合流して交換、「証跡」を撮影
                <br />
                ⑤ 双方が承認したら取引完了 → 評価
              </>
            }
          />
          <Faq
            q="現地モードとは？"
            a="ホーム上の「現地交換モード」を ON にすると、自分の AW（合流可能枠）を設定でき、近隣のユーザーとマッチングしやすくなります。OFF（広域モード）では距離を問わずマッチを探します。"
          />
        </Section>

        {/* マッチング・打診 */}
        <Section label="マッチング・打診">
          <Faq
            q="マッチカードに表示される「両方向 候補」「あなたを求めてる 候補」とは？"
            a="システムが「グループ・キャラ・グッズ種別」の一致でピックアップした交換可能性の高い候補です。実際に交換できるかは、写真と推し具合（同種／異種など）を見てユーザー自身で判断してください。両方向＝お互いの wish が候補化、片方向＝どちらか一方の wish が候補化。"
          />
          <Faq
            q="個別募集（listing）とは？"
            a="複数のグッズを「セット交換」「いずれか OK」など条件付きで募集できる機能です。譲 1 バンドル + 求 N 選択肢の構造で、より具体的な条件マッチが可能です。"
          />
          <Faq
            q="ネゴ（条件相談）と打診の違い"
            a="打診は最初の提案、ネゴは送信後に条件を相談するチャットです。両者が「合意」を押すと取引フェーズに進みます。打診の期限は 7 日（最大 3 回まで延長可）。"
          />
          <Faq
            q="打診はキャンセルできますか？"
            a="合意前は「条件を変えて再打診」が可能。合意済みの取引は『キャンセル要請』を相手に送って同意を得る必要があります。同意がなければ申告フローに進みます。"
          />
        </Section>

        {/* 取引・申告 */}
        <Section label="取引・申告">
          <Faq
            q="取引証跡（C-3 の写真）とは？"
            a="合意済みの取引で、当日交換時に両者が確認のために撮影する写真です。受け取ったグッズが揃っていることを記録するもので、申告時の証拠にもなります。"
          />
          <Faq
            q="「相違あり」「申告」したい時"
            a="取引完了確認画面で『相違あり』を選ぶと申告フォームに進みます。受け取った点数が少ない・グッズが違う・相手が来なかった等を運営に報告できます。"
          />
          <Faq
            q="申告中の制限"
            a="新規打診は一時制限されますが、既に進行中の取引は通常通り続行できます。評価は結論が出るまで保留されます。"
          />
        </Section>

        {/* アカウント */}
        <Section label="アカウント・設定">
          <Faq
            q="ハンドル名は変更できますか？"
            a={
              <>
                プロフィール編集から変更できます。
                <Link href="/profile/edit" className="text-[#a695d8] underline">
                  → プロフィール編集
                </Link>
              </>
            }
          />
          <Faq
            q="通知の ON/OFF を切り替えたい"
            a={
              <>
                アプリ内通知は常時 ON（無効化不可）。メール通知の ON/OFF
                は設定画面で切り替えられます。
                <Link
                  href="/settings/notifications"
                  className="text-[#a695d8] underline"
                >
                  → 通知設定
                </Link>
              </>
            }
          />
          <Faq
            q="アカウントを削除したい"
            a="現在準備中の機能です。お急ぎの場合は support@megrum.jp までご連絡ください。"
          />
        </Section>

        {/* 規約 */}
        <Section label="規約・法的情報">
          <LinkRow href="/legal/terms" icon="📄" title="利用規約" />
          <LinkRow
            href="/legal/privacy"
            icon="🔐"
            title="プライバシーポリシー"
          />
          <LinkRow
            href="/legal/notice"
            icon="📜"
            title="特定商取引法に基づく表記"
          />
        </Section>
      </div>
    </main>
  );
}

function Section({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-4">
      <div className="mb-1.5 px-1 text-[10.5px] font-bold uppercase tracking-[0.6px] text-[#3a324a8c]">
        {label}
      </div>
      <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
        {children}
      </div>
    </div>
  );
}

function Faq({ q, a }: { q: string; a: React.ReactNode }) {
  return (
    <details className="group border-b border-[#3a324a08] last:border-b-0">
      <summary className="flex cursor-pointer items-center gap-2 px-3.5 py-3 text-[12.5px] font-bold text-[#3a324a]">
        <span className="flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full bg-[#a695d822] text-[10px] font-extrabold text-[#a695d8]">
          Q
        </span>
        <span className="flex-1">{q}</span>
        <span className="text-[12px] text-[#3a324a8c] transition-transform group-open:rotate-90">
          ›
        </span>
      </summary>
      <div className="px-3.5 pb-3 pl-[42px] text-[12px] leading-relaxed text-[#3a324a8c]">
        {a}
      </div>
    </details>
  );
}

function LinkRow({
  href,
  icon,
  title,
}: {
  href: string;
  icon: string;
  title: string;
}) {
  return (
    <Link
      href={href}
      className="flex items-center gap-3 border-b border-[#3a324a08] px-3.5 py-3 last:border-b-0 active:scale-[0.99]"
    >
      <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center text-[18px] leading-none">
        {icon}
      </div>
      <span className="flex-1 text-[13px] font-bold text-[#3a324a]">
        {title}
      </span>
      <span className="text-[12px] text-[#3a324a8c]">›</span>
    </Link>
  );
}
