import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { PrimaryLinkButton } from "@/components/auth/PrimaryButton";

export const metadata = {
  title: "Megrum へようこそ — Megrum",
};

type OshiRow = {
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  oshi_request: { requested_name: string } | { requested_name: string }[] | null;
  character_request:
    | { requested_name: string }
    | { requested_name: string }[]
    | null;
};

function pickOne<T>(v: T | T[] | null): T | null {
  if (!v) return null;
  return Array.isArray(v) ? (v[0] ?? null) : v;
}

function buildOshiSummary(
  rows: OshiRow[],
): { groupName: string; members: string }[] {
  const map = new Map<string, { groupName: string; members: string[] }>();

  for (const r of rows) {
    const grp = pickOne(r.group);
    const ch = pickOne(r.character);
    const oshiReq = pickOne(r.oshi_request);
    const chReq = pickOne(r.character_request);

    const groupName = grp?.name ?? oshiReq?.requested_name ?? "?";
    const memberName = ch?.name ?? chReq?.requested_name ?? null;

    const entry = map.get(groupName) ?? { groupName, members: [] };
    if (memberName) {
      entry.members.push(memberName);
    }
    map.set(groupName, entry);
  }

  return Array.from(map.values()).map(({ groupName, members }) => ({
    groupName,
    members: members.length > 0 ? members.join(" / ") : "箱推し",
  }));
}

const NEXT_ACTIONS = [
  {
    icon: "🔍",
    label: "マッチを探す",
    sub: "ホーム画面で交換相手を見つける",
    href: "/",
  },
  {
    icon: "📦",
    label: "在庫を登録する",
    sub: "グッズを撮影して登録",
    href: "/",
  },
  {
    icon: "⭐",
    label: "wish を登録する",
    sub: "欲しいグッズを登録",
    href: "/",
  },
];

/**
 * オンボーディング完了画面（モックアップ AOOnboardDone 準拠）
 */
export default async function DonePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 並列取得
  const [{ data: profile }, { data: oshiList }] = await Promise.all([
    supabase
      .from("users")
      .select("handle, display_name, primary_area")
      .eq("id", user.id)
      .maybeSingle(),
    supabase
      .from("user_oshi")
      .select(
        "priority, group:groups_master(name), character:characters_master(name), oshi_request:oshi_requests(requested_name), character_request:character_requests(requested_name)",
      )
      .eq("user_id", user.id)
      .order("priority", { ascending: true }),
  ]);

  const oshiSummary = buildOshiSummary((oshiList as OshiRow[]) ?? []);
  const areas = profile?.primary_area
    ? profile.primary_area
        .split(",")
        .map((s: string) => s.trim())
        .filter(Boolean)
    : [];

  return (
    <main className="flex flex-1 flex-col bg-[linear-gradient(180deg,#a695d822_0%,#a8d4e614_50%,#ffffff_100%)] px-5 pb-8 pt-14">
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col">
        {/* 中央コンテンツ */}
        <div className="flex flex-1 flex-col items-center text-center">
          <div className="text-5xl">✨</div>
          <h1 className="mt-3 text-[26px] font-extrabold text-gray-900">
            Megrum へようこそ！
          </h1>
          <p className="mt-2 text-[13px] leading-relaxed text-gray-500">
            <strong className="font-bold text-gray-700">
              @{profile?.handle ?? "you"}
            </strong>{" "}
            さんのプロフィール設定が完了しました
          </p>

          {/* サマリーボックス */}
          <div className="mt-6 w-full rounded-2xl border border-[#3a324a14] bg-white px-4 py-4">
            <div className="mb-2 text-[11px] font-bold text-gray-500">
              あなたの設定
            </div>
            {oshiSummary.length > 0 ? (
              <div className="space-y-1">
                {oshiSummary.slice(0, 3).map((o, i) => (
                  <div key={i} className="flex items-center gap-2 text-[13px]">
                    <span className="text-[10px] font-bold text-gray-500">
                      推し
                    </span>
                    <span className="font-bold text-gray-900">
                      {o.groupName}
                    </span>
                    <span className="text-gray-400">·</span>
                    <span className="text-gray-700">{o.members}</span>
                  </div>
                ))}
                {oshiSummary.length > 3 && (
                  <div className="text-[11px] text-gray-500">
                    ほか {oshiSummary.length - 3} 件
                  </div>
                )}
              </div>
            ) : (
              <div className="text-[12px] text-gray-500">推し未設定</div>
            )}
            <div className="mt-2 flex items-center gap-2 text-[13px]">
              <span className="text-[10px] font-bold text-gray-500">
                エリア
              </span>
              <span className="font-medium text-gray-700">
                {areas.length > 0 ? areas.join(" / ") : "未設定（あとで設定可）"}
              </span>
            </div>
          </div>

          {/* 次は何をする？ */}
          <div className="mt-6 w-full">
            <div className="mb-2 text-left text-[11px] font-bold text-gray-500">
              次は何をする？
            </div>
            <div className="space-y-2">
              {NEXT_ACTIONS.map((a, i) => (
                <Link
                  key={i}
                  href={a.href}
                  className="flex items-center gap-3 rounded-xl border border-[#3a324a14] bg-white px-3.5 py-3 text-left transition-all duration-150 active:scale-[0.99]"
                >
                  <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-[10px] bg-[linear-gradient(135deg,#a695d822,#a8d4e622)] text-lg">
                    {a.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-[13px] font-bold text-gray-900">
                      {a.label}
                    </div>
                    <div className="mt-0.5 text-[11px] text-gray-500">
                      {a.sub}
                    </div>
                  </div>
                  <svg
                    width="8"
                    height="14"
                    viewBox="0 0 8 14"
                    fill="none"
                    stroke="#6b6478"
                    strokeWidth="1.4"
                  >
                    <path d="M1 1l6 6-6 6" />
                  </svg>
                </Link>
              ))}
            </div>
          </div>
        </div>

        {/* 進む */}
        <div className="mt-6">
          <PrimaryLinkButton href="/">ホームに進む</PrimaryLinkButton>
        </div>
      </div>
    </main>
  );
}
