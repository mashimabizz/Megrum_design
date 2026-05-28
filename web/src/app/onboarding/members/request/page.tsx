import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { RequestForm } from "./RequestForm";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "メンバー追加リクエスト — Megrum",
};

type Props = {
  searchParams: Promise<{
    groupId?: string;
    oshiRequestId?: string;
    return?: string;
  }>;
};

/**
 * メンバー追加リクエスト画面
 *
 * - クエリパラメータ: groupId（既存マスタ）または oshiRequestId（審査中）
 * - 名前 / メモ を入力 → character_requests に挿入
 * - 送信後 /onboarding/members に戻る
 */
export default async function CharacterRequestPage({ searchParams }: Props) {
  const params = await searchParams;
  const { groupId, oshiRequestId, return: returnTo } = params;
  const backHref =
    returnTo === "profile" ? "/profile/oshi" : "/onboarding/members";
  if (!groupId && !oshiRequestId) redirect(backHref);

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 親グループ情報を取得（groups_master か oshi_requests のどちらか）
  let parentName: string | null = null;
  let isPendingParent = false;

  if (groupId) {
    const { data: group } = await supabase
      .from("groups_master")
      .select("id, name")
      .eq("id", groupId)
      .maybeSingle();
    parentName = group?.name ?? null;
  } else if (oshiRequestId) {
    const { data: req } = await supabase
      .from("oshi_requests")
      .select("id, requested_name, status")
      .eq("id", oshiRequestId)
      .maybeSingle();
    if (req && req.status === "pending") {
      parentName = req.requested_name;
      isPendingParent = true;
    }
  }

  if (!parentName) redirect(backHref);

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="メンバー追加リクエスト" backHref={backHref} />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-6">
        <h2 className="text-[22px] font-extrabold leading-tight text-gray-900">
          メンバーを追加リクエスト
        </h2>
        <p className="mt-2 text-xs leading-relaxed text-gray-500">
          公式メンバーが見つからない場合、運営に追加リクエストを送ります。
          <br />
          審査の上、マスタに登録されます。
        </p>
        <RequestForm
          groupId={groupId}
          oshiRequestId={oshiRequestId}
          parentName={parentName}
          isPendingParent={isPendingParent}
        />
      </div>
    </main>
  );
}
