import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { GenderForm } from "./GenderForm";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ProgressDots } from "@/components/auth/ProgressDots";

export const metadata = {
  title: "プロフィール設定 — Megrum",
};

/**
 * オンボーディング 1/4: 性別選択（モックアップ AOOnboardGender 準拠）
 */
export default async function GenderPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 既存値（再訪時の初期選択）
  const { data: profile } = await supabase
    .from("users")
    .select("gender")
    .eq("id", user.id)
    .maybeSingle();

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="プロフィール設定"
        sub="マッチングの安全性のため"
        progress="1/4"
        backHref="/auth/email-confirmed"
      />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-6">
        <ProgressDots current={0} total={4} />
        <h2 className="mt-4 text-[22px] font-extrabold leading-tight text-gray-900">
          性別を教えてください
        </h2>
        <p className="mt-2 text-xs leading-relaxed text-gray-500">
          マッチング前のプロフィールに表示されます。
          <br />
          現地交換時の安全性のために必要な情報です。
        </p>
        <GenderForm initialValue={profile?.gender} />
      </div>
    </main>
  );
}
