import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "評価一覧 — Megrum",
};

/**
 * iter146：他人プロフィールの評価コメント一覧ページ。
 * プロフ画面の hero 右上の「★平均 (件数)」をタップして来る。
 */
export default async function UserEvaluationsPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user: me },
  } = await supabase.auth.getUser();
  if (!me) redirect("/login");

  const { data: user } = await supabase
    .from("users")
    .select("id, handle, display_name, account_status")
    .eq("id", id)
    .maybeSingle();
  if (!user) notFound();
  if (
    user.account_status === "deleted" ||
    user.account_status === "suspended"
  ) {
    notFound();
  }

  // 評価全件取得（コメント有無問わず stars 集計用に全部）
  const { data: allEvals } = await supabase
    .from("user_evaluations")
    .select("stars, comment, created_at, rater_id")
    .eq("ratee_id", id)
    .order("created_at", { ascending: false });

  const all = allEvals ?? [];
  const stars = all.map((e) => e.stars as number);
  const ratingAvg =
    stars.length > 0 ? stars.reduce((a, b) => a + b, 0) / stars.length : null;
  const ratingCount = stars.length;

  // rater handle を fetch
  const raterIds = Array.from(
    new Set(all.map((e) => e.rater_id as string)),
  );
  const handlesById = new Map<string, string>();
  if (raterIds.length > 0) {
    const { data: rs } = await supabase
      .from("users")
      .select("id, handle")
      .in("id", raterIds);
    if (rs) {
      for (const r of rs) handlesById.set(r.id as string, r.handle as string);
    }
  }

  // 星別ヒストグラム
  const histogram: Record<number, number> = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
  for (const s of stars) {
    if (s >= 1 && s <= 5) histogram[s] = (histogram[s] ?? 0) + 1;
  }

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title={`@${user.handle} の評価`}
        sub={ratingCount > 0 ? `${ratingCount} 件` : undefined}
        backHref={`/users/${id}`}
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        {ratingCount === 0 ? (
          <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-10 text-center text-[12px] text-[#3a324a8c]">
            まだ評価がありません
          </div>
        ) : (
          <>
            {/* サマリパネル */}
            <div className="mb-3 rounded-2xl border border-[#a695d855] bg-[linear-gradient(120deg,#a695d80f,#a8d4e60f)] px-4 py-3.5">
              <div className="flex items-center gap-3">
                <div className="text-center">
                  <div
                    className="text-[28px] font-extrabold leading-none text-[#a695d8]"
                    style={{ fontFamily: '"Inter Tight", sans-serif' }}
                  >
                    ★{ratingAvg!.toFixed(1)}
                  </div>
                  <div className="mt-0.5 text-[10px] text-[#3a324a8c]">
                    {ratingCount} 件
                  </div>
                </div>
                <div className="min-w-0 flex-1">
                  {[5, 4, 3, 2, 1].map((s) => {
                    const c = histogram[s] ?? 0;
                    const pct = ratingCount > 0 ? (c / ratingCount) * 100 : 0;
                    return (
                      <div
                        key={s}
                        className="flex items-center gap-2 text-[10px]"
                      >
                        <span className="w-3 text-right text-[#3a324a8c]">
                          {s}
                        </span>
                        <span className="text-[#a695d8]">★</span>
                        <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-[#3a324a08]">
                          <div
                            className="h-full bg-[#a695d8]"
                            style={{ width: `${pct}%` }}
                          />
                        </div>
                        <span className="w-5 text-right tabular-nums text-[#3a324a8c]">
                          {c}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* コメント一覧（全件） */}
            <div className="space-y-2">
              {all
                .filter(
                  (e): e is typeof e & { comment: string } =>
                    typeof e.comment === "string" &&
                    (e.comment as string).trim().length > 0,
                )
                .map((e, i) => (
                  <div
                    key={i}
                    className="rounded-2xl border border-[#3a324a14] bg-white px-3.5 py-3"
                  >
                    <div className="mb-1 flex items-center gap-2">
                      <span className="text-[11px] font-bold text-[#3a324a]">
                        @{handlesById.get(e.rater_id as string) ?? "?"}
                      </span>
                      <span className="text-[10.5px] tabular-nums text-[#3a324a8c]">
                        {"★".repeat(e.stars as number)}
                        <span className="text-[#3a324a14]">
                          {"★".repeat(5 - (e.stars as number))}
                        </span>
                      </span>
                      <div className="flex-1" />
                      <span className="text-[10px] text-[#3a324a8c]">
                        {formatDate(e.created_at as string)}
                      </span>
                    </div>
                    <pre className="whitespace-pre-wrap break-words text-[12px] leading-relaxed text-[#3a324a]">
                      {e.comment as string}
                    </pre>
                  </div>
                ))}
              {all.filter(
                (e) =>
                  typeof e.comment === "string" &&
                  (e.comment as string).trim().length > 0,
              ).length === 0 && (
                <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-6 text-center text-[11px] text-[#3a324a8c]">
                  コメント付きの評価はまだありません
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </main>
  );
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(2, "0")}/${String(d.getDate()).padStart(2, "0")}`;
}
