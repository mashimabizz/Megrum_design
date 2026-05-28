import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { AreaForm } from "./AreaForm";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ProgressDots } from "@/components/auth/ProgressDots";

export const metadata = {
  title: "プロフィール設定 — Megrum",
};

/**
 * オンボーディング 4/4: 活動エリア（モックアップ AOOnboardAW 準拠）
 *
 * - 主な活動エリア（複数選択可・任意）
 * - 「あとで設定する」スキップ可
 * - 完了 / スキップで onboarding 終了 → /onboarding/done
 */
export default async function AreaPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("users")
    .select("primary_area")
    .eq("id", user.id)
    .maybeSingle();

  const initialAreas: string[] = profile?.primary_area
    ? profile.primary_area.split(",").map((s: string) => s.trim()).filter(Boolean)
    : [];

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="プロフィール設定"
        sub="主な活動エリア（任意）"
        progress="4/4"
        backHref="/onboarding/members"
      />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-6">
        <ProgressDots current={3} total={4} />
        <h2 className="mt-4 text-[22px] font-extrabold leading-tight text-gray-900">
          よく行くエリアは？
        </h2>
        <p className="mt-2 text-xs leading-relaxed text-gray-500">
          現地交換のマッチングに使います。
          <br />
          ライブ・イベントごとの詳細はあとで設定できます。
        </p>
        <AreaForm initialAreas={initialAreas} />
      </div>
    </main>
  );
}
