"use client";

/**
 * iter82: 検索画面（search-filter.jsx の SearchScreen 準拠）
 *
 * - 検索バー（form submit で ?q=... に遷移）
 * - フィルタチップ（active）— フィルタ画面実装は次イテで詳細
 * - 結果カード：avatar + handle + 距離/★/取引/推し + マッチバッジ + 譲タイトル
 * - 履歴 / 人気の検索（履歴は localStorage に簡易保存、人気はサーバ固定）
 */

import Link from "next/link";
import { useEffect, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";

export type SearchHit = {
  id: string;
  userId: string;
  userHandle: string;
  userDisplayName: string;
  primaryArea: string | null;
  ratingAvg: number | null;
  ratingCount: number;
  title: string;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  wishHit: boolean;
};

const RECENT_KEY = "megrum-search-recent-v1";
const RECENT_MAX = 6;

export function SearchView({
  query,
  hits,
  popularKeywords,
}: {
  query: string;
  hits: SearchHit[];
  popularKeywords: string[];
}) {
  const router = useRouter();
  const [draft, setDraft] = useState(query);
  const [recent, setRecent] = useState<string[]>([]);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(RECENT_KEY);
      if (raw) {
        const parsed: unknown = JSON.parse(raw);
        if (Array.isArray(parsed))
          setRecent(parsed.filter((x): x is string => typeof x === "string"));
      }
    } catch {
      // ignore
    }
  }, []);

  // クエリが変わったら履歴に追加
  useEffect(() => {
    if (!query) return;
    setRecent((prev) => {
      const filtered = prev.filter((q) => q !== query);
      const next = [query, ...filtered].slice(0, RECENT_MAX);
      try {
        localStorage.setItem(RECENT_KEY, JSON.stringify(next));
      } catch {
        // ignore
      }
      return next;
    });
  }, [query]);

  function submit(e?: FormEvent) {
    e?.preventDefault();
    const q = draft.trim();
    if (!q) return;
    router.push(`/search?q=${encodeURIComponent(q)}`);
  }

  function jumpTo(q: string) {
    setDraft(q);
    router.push(`/search?q=${encodeURIComponent(q)}`);
  }

  function clearQuery() {
    setDraft("");
    router.push("/search");
  }

  return (
    <div className="space-y-3">
      {/* 検索バー */}
      <form onSubmit={submit}>
        <div className="flex items-center gap-2.5 rounded-[12px] border border-[#3a324a14] bg-white px-3.5 py-[11px]">
          <svg
            width="16"
            height="16"
            viewBox="0 0 16 16"
            fill="none"
            stroke="#3a324a8c"
            strokeWidth="1.6"
          >
            <circle cx="7" cy="7" r="5" />
            <path d="M11 11l4 4" />
          </svg>
          <input
            type="text"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            placeholder="例：スア トレカ / WORLD TOUR"
            className="flex-1 bg-transparent text-[16px] text-[#3a324a] outline-none placeholder:text-[#3a324a4d]"
            enterKeyHint="search"
          />
          {draft && (
            <button
              type="button"
              onClick={clearQuery}
              aria-label="クリア"
              className="text-[#3a324a8c]"
            >
              <svg
                width="14"
                height="14"
                viewBox="0 0 14 14"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.4"
              >
                <line x1="3" y1="3" x2="11" y2="11" />
                <line x1="11" y1="3" x2="3" y2="11" />
              </svg>
            </button>
          )}
        </div>
      </form>

      {/* 検索結果 or 履歴・人気 */}
      {query ? (
        <ResultsList hits={hits} query={query} />
      ) : (
        <SuggestionsSection
          recent={recent}
          popular={popularKeywords}
          onJump={jumpTo}
        />
      )}
    </div>
  );
}

/* ─── 検索結果リスト ─── */

function ResultsList({ hits, query }: { hits: SearchHit[]; query: string }) {
  // 完全マッチ → その他 の順にソート
  const sorted = [...hits].sort((a, b) => {
    if (a.wishHit !== b.wishHit) return a.wishHit ? -1 : 1;
    return 0;
  });

  return (
    <div>
      <div className="mb-2 flex items-center justify-between px-1">
        <div className="text-[12px] text-[#3a324a8c]">
          <b className="text-[14px] text-[#3a324a]">{sorted.length}件</b>{" "}
          ヒット
          {query && (
            <span className="ml-1 text-[10px] text-[#3a324a8c]">
              ・「{query}」
            </span>
          )}
        </div>
      </div>
      {sorted.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-10 text-center text-[12px] text-[#3a324a8c]">
          該当する出品が見つかりませんでした
        </div>
      ) : (
        <div className="space-y-2.5">
          {sorted.map((h) => (
            <HitCard key={h.id} hit={h} />
          ))}
        </div>
      )}
    </div>
  );
}

function HitCard({ hit }: { hit: SearchHit }) {
  const memberName =
    hit.characterName ?? hit.groupName ?? hit.title ?? "?";
  const hue =
    Math.abs([...memberName].reduce((s, c) => s + c.charCodeAt(0), 0)) % 360;
  const stripeBg = `repeating-linear-gradient(135deg, hsl(${hue}, 28%, 84%) 0 5px, hsl(${hue}, 28%, 76%) 5px 10px)`;

  return (
    <Link
      href={`/users/${hit.userId}`}
      className="block overflow-hidden rounded-[14px] border border-[#3a324a14] bg-white p-3.5 active:scale-[0.99]"
    >
      {/* user 行 */}
      <div className="mb-2.5 flex items-center gap-2.5">
        <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-[linear-gradient(135deg,#a695d855,#a8d4e655)] text-[12px] font-extrabold text-[#3a324a]">
          {hit.userDisplayName[0] || "?"}
        </div>
        <div className="min-w-0 flex-1">
          <div className="text-[13px] font-bold text-[#3a324a]">
            @{hit.userHandle}
          </div>
          <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">
            {hit.primaryArea ?? "—"}
            {hit.ratingAvg !== null && (
              <>
                ・★{hit.ratingAvg.toFixed(1)}
                <span className="ml-0.5 text-[9.5px]">
                  ({hit.ratingCount})
                </span>
              </>
            )}
          </div>
        </div>
        {hit.wishHit ? (
          <span
            className="rounded-full px-2 py-[3px] text-[9px] font-extrabold tracking-[0.3px] text-white"
            style={{
              background: "linear-gradient(135deg, #a695d8, #f3c5d4)",
            }}
          >
            wish 候補
          </span>
        ) : (
          <span className="rounded-full bg-emerald-500 px-2 py-[3px] text-[9px] font-extrabold tracking-[0.3px] text-white">
            出品中
          </span>
        )}
      </div>

      {/* 譲アイテムプレビュー */}
      <div className="flex items-center gap-2.5 rounded-[10px] bg-[#fbf9fc] px-3 py-2">
        <div
          className="relative flex h-[44px] w-[32px] flex-shrink-0 items-center justify-center overflow-hidden rounded-[5px] border border-white/60 shadow-[0_1px_3px_rgba(58,50,74,0.15)]"
          style={{ background: hit.photoUrl ? "#3a324a" : stripeBg }}
        >
          {hit.photoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={hit.photoUrl}
              alt={hit.title}
              className="absolute inset-0 h-full w-full object-cover"
              loading="lazy"
            />
          ) : (
            <span
              className="text-[14px] font-extrabold text-white/95"
              style={{
                textShadow: `0 1px 2px hsla(${hue}, 30%, 30%, 0.5)`,
              }}
            >
              {memberName[0] || "?"}
            </span>
          )}
        </div>
        <div className="min-w-0 flex-1">
          <div className="truncate text-[12px] font-bold text-[#3a324a]">
            譲：{hit.title}
          </div>
          <div className="mt-0.5 truncate text-[10.5px] text-[#3a324a8c]">
            {[hit.groupName, hit.characterName, hit.goodsTypeName]
              .filter(Boolean)
              .join(" ・ ")}
          </div>
        </div>
        <span className="text-[12px] text-[#a695d8]">›</span>
      </div>
    </Link>
  );
}

/* ─── 履歴 + 人気の検索 ─── */

function SuggestionsSection({
  recent,
  popular,
  onJump,
}: {
  recent: string[];
  popular: string[];
  onJump: (q: string) => void;
}) {
  return (
    <div className="space-y-3">
      {recent.length > 0 && (
        <div>
          <div className="mb-1.5 px-1 text-[11px] font-bold tracking-[0.4px] text-[#3a324a8c]">
            履歴
          </div>
          <div className="flex flex-wrap gap-1.5">
            {recent.map((q) => (
              <button
                key={q}
                type="button"
                onClick={() => onJump(q)}
                className="inline-flex items-center gap-1 rounded-full border border-[#3a324a14] bg-white px-3 py-1.5 text-[11.5px] font-semibold text-[#3a324a]"
              >
                <span className="text-[10px]">🕐</span>
                {q}
              </button>
            ))}
          </div>
        </div>
      )}
      <div>
        <div className="mb-1.5 px-1 text-[11px] font-bold tracking-[0.4px] text-[#3a324a8c]">
          人気の検索
        </div>
        <div className="flex flex-wrap gap-1.5">
          {popular.map((q) => (
            <button
              key={q}
              type="button"
              onClick={() => onJump(q)}
              className="inline-flex items-center gap-1 rounded-full border border-[#3a324a14] bg-white px-3 py-1.5 text-[11.5px] font-semibold text-[#3a324a]"
            >
              {q}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
