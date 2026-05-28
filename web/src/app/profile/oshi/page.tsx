import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { OshiEditView } from "./OshiEditView";

export const metadata = {
  title: "推し設定 — Megrum",
};

type OshiRow = {
  id: string;
  group_id: string | null;
  character_id: string | null;
  oshi_request_id: string | null;
  character_request_id: string | null;
  kind: "box" | "specific" | "multi";
  priority: number;
  group: { id: string; name: string } | { id: string; name: string }[] | null;
  character:
    | { id: string; name: string }
    | { id: string; name: string }[]
    | null;
  oshi_request:
    | { id: string; requested_name: string }
    | { id: string; requested_name: string }[]
    | null;
  character_request:
    | { id: string; requested_name: string }
    | { id: string; requested_name: string }[]
    | null;
};

type GenreRow = {
  id: string;
  name: string;
};

type CharacterRow = {
  id: string;
  name: string;
  group_id: string | null;
};

type MasterGroupRow = {
  id: string;
  name: string;
  aliases: string[] | null;
  kind: string;
  display_order: number;
  genre:
    | { id: string; name: string; kind: string }
    | { id: string; name: string; kind: string }[]
    | null;
};

function pickOne<T>(v: T | T[] | null): T | null {
  if (!v) return null;
  return Array.isArray(v) ? (v[0] ?? null) : v;
}

const MASTER_CHARACTER_PAGE_SIZE = 1000;

async function fetchAllMasterCharacters(
  supabase: Awaited<ReturnType<typeof createClient>>,
): Promise<CharacterRow[]> {
  const rows: CharacterRow[] = [];
  for (let from = 0; ; from += MASTER_CHARACTER_PAGE_SIZE) {
    const { data, error } = await supabase
      .from("characters_master")
      .select("id, name, group_id")
      .order("display_order", { ascending: true })
      .order("name", { ascending: true })
      .range(from, from + MASTER_CHARACTER_PAGE_SIZE - 1);
    if (error) throw error;
    const page = (data as CharacterRow[] | null) ?? [];
    rows.push(...page);
    if (page.length < MASTER_CHARACTER_PAGE_SIZE) break;
  }
  return rows;
}

type Props = {
  searchParams: Promise<{ request?: string }>;
};

export default async function ProfileOshiPage({ searchParams }: Props) {
  const params = await searchParams;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 自分の推し + 関連 master + 追加リクエスト用 genre を並列取得
  const [
    { data: oshi },
    characters,
    { data: genres },
    { data: masterGroups },
  ] = await Promise.all([
    supabase
      .from("user_oshi")
      .select(
        "id, group_id, character_id, oshi_request_id, character_request_id, kind, priority, group:groups_master(id, name), character:characters_master(id, name), oshi_request:oshi_requests(id, requested_name), character_request:character_requests(id, requested_name)",
      )
      .eq("user_id", user.id)
      .order("priority", { ascending: true }),
    fetchAllMasterCharacters(supabase),
    supabase
      .from("genres_master")
      .select("id, name")
      .order("display_order", { ascending: true }),
    supabase
      .from("groups_master")
      .select(
        "id, name, aliases, kind, display_order, genre:genres_master(id, name, kind)",
      )
      .order("display_order", { ascending: true }),
  ]);

  // グループごとにまとめる
  type GroupSource = "master" | "request";
  type Member = {
    id: string;
    name: string;
    source: "master" | "request";
  };
  type Group = {
    groupId: string;
    source: GroupSource;
    groupName: string;
    priority: number;
    members: Member[];
    availableCharacters: { id: string; name: string }[];
  };

  const groupMap = new Map<string, Group>();
  for (const row of (oshi as OshiRow[]) ?? []) {
    const grp = pickOne(row.group);
    const oshiReq = pickOne(row.oshi_request);
    const source: GroupSource | null = row.group_id
      ? "master"
      : row.oshi_request_id
        ? "request"
        : null;
    const groupId = row.group_id ?? row.oshi_request_id;
    const groupName = grp?.name ?? oshiReq?.requested_name;
    if (!source || !groupId || !groupName) continue;

    const mapKey = `${source}:${groupId}`;
    if (!groupMap.has(mapKey)) {
      groupMap.set(mapKey, {
        groupId,
        source,
        groupName,
        priority: row.priority,
        members: [],
        availableCharacters: [],
      });
    } else {
      groupMap.get(mapKey)!.priority = Math.min(
        groupMap.get(mapKey)!.priority,
        row.priority,
      );
    }

    if (row.character_id) {
      const ch = pickOne(row.character);
      if (ch) {
        groupMap.get(mapKey)!.members.push({
          id: row.character_id,
          name: ch.name,
          source: "master",
        });
      }
    }

    if (row.character_request_id) {
      const chReq = pickOne(row.character_request);
      if (chReq) {
        groupMap.get(mapKey)!.members.push({
          id: row.character_request_id,
          name: chReq.requested_name,
          source: "request",
        });
      }
    }
  }

  // availableCharacters: 各グループの全キャラから、すでに登録済みのキャラを除外
  for (const group of groupMap.values()) {
    if (group.source !== "master") continue;
    const memberIds = new Set(
      group.members
        .filter((m) => m.source === "master")
        .map((m) => m.id),
    );
    group.availableCharacters = (characters ?? [])
      .filter(
        (c) => c.group_id === group.groupId && !memberIds.has(c.id),
      )
      .map((c) => ({ id: c.id, name: c.name }));
  }

  const oshiGroups = Array.from(groupMap.values()).sort(
    (a, b) =>
      a.priority - b.priority ||
      a.groupName.localeCompare(b.groupName, "ja"),
  );
  const charactersByGroup = new Map<
    string,
    { id: string; name: string }[]
  >();
  for (const c of characters) {
    if (!c.group_id) continue;
    const list = charactersByGroup.get(c.group_id) ?? [];
    list.push({ id: c.id, name: c.name });
    charactersByGroup.set(c.group_id, list);
  }

  const masterOptions = ((masterGroups as MasterGroupRow[] | null) ?? [])
    .map((g) => {
      const genre = pickOne(g.genre);
      if (!genre) return null;
      return {
        id: g.id,
        name: g.name,
        aliases: g.aliases ?? [],
        kind: g.kind as "group" | "work" | "solo",
        displayOrder: g.display_order,
        genreId: genre.id,
        genreName: genre.name,
        genreKind: genre.kind as "idol" | "anime" | "game" | "other",
        characters: charactersByGroup.get(g.id) ?? [],
      };
    })
    .filter((g): g is NonNullable<typeof g> => !!g);

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="推し設定" backHref="/profile" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-12 pt-5">
        <OshiEditView
          oshiGroups={oshiGroups}
          initialRequestModal={params.request === "oshi"}
          genreOptions={((genres as GenreRow[] | null) ?? []).map((g) => ({
            id: g.id,
            name: g.name,
          }))}
          masterOptions={masterOptions}
        />
      </div>
    </main>
  );
}
