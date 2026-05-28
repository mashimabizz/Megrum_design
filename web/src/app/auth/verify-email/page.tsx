import Link from "next/link";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ResendButton } from "./ResendButton";

export const metadata = {
  title: "メール認証 — Megrum",
};

type Props = {
  searchParams: Promise<{ email?: string; resent?: string }>;
};

export default async function VerifyEmailPage({ searchParams }: Props) {
  const params = await searchParams;
  const email = params.email ?? "";
  const wasResent = params.resent === "1";

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="メール認証" backHref="/signup" />
      <div className="mx-auto w-full max-w-md flex-1 px-7 pb-8 pt-10 text-center">
        {/* 中央アイコン（モックアップ：紫＆水色のグラデ丸 + メールアイコン） */}
        <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-gradient-to-br from-purple-100 to-sky-100">
          <svg
            width="40"
            height="40"
            viewBox="0 0 40 40"
            fill="none"
            stroke="#a695d8"
            strokeWidth="1.8"
          >
            <rect x="6" y="10" width="28" height="20" rx="3" />
            <path d="M6 13l14 9 14-9" />
          </svg>
        </div>

        <h1 className="mt-5 text-xl font-extrabold leading-tight text-gray-900">
          確認メールを送りました
        </h1>

        <p className="mt-2 text-[13px] leading-relaxed text-gray-500">
          下記のメールアドレスに認証用のリンクを送りました。
          <br />
          メール内のリンクをタップして、認証を完了してください。
        </p>

        {/* resent 通知（既存メアド未認証の再 signup 流入時） */}
        {wasResent && (
          <div className="mx-auto mt-5 inline-block rounded-lg bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700">
            ✓ 確認メールを再送しました
          </div>
        )}

        {/* メアド表示 */}
        {email && (
          <div className="mx-auto mt-5 inline-block rounded-xl border border-gray-200 bg-white px-4 py-3 text-[13px] font-semibold text-gray-900">
            {email}
          </div>
        )}

        {/* 注意書き（ピンク背景） */}
        <div className="mt-6 rounded-xl bg-pink-100/70 px-4 py-3 text-left text-[11px] leading-relaxed text-gray-800">
          <span className="font-bold">📧 メールが届かない場合</span>
          <br />
          迷惑メールフォルダもご確認ください。それでも見つからない場合は、再送信または別のメールアドレスをお試しください。
        </div>

        {/* 再送信ボタン（60秒クールダウン） */}
        {email && (
          <div className="mt-6">
            <ResendButton
              email={email}
              initialCooldown={wasResent ? 60 : 0}
            />
          </div>
        )}

        {/* メールアドレスを変更する */}
        <div className="mt-2.5">
          <Link
            href="/signup"
            className="inline-block px-2 py-2 text-[13px] font-semibold text-purple-600 hover:text-purple-700"
          >
            メールアドレスを変更する
          </Link>
        </div>
      </div>
    </main>
  );
}
