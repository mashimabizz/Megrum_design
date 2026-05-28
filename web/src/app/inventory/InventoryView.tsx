"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { flushSync } from "react-dom";
import { deleteInventoryItem, updateInventoryStatus } from "./actions";
import { AddCard, ItemCard, type ItemCardData } from "./ItemCard";
import { BottomNav } from "@/components/home/BottomNav";
import {
  ColumnCountButton,
  type ColumnCount,
} from "@/components/common/ColumnCountButton";
import { BottomActionSheet } from "@/components/common/BottomActionSheet";
import { useImageReady } from "@/components/common/useImageReady";

export type InventoryItemFull = ItemCardData & {
  status: "active" | "keep" | "traded" | "reserved" | "archived";
  groupName: string | null;
};

type SubTab = "active" | "keep" | "traded";

const SUB_TABS: { id: SubTab; label: string; color: string }[] = [
  { id: "active", label: "譲る候補", color: "#a695d8" },
  { id: "keep", label: "自分用キープ", color: "#f3c5d4" },
  { id: "traded", label: "過去に譲った", color: "#9aa3b0" },
];

const SUB_IDS: SubTab[] = ["active", "keep", "traded"];
const GRID_CLASS_BY_COLUMNS: Record<ColumnCount, string> = {
  3: "grid-cols-3 gap-2.5",
  4: "grid-cols-4 gap-2",
  5: "grid-cols-5 gap-1.5",
};

export function InventoryView({
  items,
}: {
  items: InventoryItemFull[];
}) {
  const router = useRouter();
  const [sub, setSub] = useState<SubTab>("active");
  const [columnCount, setColumnCount] = useState<ColumnCount>(3);
  const scrollRef = useRef<HTMLDivElement>(null);

  // iter98: フィルタを実データ駆動に。
  //   activeMember: null = すべて、それ以外 = memberName 完全一致
  //   activeType  : null = すべて、それ以外 = goodsType 完全一致
  const [activeMember, setActiveMember] = useState<string | null>(null);
  const [activeType, setActiveType] = useState<string | null>(null);

  /** items から実在する memberName / goodsType だけを推し / 種別フィルタ候補に */
  const memberOptions = useMemo(() => {
    const s = new Set<string>();
    for (const it of items) s.add(it.memberName);
    return Array.from(s).sort();
  }, [items]);
  const typeOptions = useMemo(() => {
    const s = new Set<string>();
    for (const it of items) s.add(it.goodsType);
    return Array.from(s).sort();
  }, [items]);

  /** フィルタ適用後の items（status 別の集計はこの後で行う） */
  const filteredItems = useMemo(() => {
    return items.filter((it) => {
      if (activeMember && it.memberName !== activeMember) return false;
      if (activeType && it.goodsType !== activeType) return false;
      return true;
    });
  }, [items, activeMember, activeType]);

  // counts と itemsBySub はフィルタ後で計算
  const counts = useMemo(
    () => ({
      active: filteredItems.filter((i) => i.status === "active").length,
      keep: filteredItems.filter((i) => i.status === "keep").length,
      traded: filteredItems.filter((i) => i.status === "traded").length,
    }),
    [filteredItems],
  );
  const itemsBySub = useMemo(
    () => ({
      active: filteredItems.filter((i) => i.status === "active"),
      keep: filteredItems.filter((i) => i.status === "keep"),
      traded: filteredItems.filter((i) => i.status === "traded"),
    }),
    [filteredItems],
  );
  // carrying 関連は持参グッズ管理機能の廃止に伴い削除（iter65.6）

  // スワイプ位置からタブを更新（debounce 付き）
  useEffect(() => {
    const container = scrollRef.current;
    if (!container) return;
    let frame: number | null = null;
    function onScroll() {
      if (frame) cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        if (!container) return;
        const idx = Math.round(container.scrollLeft / container.clientWidth);
        const next = SUB_IDS[idx];
        if (next && next !== sub) setSub(next);
      });
    }
    container.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      container.removeEventListener("scroll", onScroll);
      if (frame) cancelAnimationFrame(frame);
    };
  }, [sub]);

  // タブクリック時にスムーズスクロール
  function selectSub(target: SubTab) {
    setSub(target);
    const container = scrollRef.current;
    if (!container) return;
    const idx = SUB_IDS.indexOf(target);
    container.scrollTo({
      left: idx * container.clientWidth,
      behavior: "smooth",
    });
  }

  // carrying / going_out の制御は持参グッズ機能の廃止により削除（iter65.6）

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc] pb-[140px]">
      {/* ヘッダー */}
      <div className="border-b border-[#3a324a14] bg-white px-[18px] pb-3 pt-12">
        <div className="mx-auto flex max-w-md items-center justify-between">
          <h1 className="text-[19px] font-extrabold tracking-wide text-gray-900">
            マイ在庫
          </h1>
          <div className="relative flex gap-1.5">
            <ColumnCountButton
              value={columnCount}
              onChange={setColumnCount}
            />
            <IconButton ariaLabel="フィルタ">
              <svg
                width="14"
                height="14"
                viewBox="0 0 14 14"
                fill="none"
                stroke="#3a324a"
                strokeWidth="1.5"
                strokeLinecap="round"
              >
                <path d="M2 4h10M3.5 7h7M5 10h4" />
              </svg>
            </IconButton>
            <IconButton ariaLabel="検索">
              <svg
                width="14"
                height="14"
                viewBox="0 0 14 14"
                fill="none"
                stroke="#3a324a"
                strokeWidth="1.5"
                strokeLinecap="round"
              >
                <circle cx="6" cy="6" r="4" fill="none" />
                <path d="M9.5 9.5L12 12" />
              </svg>
            </IconButton>
          </div>
        </div>

        {/* 持参グッズの設定はホーム > 現地交換モードへ移行（iter65.6） */}
      </div>

      {/* サブタブ（active/keep/traded）- タップ + スワイプ対応 */}
      <div className="mx-auto w-full max-w-md px-4 pt-2.5">
        <div className="flex gap-1">
          {SUB_TABS.map((s) => {
            const active = sub === s.id;
            return (
              <button
                key={s.id}
                type="button"
                onClick={() => selectSub(s.id)}
                className={`relative flex flex-1 items-center justify-center gap-1 rounded-xl py-2 transition-all ${
                  active
                    ? "border-[1.5px] border-solid bg-white"
                    : "border-[0.5px] border-solid border-[#3a324a14] bg-[#3a324a08]"
                }`}
                style={{
                  borderColor: active ? s.color : undefined,
                }}
              >
                <span
                  className={`text-[12px] ${
                    active
                      ? "font-extrabold text-gray-900"
                      : "font-semibold text-gray-500"
                  }`}
                >
                  {s.label}
                </span>
                <span
                  className="text-[10px] font-bold tabular-nums"
                  style={{ color: active ? s.color : "#6b6478" }}
                >
                  {counts[s.id]}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* フィルタチップ（推し / 種別） — iter98: 実データで動作 */}
      <div className="mx-auto w-full max-w-md px-4 pt-1.5">
        <FilterRow
          label="推し"
          options={memberOptions}
          active={activeMember}
          onChange={setActiveMember}
        />
        <FilterRow
          label="種別"
          options={typeOptions}
          active={activeType}
          onChange={setActiveType}
        />
      </div>

      {/* スワイプコンテナ（横スクロール + scroll snap） */}
      <div
        ref={scrollRef}
        className="mx-auto flex w-full max-w-md flex-1 snap-x snap-mandatory overflow-x-auto overflow-y-hidden [-webkit-overflow-scrolling:touch] [&::-webkit-scrollbar]:hidden"
        style={{ scrollbarWidth: "none" }}
      >
        {SUB_IDS.map((subId) => (
          <SubPanel
            key={subId}
            subId={subId}
            items={itemsBySub[subId]}
            router={router}
            columnCount={columnCount}
          />
        ))}
      </div>

    </main>
  );
}

/**
 * 在庫専用フッター（CTA + BottomNav を一体化したブロック）
 * inventory/page.tsx で <BottomNav /> の代わりに使う。
 * CTA と BottomNav が背景連続でぴったりくっつく。
 */
export function InventoryFooter() {
  return (
    <div className="pointer-events-none fixed bottom-0 left-0 right-0 z-40">
      {/* CTA バー */}
      <div className="pointer-events-auto mx-auto max-w-md px-[18px] pb-2 pt-3">
        <Link
          href="/inventory/new"
          className="flex h-12 w-full items-center justify-center gap-2 rounded-2xl bg-gradient-to-br from-megrum-lavender to-megrum-pink text-[14.5px] font-bold tracking-wider text-white shadow-[0_6px_16px_rgba(58,50,74,0.18)] transition-all duration-150 active:scale-[0.97]"
        >
          <svg
            width="14"
            height="14"
            viewBox="0 0 14 14"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
          >
            <path d="M7 1v12M1 7h12" />
          </svg>
          グッズを登録
        </Link>
      </div>

      <div className="pointer-events-auto mx-auto max-w-md px-4 pb-[calc(env(safe-area-inset-bottom)+10px)]">
        <div className="mx-auto w-full max-w-[400px]">
          <BottomNav inline />
        </div>
      </div>
    </div>
  );
}

function SubPanel({
  subId,
  items,
  router,
  columnCount,
}: {
  subId: SubTab;
  items: InventoryItemFull[];
  router: ReturnType<typeof useRouter>;
  columnCount: ColumnCount;
}) {
  const [removedIds, setRemovedIds] = useState<Set<string>>(() => new Set());
  const [confirmTarget, setConfirmTarget] =
    useState<InventoryItemFull | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const visibleItems = useMemo(
    () => items.filter((item) => !removedIds.has(item.id)),
    [items, removedIds],
  );

  function requestDelete(item: InventoryItemFull) {
    setConfirmTarget(item);
  }

  async function performDelete(item: InventoryItemFull) {
    setConfirmTarget(null);
    setDeletingId(item.id);

    // Wish と同じ手触り：まず対象パネルを奥へフェードアウトさせる。
    await new Promise((r) => setTimeout(r, 380));

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
      document.body.classList.add("panel-deleting");
      const result = doc.startViewTransition(update) as
        | { finished?: Promise<unknown> }
        | undefined;
      Promise.resolve(result?.finished).finally(() => {
        document.body.classList.remove("panel-deleting");
      });
    } else {
      update();
    }

    const result = await deleteInventoryItem(item.id);
    if (result?.error) {
      alert(result.error);
      setRemovedIds((prev) => {
        const next = new Set(prev);
        next.delete(item.id);
        return next;
      });
    } else {
      router.refresh();
    }
  }

  return (
    <div className="flex w-full flex-shrink-0 snap-start flex-col overflow-y-auto px-4 pb-4 pt-2">
      {/* グリッド（iter147: 各パネルがスタガーで pop-in） */}
      <div className={`grid ${GRID_CLASS_BY_COLUMNS[columnCount]}`}>
        {subId === "active" && (
          <div
            className="animate-panel-pop"
            style={{ animationDelay: "0ms" }}
          >
            <AddCard href="/inventory/new" />
          </div>
        )}
        {visibleItems.length === 0 && subId !== "active" && (
          <div className="col-span-3 rounded-2xl border border-dashed border-[#3a324a14] bg-white py-10 text-center text-xs text-gray-500">
            {subId === "keep"
              ? "自分用キープのアイテムはまだありません"
              : "譲ったアイテムはまだありません"}
          </div>
        )}
        {visibleItems.map((item, i) => {
          // iter147: AddCard が active のとき index 0 を取るので +1 ずらす
          const idx = subId === "active" ? i + 1 : i;
          return (
            <InventoryCardPanel
              key={item.id}
              item={item}
              router={router}
              delayMs={idx * 45}
              deleting={deletingId === item.id}
              onRequestDelete={() => requestDelete(item)}
            />
          );
        })}
      </div>

      {confirmTarget && (
        <InventoryDeleteConfirmModal
          item={confirmTarget}
          onCancel={() => setConfirmTarget(null)}
          onConfirm={() => performDelete(confirmTarget)}
        />
      )}
    </div>
  );
}

function InventoryCardPanel({
  item,
  router,
  delayMs,
  deleting,
  onRequestDelete,
}: {
  item: InventoryItemFull;
  router: ReturnType<typeof useRouter>;
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
      <ItemCardWrapper
        item={item}
        router={router}
        onRequestDelete={onRequestDelete}
      />
    </div>
  );
}

function IconButton({
  children,
  ariaLabel,
  onClick,
}: {
  children: React.ReactNode;
  ariaLabel: string;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      aria-label={ariaLabel}
      onClick={onClick}
      className="flex h-8 w-8 items-center justify-center rounded-[10px] border border-[#3a324a14] bg-white"
    >
      {children}
    </button>
  );
}

/**
 * iter98: 実データで動作する FilterRow。
 *
 * - options：items から動的に抽出した値（例：memberName / goodsType の Set）
 * - active：null = 「すべて」、それ以外 = 選択中の値
 * - 親が onChange で active を更新する
 * - options が空（在庫が無い）なら何も表示しない（ノイズ削減）
 */
export function FilterRow({
  label,
  options,
  active,
  onChange,
}: {
  label: string;
  options: string[];
  active: string | null;
  onChange: (next: string | null) => void;
}) {
  if (options.length === 0) return null;
  return (
    <div className="mb-1.5 flex items-center gap-1.5 overflow-x-auto pb-1 [&::-webkit-scrollbar]:hidden">
      <span className="w-7 flex-shrink-0 pr-1 text-[9.5px] font-bold tracking-wider text-gray-500">
        {label}
      </span>
      <button
        type="button"
        onClick={() => onChange(null)}
        className={`flex-shrink-0 whitespace-nowrap rounded-full px-2.5 py-1 text-[11px] font-semibold transition-all ${
          active === null
            ? "bg-[#a695d8] text-white"
            : "border-[0.5px] border-[#3a324a14] bg-white text-gray-900"
        }`}
      >
        すべて
      </button>
      {options.map((f) => (
        <button
          key={f}
          type="button"
          onClick={() => onChange(f)}
          className={`flex-shrink-0 whitespace-nowrap rounded-full px-2.5 py-1 text-[11px] font-semibold transition-all ${
            active === f
              ? "bg-[#a695d8] text-white"
              : "border-[0.5px] border-[#3a324a14] bg-white text-gray-900"
          }`}
        >
          {f}
        </button>
      ))}
    </div>
  );
}

function ItemCardWrapper({
  item,
  router,
  onRequestDelete,
}: {
  item: InventoryItemFull;
  router: ReturnType<typeof useRouter>;
  onRequestDelete: () => void;
}) {
  const [sheetOpen, setSheetOpen] = useState(false);
  const [bouncing, setBouncing] = useState(false);
  const BOUNCE_MS = 580;
  const itemLabel = `${item.memberName} ${item.goodsType}`;
  const statusAction =
    item.status === "keep"
      ? {
          label: "譲る候補へ",
          onClick: () => bounceThen(() => changeStatus("active")),
        }
      : {
          label: "自分キープへ",
          onClick: () => bounceThen(() => changeStatus("keep")),
        };

  function bounceThen(action?: () => void | Promise<void>) {
    setSheetOpen(false);
    setBouncing(true);
    window.setTimeout(() => {
      setBouncing(false);
      void action?.();
    }, BOUNCE_MS);
  }

  async function changeStatus(
    status: "active" | "keep" | "traded" | "archived",
  ) {
    setSheetOpen(false);
    const result = await updateInventoryStatus(item.id, status);
    if (result?.error) {
      alert(result.error);
    } else {
      router.refresh();
    }
  }

  return (
    <div className="relative">
      <div className={bouncing ? "animate-panel-bounce" : undefined}>
        <button
          type="button"
          onClick={() => {
            if (bouncing) return;
            if (item.status === "traded") {
              router.push(`/inventory/${item.id}`);
              return;
            }
            setSheetOpen(true);
          }}
          className="block w-full"
        >
          <ItemCard item={item} />
        </button>
      </div>
      {sheetOpen && !bouncing && item.status !== "traded" && (
        <BottomActionSheet
          title={item.memberName}
          subtitle={item.goodsType}
          imageUrl={item.photoUrl}
          fallbackLabel={itemLabel}
          meta={
            item.qty > 1 ? (
              <div className="rounded-md bg-megrum-lavender px-1.5 py-0.5 text-[10px] font-extrabold tabular-nums text-white">
                ×{item.qty}
              </div>
            ) : null
          }
          onClose={() => setSheetOpen(false)}
          actions={[
            {
              label: "編集する",
              tone: "primary",
              onClick: () =>
                bounceThen(() => router.push(`/inventory/${item.id}`)),
            },
            statusAction,
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

function InventoryDeleteConfirmModal({
  item,
  onCancel,
  onConfirm,
}: {
  item: InventoryItemFull;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  const itemLabel = `${item.memberName} ${item.goodsType}`;
  return (
    <div
      className="animate-delete-backdrop-in fixed inset-0 z-[120] flex items-center justify-center bg-black/55 px-5 backdrop-blur-sm"
      onClick={onCancel}
    >
      <div
        className="animate-delete-modal-in w-full max-w-sm overflow-hidden rounded-[18px] bg-white shadow-[0_20px_60px_rgba(0,0,0,0.3)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-5 pb-2 pt-5">
          <div className="text-[15px] font-extrabold text-[#3a324a]">
            在庫を削除しますか？
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
                {item.memberName[0] ?? "?"}
              </div>
            )}
            <div className="min-w-0 flex-1">
              <div className="truncate text-[12.5px] font-bold text-[#3a324a]">
                {item.memberName}
              </div>
              <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">
                {item.goodsType}
              </div>
            </div>
            {item.qty > 1 && (
              <div className="rounded-md bg-[#a695d8] px-1.5 py-0.5 text-[10px] font-extrabold tabular-nums text-white">
                ×{item.qty}
              </div>
            )}
          </div>
          <div className="mt-3 text-[11.5px] leading-relaxed text-[#3a324a8c]">
            この在庫を削除します。削除後はマッチング候補や打診の対象から外れます。
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
