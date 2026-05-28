import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { OshiForm, type OshiOption, type GenreOption } from "./OshiForm";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ProgressDots } from "@/components/auth/ProgressDots";

export const metadata = {
  title: "プロフィール設定 — Megrum",
};

/**
 * オンボーディング 2/4: 推し選択（モックアップ AOOnboardGroup 準拠）
 *
 * - groups_master + genres_master をジャンル横断で取得
 * - ジャンルチップでフィルタ + 名前/aliases 検索
 * - 複数選択可、選択順に user_oshi に priority を振る（kind=box でメンバー未選択状態）
 */
type Props = {
  searchParams: Promise<{ return?: string }>;
};

export default async function OshiPage({ searchParams }: Props) {
  const params = await searchParams;
  const returnTo = params.return;
  const isProfileReturn = returnTo === "profile";
  const backHref = isProfileReturn ? "/profile/oshi" : "/onboarding/gender";
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 4 つの DB クエリを並列実行（順次待つと 4×RTT、並列なら 1×RTT）
  const [
    { data: genres },
    { data: groups },
    { data: existingOshi },
    { data: pendingRequestsRaw },
  ] = await Promise.all([
    supabase
      .from("genres_master")
      .select("id, name, kind, display_order")
      .order("display_order", { ascending: true }),
    supabase
      .from("groups_master")
      .select(
        "id, name, aliases, kind, display_order, genre:genres_master(id, name, kind)",
      )
      .order("display_order", { ascending: true }),
    supabase
      .from("user_oshi")
      .select("group_id, oshi_request_id, priority")
      .eq("user_id", user.id)
      .order("priority", { ascending: true }),
    supabase
      .from("oshi_requests")
      .select(
        "id, requested_name, requested_kind, status, user_id, created_at, genre:genres_master(id, name)",
      )
      .eq("status", "pending")
      .order("created_at", { ascending: false }),
  ]);

  const initialSelectedGroupIds: string[] = (existingOshi ?? [])
    .filter((o): o is { group_id: string; oshi_request_id: null; priority: number } =>
      !!o.group_id,
    )
    .map((o) => o.group_id);

  const initialSelectedRequestIds: string[] = (existingOshi ?? [])
    .filter(
      (o): o is { group_id: null; oshi_request_id: string; priority: number } =>
        !!o.oshi_request_id,
    )
    .map((o) => o.oshi_request_id);

  const pendingRequests = (pendingRequestsRaw ?? []).map((r) => {
    const genre = Array.isArray(r.genre) ? r.genre[0] : r.genre;
    return {
      id: r.id,
      name: r.requested_name,
      kind: r.requested_kind as "group" | "work" | "solo" | null,
      genre_id: genre?.id ?? null,
      genre_name: genre?.name ?? null,
      isMine: r.user_id === user.id,
    };
  });

  // OshiOption に変換
  const oshiOptions: OshiOption[] = (groups ?? [])
    .filter((g): g is typeof g & { genre: NonNullable<typeof g.genre> } =>
      Array.isArray(g.genre) ? g.genre.length > 0 : !!g.genre,
    )
    .map((g) => {
      const genre = Array.isArray(g.genre) ? g.genre[0] : g.genre;
      return {
        id: g.id,
        name: g.name,
        aliases: g.aliases ?? [],
        kind: g.kind as "group" | "work" | "solo",
        display_order: g.display_order,
        genre_id: genre.id,
        genre_name: genre.name,
        genre_kind: genre.kind as "idol" | "anime" | "game" | "other",
      };
    });

  const genreOptions: GenreOption[] = (genres ?? []).map((g) => ({
    id: g.id,
    name: g.name,
    kind: g.kind as "idol" | "anime" | "game" | "other",
  }));

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title={isProfileReturn ? "推しを追加" : "プロフィール設定"}
        sub="あなたの推し（複数選択可）"
        progress={isProfileReturn ? undefined : "2/4"}
        backHref={backHref}
      />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-6">
        {!isProfileReturn && <ProgressDots current={1} total={4} />}
        <h2
          className={`${isProfileReturn ? "mt-0" : "mt-4"} text-[22px] font-extrabold leading-tight text-gray-900`}
        >
          {isProfileReturn ? "追加する推しは？" : "推しは？"}
        </h2>
        <p className="mt-2 text-xs leading-relaxed text-gray-500">
          グループ・作品・配信者など、ジャンル横断で選べます
        </p>
        <OshiForm
          oshiOptions={oshiOptions}
          genreOptions={genreOptions}
          initialSelectedGroupIds={initialSelectedGroupIds}
          initialSelectedRequestIds={initialSelectedRequestIds}
          pendingRequests={pendingRequests}
        />
      </div>
    </main>
  );
}
