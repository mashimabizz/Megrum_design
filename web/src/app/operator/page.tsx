import type { Metadata } from "next";
import {
  CONTACT_EMAIL,
  LegalSection,
  LegalShell,
  OFFICE_ADDRESS_LINES,
  SITE_URL,
  TextLink,
} from "../_publicComponents";

export const metadata: Metadata = {
  title: "運営者情報",
  description:
    "Megrumの運営者情報。サービス名、公式サイト、問い合わせ先、オフィス所在地を掲載しています。",
  alternates: {
    canonical: "/operator",
  },
};

const infoRows = [
  { label: "サービス名", value: "Megrum" },
  { label: "公式サイト", value: SITE_URL },
  { label: "問い合わせ先", value: CONTACT_EMAIL },
];

export default function OperatorPage() {
  return (
    <LegalShell
      eyebrow="Operator"
      title="運営者情報"
      updated="2026年6月29日"
      intro="Megrumの運営に関する基本情報と、オフィス所在地を掲載しています。サービスに関する問い合わせはサポート窓口で受け付けています。"
    >
      <LegalSection title="基本情報">
        <dl className="divide-y divide-slate-200 rounded-lg border border-slate-200 bg-[#fbf9fc]">
          {infoRows.map((row) => (
            <div
              key={row.label}
              className="grid gap-1 px-4 py-3 md:grid-cols-[10rem_1fr] md:gap-4"
            >
              <dt className="text-[13px] font-black text-slate-500">
                {row.label}
              </dt>
              <dd className="text-[14px] font-bold text-slate-800">
                {row.value}
              </dd>
            </div>
          ))}
        </dl>
      </LegalSection>

      <LegalSection title="オフィス所在地">
        <address className="not-italic">
          {OFFICE_ADDRESS_LINES.map((line) => (
            <span key={line} className="block">
              {line}
            </span>
          ))}
        </address>
      </LegalSection>

      <LegalSection title="問い合わせ">
        <p>
          アプリの利用、通報相談、個人情報に関する請求、運営者情報に関する問い合わせは
          <TextLink href="/support">サポートページ</TextLink>
          からご連絡ください。
        </p>
      </LegalSection>
    </LegalShell>
  );
}
