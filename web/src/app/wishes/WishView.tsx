"use client";

/**
 * iter143：WISH 画面を 2 タブ swipe + パネル形式に再設計。
 * iter150：削除フローをカスタムモーダル + フェードアウト + 滑らかな reflow に。
 *
 * - Tab 1「WISH」：マイ在庫と同じ 3 カラム panel グリッド
 *   - 個別募集に紐付けされていない wish には「未紐付け」バッジ + 個別募集作成導線
 *   - 紐付けされている wish には「個別募集 N件」バッジ
 * - Tab 2「個別募集」：既存 ListingsView を再利用
 * - 「マッチ X件 検出中」バナーは廃止（ノイズになっていた）
 */

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { flushSync } from "react-dom";
import { deleteWishItem } from "./actions";
import { ListingsView, type ListingItem } from "../listings/ListingsView";
import {
  ColumnCountButton,
  type ColumnCount,
} from "@/components/common/ColumnCountButton";
import { FloatingAddButton } from "@/components/common/FloatingAddButton";
import { BottomActionSheet } from "@/components/common/BottomActionSheet";
import { useImageReady } from "@/components/common/useImageReady";

export type WishLink = {
  listingId: string;
  status: "active" | "paused" | "matched" | "closed";
};

export type WishItem = {
  id: string;
  title: string;
  note: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string;
  priority: "top" | "second" | "flexible" | null;
  flexLevel: "exact" | "character_any" | "series_any" | null;
  exchangeType: "same_kind" | "cross_kind" | "any";
  quantity: number;
  /** 0–360（ItemCard と同じ着色基準） */
  hue: number;
  createdAt: string; // ISO
  /** メイン画像 URL */
  photoUrl: string | null;
  /** iter143: 紐付け中の個別募集（active/paused/matched） */
  linkedListings: WishLink[];
};

type Tab = "wish" | "listings";
const TAB_IDS: Tab[] = ["wish", "listings"];
const GRID_CLASS_BY_COLUMNS: Record<ColumnCount, string> = {
  3: "grid-cols-3 gap-2.5",
  4: "grid-cols-4 gap-2",
  5: "grid-cols-5 gap-1.5",
};

export function WishView({
  wishItems,
  listingItems,
}: {
  wishItems: WishItem[];
  listingItems: ListingItem[];
}) {
  const [tab, setTab] = useState<Tab>("wish");
  const [columnCount, setColumnCount] = useState<ColumnCount>(3);
  const scrollRef = useRef<HTMLDivElement>(null);

  // スワイプ位置 → タブ同期（debounce 付き）
  useEffect(() => {
    const container = scrollRef.current;
    if (!container) return;
    let frame: number | null = null;
    function onScroll() {
      if (frame) cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        if (!container) return;
        const idx = Math.round(container.scrollLeft / container.clientWidth);
        const next = TAB_IDS[idx];
        if (next && next !== tab) setTab(next);
      });
    }
    container.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      container.removeEventListener("scroll", onScroll);
      if (frame) cancelAnimationFrame(frame);
    };
  }, [tab]);

  function selectTab(target: Tab) {
    setTab(target);
    const container = scrollRef.current;
    if (!container) return;
    const idx = TAB_IDS.indexOf(target);
    container.scrollTo({
      left: idx * container.clientWidth,
      behavior: "smooth",
    });
  }

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc] pb-[88px]">
      {/* ヘッダー（プロフ画面と同じパターン） */}
      <div className="border-b border-[#3a324a14] bg-white px-[18px] pb-3 pt-12">
        <div className="mx-auto flex max-w-md items-center justify-between">
          <h1 className="text-[19px] font-extrabold tracking-wide text-gray-900">
            ウィッシュ
          </h1>
          {tab === "wish" && (
            <ColumnCountButton
              value={columnCount}
              onChange={setColumnCount}
            />
          )}
        </div>
      </div>

      {/* タブバー */}
      <div className="mx-auto w-full max-w-md px-4 pt-2.5">
        <div className="flex gap-1">
          <TabButton
            active={tab === "wish"}
            label="WISH"
            count={wishItems.length}
            onClick={() => selectTab("wish")}
            color="#a695d8"
          />
          <TabButton
            active={tab === "listings"}
            label="個別募集"
            count={listingItems.length}
            onClick={() => selectTab("listings")}
            color="#a8d4e6"
          />
        </div>
      </div>

      {/* スワイプコンテナ */}
      <div
        ref={scrollRef}
        className="mx-auto flex w-full max-w-md flex-1 snap-x snap-mandatory overflow-x-auto overflow-y-hidden [-webkit-overflow-scrolling:touch] [&::-webkit-scrollbar]:hidden"
        style={{ scrollbarWidth: "none" }}
      >
        <WishPanel items={wishItems} columnCount={columnCount} />
        <ListingsPanel items={listingItems} />
      </div>
      <FloatingAddButton
        href={tab === "wish" ? "/wishes/new" : "/listings/new"}
        label={tab === "wish" ? "wish を追加" : "個別募集を追加"}
      />
    </main>
  );
}

function TabButton({
  active,
  label,
  count,
  onClick,
  color,
}: {
  active: boolean;
  label: string;
  count: number;
  onClick: () => void;
  color: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`relative flex flex-1 items-center justify-center gap-1 rounded-xl py-2 transition-all ${
        active
          ? "border-[1.5px] border-solid bg-white"
          : "border-[0.5px] border-solid border-[#3a324a14] bg-[#3a324a08]"
      }`}
      style={{ borderColor: active ? color : undefined }}
    >
      <span
        className={`text-[12px] ${
          active
            ? "font-extrabold text-gray-900"
            : "font-semibold text-gray-500"
        }`}
      >
        {label}
      </span>
      <span
        className="text-[10px] font-bold tabular-nums"
        style={{ color: active ? color : "#6b6478" }}
      >
        {count}
      </span>
    </button>
  );
}

/* ─── Tab 1: WISH パネル一覧 ───────────────────────────── */

function WishPanel({
  items,
  columnCount,
}: {
  items: WishItem[];
  columnCount: ColumnCount;
}) {
  const router = useRouter();
  /**
   * iter150: 削除を「ローカル先行 + サーバー後追い」にして、
   * パネルの fade-out → 他パネルの reflow までスムーズに動かす。
   * - removedIds: 画面上だけ先に消した ID
   * - confirmTarget: 確認モーダル表示中のアイテム
   * - deletingId: フェードアウト中のアイテム ID
   */
  const [removedIds, setRemovedIds] = useState<Set<string>>(() => new Set());
  const visibleItems = items.filter((item) => !removedIds.has(item.id));
  const [confirmTarget, setConfirmTarget] = useState<WishItem | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  function requestDelete(item: WishItem) {
    setConfirmTarget(item);
  }

  async function performDelete(item: WishItem) {
    setConfirmTarget(null);
    setDeletingId(item.id);

    // Stage 1: 「奥に消える」フェードアウト（CSS, 380ms）
    await new Promise((r) => setTimeout(r, 380));

    // Stage 2: View Transitions API で他パネルの reflow を滑らかに
    const update = () => {
      flushSync(() => {
        setRemovedIds((prev) => {
          const next = new Set(prev);
          next.add(item.id);
          return next;
        });
        setDeletingId(null);
      });
    };
    type DocWithVT = Document & {
      startViewTransition?: (cb: () => void) => unknown;
    };
    const doc =
      typeof document !== "undefined" ? (document as DocWithVT) : null;
    if (doc && typeof doc.startViewTransition === "function") {
      // body に class を付けてカスタム VT スタイルを有効化
      document.body.classList.add("wish-deleting");
      const result = doc.startViewTransition(update) as
        | { finished?: Promise<unknown> }
        | undefined;
      // VT 完了で class を外す
      Promise.resolve(result?.finished).finally(() => {
        document.body.classList.remove("wish-deleting");
      });
    } else {
      update();
    }

    // Stage 3: サーバー削除（バックグラウンド、UI ブロック無し）
    const r = await deleteWishItem(item.id);
    if (r?.error) {
      alert(r.error);
      setRemovedIds((prev) => {
        const next = new Set(prev);
        next.delete(item.id);
        return next;
      });
    } else {
      // 念のため最新データを取り直す（画像有無など他画面と整合）
      router.refresh();
    }
  }

  return (
    <div className="flex w-full flex-shrink-0 snap-start flex-col overflow-y-auto px-4 pb-4 pt-3">
      {visibleItems.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-10 text-center text-xs text-gray-500">
          まだ wish がありません
        </div>
      ) : (
        // iter147: 各パネルがスタガーで pop-in
        <div className={`grid ${GRID_CLASS_BY_COLUMNS[columnCount]}`}>
          {visibleItems.map((w, i) => (
            <WishCardPanel
              key={w.id}
              item={w}
              delayMs={i * 45}
              deleting={deletingId === w.id}
              onRequestDelete={() => requestDelete(w)}
            />
          ))}
        </div>
      )}

      {/* iter150: 削除確認モーダル */}
      {confirmTarget && (
        <DeleteConfirmModal
          item={confirmTarget}
          onCancel={() => setConfirmTarget(null)}
          onConfirm={() => performDelete(confirmTarget)}
        />
      )}
    </div>
  );
}

function WishCardPanel({
  item,
  delayMs,
  deleting,
  onRequestDelete,
}: {
  item: WishItem;
  delayMs: number;
  deleting: boolean;
  onRequestDelete: () => void;
}) {
  const imageReady = useImageReady(item.photoUrl);
  return (
    <div
      className={`${
        imageReady ? "animate-panel-pop" : "pointer-events-none opacity-0"
      } ${deleting ? "animate-fade-out-back" : ""}`}
      style={{ animationDelay: `${delayMs}ms` }}
    >
      <WishCardWrapper
        item={item}
        onRequestDelete={onRequestDelete}
      />
    </div>
  );
}

/* ─── 削除確認モーダル ──────────────────────────────────── */

function DeleteConfirmModal({
  item,
  onCancel,
  onConfirm,
}: {
  item: WishItem;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  const itemLabel = item.characterName ?? item.groupName ?? item.title;
  return (
    <div
      className="animate-delete-backdrop-in fixed inset-0 z-[120] flex items-center justify-center bg-black/55 px-5 backdrop-blur-sm"
      onClick={onCancel}
    >
      <div
        className="animate-delete-modal-in w-full max-w-sm overflow-hidden rounded-[18px] bg-white shadow-[0_20px_60px_rgba(0,0,0,0.3)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-5 pt-5 pb-2">
          <div className="text-[15px] font-extrabold text-[#3a324a]">
            wish を削除しますか？
          </div>
          <div className="mt-1.5 flex items-center gap-2.5 rounded-xl border border-[#3a324a14] bg-[#fbf9fc] px-3 py-2.5">
            {item.photoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={item.photoUrl}
                alt={itemLabel}
                className="h-12 w-9 flex-shrink-0 rounded-md object-cover"
              />
            ) : (
              <div className="flex h-12 w-9 flex-shrink-0 items-center justify-center rounded-md bg-[#a695d822] text-[14px] font-extrabold text-[#a695d8]">
                {itemLabel[0] ?? "?"}
              </div>
            )}
            <div className="min-w-0 flex-1">
              <div className="truncate text-[12.5px] font-bold text-[#3a324a]">
                {itemLabel}
              </div>
              <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">
                {item.goodsTypeName}
              </div>
            </div>
          </div>
          <div className="mt-3 text-[11.5px] leading-relaxed text-[#3a324a8c]">
            この wish を削除します。紐付け中の個別募集がある場合は、その募集の
            「求める」設定も影響を受けます。
          </div>
        </div>
        <div className="flex gap-2 border-t border-[#3a324a08] px-4 py-3">
          <button
            type="button"
            onClick={onCancel}
            className="flex-1 rounded-[10px] bg-[#3a324a08] py-2.5 text-[12.5px] font-bold text-[#3a324a]"
          >
            キャンセル
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className="flex-1 rounded-[10px] bg-red-500 py-2.5 text-[12.5px] font-extrabold text-white shadow-[0_4px_10px_rgba(239,68,68,0.33)] active:scale-[0.98]"
          >
            削除する
          </button>
        </div>
      </div>
    </div>
  );
}

/* ─── Tab 2: 個別募集（既存 ListingsView を流用） ───────── */

function ListingsPanel({ items }: { items: ListingItem[] }) {
  return (
    <div className="flex w-full flex-shrink-0 snap-start flex-col overflow-y-auto px-4 pb-4 pt-3">
      <ListingsView items={items} />
    </div>
  );
}

/* ─── WISH パネル（マイ在庫の ItemCard と同じ 3:4） ─────── */

function WishCardWrapper({
  item,
  onRequestDelete,
}: {
  item: WishItem;
  /** iter150: 削除リクエスト（親で確認モーダル → fade-out → 実削除） */
  onRequestDelete: () => void;
}) {
  const router = useRouter();
  const [sheetOpen, setSheetOpen] = useState(false);
  // iter149: メニュー内ボタン押下時にパネルを跳ねさせる（編集 / 個別募集追加のみ）
  const [bouncing, setBouncing] = useState(false);
  const BOUNCE_MS = 580;
  const itemLabel = item.characterName ?? item.groupName ?? item.title;

  function bounceThen(action: () => void) {
    setSheetOpen(false);
    setBouncing(true);
    window.setTimeout(() => {
      setBouncing(false);
      action();
    }, BOUNCE_MS);
  }

  return (
    <div className="relative">
      <div className={bouncing ? "animate-panel-bounce" : undefined}>
        <button
          type="button"
          onClick={() => !bouncing && setSheetOpen(true)}
          className="block w-full"
        >
          <WishCard item={item} />
        </button>
      </div>
      {sheetOpen && !bouncing && (
        <BottomActionSheet
          title={itemLabel}
          subtitle={item.goodsTypeName}
          imageUrl={item.photoUrl}
          fallbackLabel={itemLabel}
          meta={
            item.quantity > 1 ? (
              <div className="rounded-md bg-megrum-lavender px-1.5 py-0.5 text-[10px] font-extrabold tabular-nums text-white">
                ×{item.quantity}
              </div>
            ) : null
          }
          onClose={() => setSheetOpen(false)}
          actions={[
            {
              label: "編集する",
              tone: "primary",
              onClick: () =>
                bounceThen(() => router.push(`/wishes/${item.id}/edit`)),
            },
            {
              label:
                item.linkedListings.length === 0
                  ? "個別募集を作る"
                  : "+ 個別募集を追加",
              onClick: () =>
                bounceThen(() =>
                  router.push(`/listings/new?wishId=${item.id}`),
                ),
            },
            {
              label: "削除",
              tone: "danger",
              onClick: () => {
                setSheetOpen(false);
                onRequestDelete();
              },
            },
            {
              label: "閉じる",
              tone: "muted",
              onClick: () => setSheetOpen(false),
            },
          ]}
        />
      )}
    </div>
  );
}

function WishCard({ item }: { item: WishItem }) {
  const memberLabel = item.characterName ?? item.groupName ?? "?";
  const stripeBg = `repeating-linear-gradient(135deg, hsl(${item.hue}, 28%, 88%) 0 6px, hsl(${item.hue}, 28%, 82%) 6px 11px)`;
  const memberLabelColor = `hsl(${item.hue}, 35%, 28%)`;
  const initialShadow = `0 2px 6px hsla(${item.hue}, 30%, 30%, 0.4)`;
  const hasPhoto = !!item.photoUrl;
  const linkedCount = item.linkedListings.length;
  const isUnlinked = linkedCount === 0;

  return (
    <div
      className="relative block overflow-hidden rounded-xl border border-[#3a324a14] shadow-[0_2px_6px_rgba(58,50,74,0.08)]"
      style={{
        aspectRatio: "3 / 4",
        background: hasPhoto ? "#3a324a" : stripeBg,
      }}
    >
      {/* 写真（存在時） */}
      {hasPhoto && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={item.photoUrl!}
          alt={memberLabel}
          className="absolute inset-0 h-full w-full object-cover"
          loading="lazy"
          decoding="async"
        />
      )}

      {/* 上部：左にメンバー名 / 右に紐付けバッジ */}
      <div className="absolute inset-x-1.5 top-1.5 z-10 flex items-start justify-between gap-1">
        <div
          className={`min-w-0 truncate rounded-md px-1.5 py-0.5 text-[9px] font-bold ${
            hasPhoto ? "bg-black/55 text-white backdrop-blur-sm" : "bg-white/85"
          }`}
          style={hasPhoto ? undefined : { color: memberLabelColor }}
        >
          {memberLabel}
        </div>
        {isUnlinked ? (
          <span className="flex-shrink-0 rounded-md bg-[#d9826b] px-1.5 py-0.5 text-[8.5px] font-extrabold tracking-[0.3px] text-white shadow-[0_2px_4px_rgba(217,130,107,0.35)]">
            未紐付け
          </span>
        ) : (
          <span className="flex-shrink-0 rounded-md bg-[#a695d8] px-1.5 py-0.5 text-[8.5px] font-extrabold tabular-nums tracking-[0.3px] text-white shadow-[0_2px_4px_rgba(166,149,216,0.35)]">
            募集 {linkedCount}
          </span>
        )}
      </div>

      {/* 中央：イニシャル（写真なしのみ） */}
      {!hasPhoto && (
        <div
          className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 text-[28px] font-extrabold text-white/90"
          style={{ textShadow: initialShadow }}
        >
          {memberLabel[0]}
        </div>
      )}

      {/* 下部ストリップ：種別 + 数量 */}
      <div
        className="absolute bottom-0 left-0 right-0 flex items-end justify-between px-1.5 pb-1.5 pt-1"
        style={{
          background:
            "linear-gradient(180deg, transparent, rgba(255,255,255,0.95))",
        }}
      >
        <div className="min-w-0 flex-1">
          <div className="truncate text-[10px] font-bold leading-tight text-gray-900">
            {item.goodsTypeName}
          </div>
          {item.groupName && item.characterName && (
            <div className="mt-0.5 truncate text-[8.5px] leading-tight text-gray-500">
              {item.groupName}
            </div>
          )}
        </div>
        {item.quantity > 1 && (
          <div className="flex-shrink-0 rounded-md bg-[#a695d8] px-1.5 py-0.5 text-[10px] font-extrabold tabular-nums text-white">
            ×{item.quantity}
          </div>
        )}
      </div>
    </div>
  );
}
