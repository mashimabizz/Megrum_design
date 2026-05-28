import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { LoginForm } from "./LoginForm";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { MegrumLogo } from "@/components/auth/MegrumLogo";

export const metadata = {
  title: "ログイン — Megrum",
};

type Props = {
  searchParams: Promise<{ password_reset?: string }>;
};

export default async function LoginPage({ searchParams }: Props) {
  const params = await searchParams;
  const passwordResetSuccess = params.password_reset === "success";

  // 既ログインなら / へ
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user) redirect("/");

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="ログイン" backHref="/" />
      <div className="mx-auto w-full max-w-md flex-1 px-5 pb-8 pt-8">
        {/* Megrum ロゴ + おかえりなさい */}
        <div className="mb-7 flex flex-col items-center">
          <MegrumLogo size={60} />
          <p className="mt-3.5 text-xs text-gray-500">おかえりなさい</p>
        </div>

        {passwordResetSuccess && (
          <div className="mb-5 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-800">
            ✓ パスワードを変更しました。新しいパスワードでログインしてください。
          </div>
        )}

        <LoginForm />

        {/* 新規登録誘導 */}
        <div className="mt-6 text-center text-[13px] text-gray-500">
          アカウントをお持ちでない方は{" "}
          <Link
            href="/signup"
            className="font-bold text-purple-600 hover:text-purple-700"
          >
            新規登録
          </Link>
        </div>
      </div>
    </main>
  );
}
