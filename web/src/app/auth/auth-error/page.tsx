import Link from "next/link";

export const metadata = {
  title: "認証エラー — Megrum",
};

export default function AuthErrorPage() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center bg-gradient-to-b from-purple-50 via-white to-pink-50 px-6 py-12">
      <div className="w-full max-w-md text-center">
        <Link href="/admin" className="inline-block">
          <span className="inline-block rounded-full bg-purple-100 px-4 py-1 text-xs font-bold tracking-widest text-purple-700">
            ★ Megrum
          </span>
        </Link>

        <div className="mx-auto mt-6 flex h-16 w-16 items-center justify-center rounded-full bg-red-100">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            className="h-8 w-8 text-red-600"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"
            />
          </svg>
        </div>

        <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-gray-900">
          認証エラー
        </h1>

        <p className="mt-4 text-base leading-relaxed text-gray-600">
          認証に失敗しました。
          <br />
          リンクの有効期限が切れているか、すでに使用済みの可能性があります。
        </p>

        <div className="mt-8 flex flex-col gap-3">
          <Link
            href="/login"
            className="rounded-lg bg-gradient-to-r from-purple-500 to-pink-500 px-4 py-3 text-base font-bold text-white shadow-md transition-all hover:from-purple-600 hover:to-pink-600"
          >
            ログイン画面へ
          </Link>
        </div>
      </div>
    </main>
  );
}
