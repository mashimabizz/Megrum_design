import type { Metadata } from "next";
import {
  CONTACT_EMAIL,
  LegalSection,
  LegalShell,
  TextLink,
} from "../_publicComponents";

export const metadata: Metadata = {
  title: "サポート",
  description:
    "Megrumの問い合わせ窓口。サポート、通報相談、アカウント削除、個人情報に関する請求を受け付けます。",
  alternates: {
    canonical: "/support",
  },
};

const mailto = `mailto:${CONTACT_EMAIL}?subject=${encodeURIComponent(
  "Megrumへの問い合わせ",
)}`;

export default function SupportPage() {
  return (
    <LegalShell
      eyebrow="Support"
      title="サポート"
      updated="2026年6月26日"
      intro="Megrumに関する問い合わせ、通報相談、アカウント削除、個人情報に関する請求は、サポート窓口で受け付けています。"
    >
      <LegalSection title="問い合わせ先">
        <p>
          メール：
          <a
            href={mailto}
            className="font-black text-violet-700 underline decoration-megrum-lavender/35 underline-offset-4"
          >
            {CONTACT_EMAIL}
          </a>
        </p>
        <p>
          返信が必要な問い合わせには、内容を確認のうえ順次回答します。本人確認が必要な請求では、追加情報の提出をお願いすることがあります。
        </p>
      </LegalSection>

      <LegalSection title="受け付けている内容">
        <div className="grid gap-3 md:grid-cols-2">
          {[
            "アプリの使い方、ログイン、通知、表示不具合に関する相談",
            "取引、打診、取引チャット、現地交換に関する困りごと",
            "プロフィール、グッズ、投稿、メッセージに関する通報相談",
            "アカウント削除、データ削除、利用停止に関する問い合わせ",
            "個人情報の開示、訂正、削除、利用停止等の請求",
            "運営者情報、プライバシーポリシー、利用規約に関する問い合わせ",
          ].map((item) => (
            <div
              key={item}
              className="rounded-lg border border-slate-200 bg-[#fbf9fc] px-4 py-3 text-[13px] font-bold leading-7 text-slate-700"
            >
              {item}
            </div>
          ))}
        </div>
      </LegalSection>

      <LegalSection title="問い合わせ時に書いてほしいこと">
        <p>できる範囲で、以下の情報を添えてください。</p>
        <ul className="list-disc space-y-2 pl-5">
          <li>Megrumに登録しているメールアドレス又はハンドル</li>
          <li>発生した画面、日時、相手ユーザーや取引が分かる情報</li>
          <li>困っている内容、希望する対応、添付できるスクリーンショット</li>
          <li>個人情報に関する請求の場合、本人確認に必要な情報</li>
        </ul>
      </LegalSection>

      <LegalSection title="緊急時について">
        <p>
          身の危険を感じる場合、犯罪、つきまとい、脅迫、盗難、事故などの緊急性がある場合は、Megrumへの連絡とあわせて、警察、会場スタッフ、施設管理者など適切な窓口へ相談してください。
        </p>
      </LegalSection>

      <LegalSection title="関連ページ">
        <p>
          個人情報の扱いは
          <TextLink href="/privacy">プライバシーポリシー</TextLink>
          、サービス利用条件は
          <TextLink href="/terms">利用規約</TextLink>
          を確認してください。
        </p>
      </LegalSection>
    </LegalShell>
  );
}
