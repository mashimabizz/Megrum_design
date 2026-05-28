import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { ResetForm } from "./ResetForm";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "パスワードリセット — Megrum",
};

/**
 * パスワードリセット画面（モックアップ AOPasswordReset 準拠）
 *
 * - 既ログインなら / へ
 * - メアド入力 → リセットメール送信 → /auth/verify-email へ
 */
export default async function PasswordResetPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user) redirect("/");

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="パスワードリセット" backHref="/login" />
      <div className="mx-auto w-full max-w-md flex-1 px-5 pb-8 pt-8">
        <h2 className="mb-2.5 text-xl font-extrabold text-gray-900">
          パスワードを再設定します
        </h2>
        <p className="mb-5 text-xs leading-relaxed text-gray-500">
          ご登録のメールアドレスを入力してください。
          <br />
          パスワードリセット用のリンクをお送りします。
        </p>
        <ResetForm />
      </div>
    </main>
  );
}
