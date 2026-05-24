"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { saveOshi } from "@/app/onboarding/actions";
import { PrimaryButton } from "@/components/auth/PrimaryButton";

export type OshiOption = {
  id: string;
  name: string;
  aliases: string[];
  kind: "group" | "work" | "solo";
  display_order: number;
  genre_id: string;
  genre_name: string;
  genre_kind: "idol" | "anime" | "game" | "other";
};

export type GenreOption = {
  id: string;
  name: string;
  kind: "idol" | "anime" | "game" | "other";
};

export type PendingRequest = {
  id: string;
  name: string;
  kind: "group" | "work" | "solo" | null;
  genre_id: string | null;
  genre_name: string | null;
  isMine: boolean;
};

// 「人気」バッジを付ける group の上位件数（display_order 小 = 人気）
const POPULAR_TOP_N = 5;

// kind とジャンルから sub テキストを生成（例: "K-POP・グループ"）
function buildSubText(o: OshiOption): string {
  const kindLabel =
    o.kind === "group"
      ? "グループ"
      : o.kind === "work"
        ? "作品"
        : "ソロ";
  return `${o.genre_name}・${kindLabel}`;
}

// 名前が英字主体かを判定（フォント切替に使う）
function isLatin(name: string): boolean {
  return /^[A-Za-z0-9\s\-_!&]+$/.test(name);
}

export function OshiForm({
  oshiOptions,
  genreOptions,
  initialSelectedGroupIds,
  initialSelectedRequestIds,
  pendingRequests,
}: {
  oshiOptions: OshiOption[];
  genreOptions: GenreOption[];
  initialSelectedGroupIds: string[];
  initialSelectedRequestIds: string[];
  pendingRequests: PendingRequest[];
}) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const returnTo = searchParams?.get("return");
  const isProfileReturn = returnTo === "profile";
  // ?return=profile で来た場合、保存後はプロフ推し設定画面に戻る
  const destAfterSave = isProfileReturn
    ? "/profile/oshi"
    : "/onboarding/members";
  const requestHref = isProfileReturn
    ? "/profile/oshi?request=oshi"
    : "/onboarding/oshi/request";
  const [selectedGroupIds, setSelectedGroupIds] = useState<string[]>(
    initialSelectedGroupIds,
  );
  const [selectedRequestIds, setSelectedRequestIds] = useState<string[]>(
    initialSelectedRequestIds,
  );
  const [filterGenreId, setFilterGenreId] = useState<string | "all">("all");
  const [search, setSearch] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const totalSelected =
    selectedGroupIds.length + selectedRequestIds.length;

  // 次画面を事前ロード
  useEffect(() => {
    router.prefetch(destAfterSave);
    router.prefetch(requestHref);
  }, [router, destAfterSave, requestHref]);

  // 「人気」判定: 各ジャンル内の上位N件
  const popularSet = useMemo(() => {
    const byGenre: Record<string, OshiOption[]> = {};
    for (const o of oshiOptions) {
      (byGenre[o.genre_id] ??= []).push(o);
    }
    const set = new Set<string>();
    for (const arr of Object.values(byGenre)) {
      arr
        .sort((a, b) => a.display_order - b.display_order)
        .slice(0, POPULAR_TOP_N)
        .forEach((o) => set.add(o.id));
    }
    return set;
  }, [oshiOptions]);

  // フィルタリング（既存マスタ）
  const filtered = useMemo(() => {
    return oshiOptions.filter((o) => {
      if (filterGenreId !== "all" && o.genre_id !== filterGenreId)
        return false;
      if (search.trim()) {
        const q = search.trim().toLowerCase();
        if (
          !o.name.toLowerCase().includes(q) &&
          !o.aliases.some((a) => a.toLowerCase().includes(q))
        )
          return false;
      }
      return true;
    });
  }, [oshiOptions, filterGenreId, search]);

  // 審査中アイテムも同じフィルタ条件で絞る（誰でも選択可）
  const filteredPendingRequests = useMemo(() => {
    return pendingRequests.filter((r) => {
      if (filterGenreId !== "all" && r.genre_id !== filterGenreId)
        return false;
      if (search.trim()) {
        const q = search.trim().toLowerCase();
        if (!r.name.toLowerCase().includes(q)) return false;
      }
      return true;
    });
  }, [pendingRequests, filterGenreId, search]);

  function toggleGroup(id: string) {
    setSelectedGroupIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
    );
  }

  function toggleRequest(id: string) {
    setSelectedRequestIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
    );
  }

  async function handleSubmit() {
    if (totalSelected === 0) {
      setError("推しを 1 つ以上選択してください");
      return;
    }
    setPending(true);
    setError(null);
    const result = await saveOshi({
      groupIds: selectedGroupIds,
      requestIds: selectedRequestIds,
    });
    if (result?.error) {
      setPending(false);
      setError(result.error);
      return;
    }
    router.push(destAfterSave);
  }

  return (
    <div className="mt-4 flex flex-1 flex-col">
      {/* 検索バー */}
      <div className="mb-3 flex items-center gap-2 rounded-xl border border-[#3a324a14] bg-white px-3.5 py-3">
        <svg
          width="14"
          height="14"
          viewBox="0 0 14 14"
          fill="none"
          stroke="#6b6478"
          strokeWidth="1.4"
        >
          <circle cx="6" cy="6" r="4.5" />
          <path d="M9.5 9.5L13 13" />
        </svg>
        <input
          type="text"
          placeholder="グループ名・作品名で検索"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 bg-transparent text-[13px] text-gray-900 placeholder:text-gray-500 focus:outline-none"
        />
      </div>

      {/* ジャンルチップ */}
      <div className="-mx-5 mb-3 flex gap-1.5 overflow-x-auto px-5 pb-1 [&::-webkit-scrollbar]:hidden">
        <ChipButton
          label="すべて"
          active={filterGenreId === "all"}
          onClick={() => setFilterGenreId("all")}
        />
        {genreOptions.map((g) => (
          <ChipButton
            key={g.id}
            label={g.name}
            active={filterGenreId === g.id}
            onClick={() => setFilterGenreId(g.id)}
          />
        ))}
      </div>

      {/* 推しカードリスト */}
      <div className="flex-1 space-y-2 overflow-y-auto pb-4">
        {filtered.length === 0 ? (
          <div className="rounded-xl border border-dashed border-[#3a324a14] py-6 text-center text-xs text-gray-500">
            該当する推しが見つかりません
          </div>
        ) : (
          filtered.map((o) => {
            const active = selectedGroupIds.includes(o.id);
            const popular = popularSet.has(o.id);
            const latin = isLatin(o.name);
            return (
              <button
                key={o.id}
                type="button"
                onClick={() => toggleGroup(o.id)}
                className={`flex w-full items-center gap-3 rounded-2xl border-[1.5px] border-solid px-4 py-3.5 text-left transition-all duration-150 active:scale-[0.99] ${
                  active
                    ? "border-[#a695d8] bg-[#a695d814]"
                    : "border-[#3a324a14] bg-white hover:border-[#3a324a26]"
                }`}
              >
                {/* 名前 + サブ */}
                <div className="flex-1 min-w-0">
                  <div
                    className="text-sm font-bold text-gray-900"
                    style={
                      latin
                        ? {
                            fontFamily:
                              "var(--font-inter-tight), system-ui",
                            letterSpacing: "0.3px",
                          }
                        : undefined
                    }
                  >
                    {o.name}
                    {popular && (
                      <span className="ml-2 text-[9px] font-bold text-[#d4866b]">
                        人気
                      </span>
                    )}
                  </div>
                  <div className="mt-0.5 text-[11px] text-gray-500">
                    {buildSubText(o)}
                  </div>
                </div>

                {/* チェック円 */}
                <div
                  className={`flex h-[22px] w-[22px] flex-shrink-0 items-center justify-center rounded-full border-[1.8px] border-solid ${
                    active
                      ? "border-[#a695d8] bg-[#a695d8]"
                      : "border-[#3a324a14] bg-white"
                  }`}
                >
                  {active && (
                    <svg width="11" height="11" viewBox="0 0 11 11">
                      <path
                        d="M2 5.5l2.5 2.5L9 3"
                        stroke="#fff"
                        strokeWidth="1.8"
                        fill="none"
                        strokeLinecap="round"
                      />
                    </svg>
                  )}
                </div>
              </button>
            );
          })
        )}

        {/* 審査中の推し（共有・誰でも選択可） */}
        {filteredPendingRequests.length > 0 && (
          <>
            <div className="mt-4 mb-1 text-[11px] font-bold text-gray-500">
              審査中の推し（運営確認待ち・選択可）
            </div>
            {filteredPendingRequests.map((r) => {
              const active = selectedRequestIds.includes(r.id);
              const latin = isLatin(r.name);
              const subParts: string[] = [];
              if (r.genre_name) subParts.push(r.genre_name);
              if (r.kind === "group") subParts.push("グループ");
              else if (r.kind === "work") subParts.push("作品");
              else if (r.kind === "solo") subParts.push("ソロ");
              return (
                <button
                  key={r.id}
                  type="button"
                  onClick={() => toggleRequest(r.id)}
                  className={`flex w-full items-center gap-3 rounded-2xl border-[1.5px] border-dashed px-4 py-3.5 text-left transition-all duration-150 active:scale-[0.99] ${
                    active
                      ? "border-[#a695d8] bg-[#a695d814]"
                      : "border-[#3a324a26] bg-white hover:border-[#3a324a40]"
                  }`}
                >
                  {/* 名前 + サブ + バッジ */}
                  <div className="flex-1 min-w-0">
                    <div
                      className="text-sm font-bold text-gray-900"
                      style={
                        latin
                          ? {
                              fontFamily:
                                "var(--font-inter-tight), system-ui",
                              letterSpacing: "0.3px",
                            }
                          : undefined
                      }
                    >
                      {r.name}
                      <span className="ml-2 rounded-full bg-[#a695d822] px-1.5 py-0.5 text-[9px] font-bold text-[#a695d8]">
                        審査中
                      </span>
                      {r.isMine && (
                        <span className="ml-1 text-[9px] font-bold text-[#d4866b]">
                          あなたが申請
                        </span>
                      )}
                    </div>
                    <div className="mt-0.5 text-[11px] text-gray-500">
                      {subParts.length > 0
                        ? subParts.join("・")
                        : "ジャンル指定なし"}
                    </div>
                  </div>

                  {/* チェック円 */}
                  <div
                    className={`flex h-[22px] w-[22px] flex-shrink-0 items-center justify-center rounded-full border-[1.8px] border-solid ${
                      active
                        ? "border-[#a695d8] bg-[#a695d8]"
                        : "border-[#3a324a14] bg-white"
                    }`}
                  >
                    {active && (
                      <svg width="11" height="11" viewBox="0 0 11 11">
                        <path
                          d="M2 5.5l2.5 2.5L9 3"
                          stroke="#fff"
                          strokeWidth="1.8"
                          fill="none"
                          strokeLinecap="round"
                        />
                      </svg>
                    )}
                  </div>
                </button>
              );
            })}
          </>
        )}

        {/* 追加リクエスト枠 */}
        <Link
          href={requestHref}
          className="mt-3 block rounded-xl border border-dashed border-[#a695d855] bg-white py-3 text-center text-xs font-medium text-[#a695d8] transition-colors hover:border-[#a695d8] hover:bg-[#a695d808]"
        >
          + 見つからない場合は運営に追加リクエスト
        </Link>
      </div>

      {error && <p className="mt-3 text-xs text-red-600">{error}</p>}

      <div className="mt-2 pb-1 pt-2">
        <PrimaryButton
          type="button"
          onClick={handleSubmit}
          disabled={totalSelected === 0}
          pending={pending}
          pendingLabel="保存中..."
        >
          {isProfileReturn
            ? `この内容で保存（${totalSelected}件選択中）`
            : `次へ（${totalSelected}件選択中）`}
        </PrimaryButton>
      </div>
    </div>
  );
}

function ChipButton({
  label,
  active,
  onClick,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex-shrink-0 whitespace-nowrap rounded-full border-[1.5px] border-solid px-3.5 py-1.5 text-[12px] transition-all duration-150 active:scale-[0.97] ${
        active
          ? "border-[#a695d8] bg-[#a695d8] font-bold text-white"
          : "border-[#3a324a14] bg-white font-medium text-gray-900 hover:border-[#3a324a26]"
      }`}
    >
      {label}
    </button>
  );
}
