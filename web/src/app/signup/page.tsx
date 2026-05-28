import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { SignUpForm } from "./SignUpForm";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "新規登録 — Megrum",
};

export default async function SignUpPage() {
  // 既ログインなら / へ
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user) redirect("/");

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="新規登録" backHref="/" />
      <div className="mx-auto w-full max-w-md flex-1 px-5 pb-8 pt-6">
        <h2 className="text-[22px] font-extrabold leading-tight text-gray-900">
          はじめまして
        </h2>
        <p className="mt-1.5 text-xs leading-relaxed text-gray-500">
          メールアドレスとパスワードを設定して、Megrum を始めましょう
        </p>
        <div className="mt-6">
          <SignUpForm />
        </div>
      </div>
    </main>
  );
}
