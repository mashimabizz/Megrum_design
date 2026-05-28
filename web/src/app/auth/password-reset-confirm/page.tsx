import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { PasswordResetConfirmForm } from "./PasswordResetConfirmForm";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "新しいパスワード — Megrum",
};

type Props = {
  searchParams: Promise<{ code?: string; error?: string }>;
};

/**
 * パスワードリセット後の新パスワード設定画面
 *
 * フロー:
 * 1. ユーザーがメール内リンクをクリック
 * 2. Supabase が `?code=xxx` 付きでこのページに redirect
 * 3. exchangeCodeForSession で session を確立
 * 4. 新パスワード入力フォームを表示
 * 5. updateUser({ password }) で更新 → /login?password_reset=success
 */
export default async function PasswordResetConfirmPage({
  searchParams,
}: Props) {
  const params = await searchParams;
  const supabase = await createClient();

  // code がある場合は session に交換
  if (params.code) {
    const { error } = await supabase.auth.exchangeCodeForSession(params.code);
    if (error) {
      redirect("/auth/auth-error");
    }
  }

  // session 確立確認（code が有効でセッションができてるはず）
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    redirect("/auth/auth-error");
  }

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="新しいパスワード" backHref="/login" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-6">
        <h2 className="text-[22px] font-extrabold leading-tight text-gray-900">
          新しいパスワードを設定
        </h2>
        <p className="mt-2 text-xs leading-relaxed text-gray-500">
          新しいパスワードを入力してください。
          <br />
          設定後、ログイン画面でログインできます。
        </p>
        <div className="mt-6">
          <PasswordResetConfirmForm />
        </div>
      </div>
    </main>
  );
}
