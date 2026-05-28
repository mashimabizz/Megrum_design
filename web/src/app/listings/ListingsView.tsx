"use client";

/**
 * iter69-B：個別募集（listings）の自分一覧。
 *
 * 設計：マッチ詳細モーダル（MatchDetailModal）の ListingDiagram 風レイアウトを
 * 流用 — 左に「譲」群 / 中央に SVG で実線 / 右に「求」選択肢縦並び。
 *
 * - 編集ボタン（→ /listings/[id]/edit）
 * - 一時停止 / 再開 / 削除
 */

import Link from "next/link";
import { useRouter } from "next/navigation";
import { type CSSProperties, useEffect, useRef, useState } from "react";
import { deleteListing, updateListing } from "./actions";

export type ListingHaveItem = {
  id: string;
  title: string;
  qty: number;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
};

export type ListingWishItem = {
  id: string;
  title: string;
  qty: number;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
};

export type ListingOption = {
  id: string;
  position: number;
  logic: "and" | "or";
  exchangeType: "same_kind" | "cross_kind" | "any";
  isCashOffer: boolean;
  cashAmount: number | null;
  groupName: string | null;
  goodsTypeName: string | null;
  wishes: ListingWishItem[];
};

export type ListingItem = {
  id: string;
  haves: ListingHaveItem[];
  haveLogic: "and" | "or";
  haveGroupName: string | null;
  haveGoodsTypeName: string | null;
  options: ListingOption[];
  status: "active" | "paused" | "matched" | "closed";
  note: string | null;
};

type DeckWishSlot = {
  key: string;
  option: ListingOption;
  wish: ListingWishItem | null;
};

const EXCHANGE_LABEL: Record<"same_kind" | "cross_kind" | "any", string> = {
  same_kind: "同種",
  cross_kind: "異種",
  any: "同異種",
};

/* レイアウト数値（MatchDetailModal と揃える） */
const HAVE_W = 72;
const HAVE_SINGLE_H = 42;
const HAVE_MULTI_BASE_H = 106;
const OPT_SINGLE_H = 48;
const OPT_MULTI_H = 78;
const OPT_CASH_H = 50;
const OPT_GAP = 10;
const SVG_W = 50;
const RIGHT_W = 228;

export function ListingsView({
  items,
  readOnly = false,
}: {
  items: ListingItem[];
  /**
   * iter146：閲覧専用モード（他人プロフでの公開個別募集表示用）。
   * - 編集 / 一時停止 / 削除 ボタン非表示
   * - 「まだ個別募集がありません」の追加導線も非表示
   */
  readOnly?: boolean;
}) {
  const router = useRouter();
  const [deckIndex, setDeckIndex] = useState(0);
  const activeDeckIndex = Math.min(deckIndex, Math.max(0, items.length - 1));

  async function handleDelete(id: string) {
    if (readOnly) return;
    if (!confirm("この個別募集を削除しますか？")) return;
    const r = await deleteListing(id);
    if (r?.error) {
      alert(r.error);
      return;
    }
    router.refresh();
  }

  async function togglePause(id: string, currentStatus: ListingItem["status"]) {
    if (readOnly) return;
    const next = currentStatus === "active" ? "paused" : "active";
    const r = await updateListing({ id, status: next });
    if (r?.error) {
      alert(r.error);
      return;
    }
    router.refresh();
  }

  if (items.length === 0) {
    if (readOnly) {
      return (
        <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-10 text-center text-xs text-[#3a324a8c]">
          公開中の個別募集はありません
        </div>
      );
    }
    return (
      <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-10 text-center text-xs text-[#3a324a8c]">
        まだ個別募集がありません
        <br />
        <Link
          href="/listings/new"
          className="mt-2 inline-block font-bold text-[#a695d8]"
        >
          + 個別募集を追加
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <ListingDeck
        items={items}
        activeIndex={activeDeckIndex}
        onActiveIndexChange={setDeckIndex}
        onTogglePause={(item) => togglePause(item.id, item.status)}
        onDelete={(item) => handleDelete(item.id)}
        readOnly={readOnly}
      />
      <div className="space-y-3">
        {items.map((it) => (
          <ListingCard
            key={it.id}
            listing={it}
            onTogglePause={() => togglePause(it.id, it.status)}
            onDelete={() => handleDelete(it.id)}
            readOnly={readOnly}
          />
        ))}
      </div>
    </div>
  );
}

/* ─── 募集デッキ — 横スワイプで 1 募集ずつ大きく見る ─── */

function ListingDeck({
  items,
  activeIndex,
  onActiveIndexChange,
  onTogglePause,
  onDelete,
  readOnly,
}: {
  items: ListingItem[];
  activeIndex: number;
  onActiveIndexChange: (index: number) => void;
  onTogglePause: (item: ListingItem) => void;
  onDelete: (item: ListingItem) => void;
  readOnly?: boolean;
}) {
  const scrollerRef = useRef<HTMLDivElement | null>(null);
  const frameRef = useRef<number | null>(null);

  useEffect(() => {
    return () => {
      if (frameRef.current != null) window.cancelAnimationFrame(frameRef.current);
    };
  }, []);

  function handleScroll() {
    const scroller = scrollerRef.current;
    if (!scroller || frameRef.current != null) return;
    frameRef.current = window.requestAnimationFrame(() => {
      frameRef.current = null;
      const cards = Array.from(
        scroller.querySelectorAll<HTMLElement>("[data-listing-deck-card]"),
      );
      const center = scroller.scrollLeft + scroller.clientWidth / 2;
      let nearest = activeIndex;
      let nearestDistance = Number.POSITIVE_INFINITY;
      cards.forEach((card, index) => {
        const cardCenter = card.offsetLeft + card.offsetWidth / 2;
        const distance = Math.abs(cardCenter - center);
        if (distance < nearestDistance) {
          nearest = index;
          nearestDistance = distance;
        }
      });
      if (nearest !== activeIndex) onActiveIndexChange(nearest);
    });
  }

  function scrollToIndex(index: number) {
    const scroller = scrollerRef.current;
    const card = scroller?.querySelectorAll<HTMLElement>(
      "[data-listing-deck-card]",
    )[index];
    if (!scroller || !card) return;
    scroller.scrollTo({
      left: card.offsetLeft - (scroller.clientWidth - card.offsetWidth) / 2,
      behavior: "smooth",
    });
    onActiveIndexChange(index);
  }

  return (
    <section className="-mx-4 overflow-hidden pb-1">
      <style>{`
        @keyframes megrum-listing-card-float {
          0%, 100% { transform: translate3d(0, 0, 0) rotate(-0.25deg); }
          50% { transform: translate3d(0, -7px, 0) rotate(0.35deg); }
        }
        @keyframes megrum-listing-cord-flow {
          from { stroke-dashoffset: 0; }
          to { stroke-dashoffset: -36; }
        }
        @keyframes megrum-listing-knot-pulse {
          0%, 100% { transform: scale(1); opacity: 0.92; }
          50% { transform: scale(1.08); opacity: 1; }
        }
        .megrum-listing-card-float {
          animation: megrum-listing-card-float 5.4s ease-in-out infinite;
        }
        .megrum-listing-cord-line {
          stroke-dasharray: 7 10;
          animation: megrum-listing-cord-flow 8s linear infinite;
        }
        .megrum-listing-knot {
          animation: megrum-listing-knot-pulse 3.6s ease-in-out infinite;
        }
        @media (prefers-reduced-motion: reduce) {
          .megrum-listing-card-float,
          .megrum-listing-cord-line,
          .megrum-listing-knot {
            animation: none;
          }
        }
      `}</style>
      <div className="mb-2 flex items-center justify-between px-4">
        <div className="text-[13px] font-extrabold tracking-[0.2px] text-[#3a324a]">
          募集デッキ
        </div>
        <div className="rounded-full bg-[#3a324a08] px-2.5 py-1 text-[10px] font-extrabold tabular-nums text-[#3a324a8c]">
          {Math.min(activeIndex + 1, items.length)} / {items.length}
        </div>
      </div>
      <div
        ref={scrollerRef}
        onScroll={handleScroll}
        className="flex snap-x snap-mandatory gap-3 overflow-x-auto px-5 pb-2 pt-1 [scrollbar-width:none] [-webkit-overflow-scrolling:touch] [&::-webkit-scrollbar]:hidden"
      >
        {items.map((item, index) => {
          const offset = index - activeIndex;
          const active = offset === 0;
          return (
            <div
              key={item.id}
              data-listing-deck-card
              className="w-[84%] flex-shrink-0 snap-center transition-transform duration-500 ease-out [perspective:900px]"
              style={{
                transform: active
                  ? "translateY(0) scale(1) rotateY(0deg)"
                  : `translateY(9px) scale(0.93) rotateY(${offset < 0 ? 4 : -4}deg)`,
                transformStyle: "preserve-3d",
              }}
            >
              <ListingDeckCard
                listing={item}
                active={active}
                onTogglePause={() => onTogglePause(item)}
                onDelete={() => onDelete(item)}
                readOnly={readOnly}
              />
            </div>
          );
        })}
      </div>
      {items.length > 1 && (
        <div className="mt-1 flex justify-center gap-1.5">
          {items.map((item, index) => (
            <button
              key={item.id}
              type="button"
              aria-label={`募集 ${index + 1} を表示`}
              onClick={() => scrollToIndex(index)}
              className={`h-1.5 rounded-full transition-all ${
                index === activeIndex
                  ? "w-5 bg-[#a695d8]"
                  : "w-1.5 bg-[#3a324a1f]"
              }`}
            />
          ))}
        </div>
      )}
    </section>
  );
}

function ListingDeckCard({
  listing,
  active,
  onTogglePause,
  onDelete,
  readOnly,
}: {
  listing: ListingItem;
  active: boolean;
  onTogglePause: () => void;
  onDelete: () => void;
  readOnly?: boolean;
}) {
  const isActive = listing.status === "active";
  const wishSlots = getDeckWishSlots(listing);
  const mode =
    wishSlots.length <= 1 ? "duel" : wishSlots.length <= 3 ? "fan" : "orb";

  return (
    <article
      className={`megrum-listing-card-float relative min-h-[254px] overflow-hidden rounded-[22px] border bg-white shadow-[0_18px_44px_rgba(58,50,74,0.13)] ${
        active ? "border-[#a695d866]" : "border-[#3a324a12]"
      }`}
      style={{
        animationDelay: `${-(listing.id.length % 5) * 0.38}s`,
      }}
    >
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_22%_4%,rgba(166,149,216,0.17),transparent_38%),radial-gradient(circle_at_92%_24%,rgba(243,197,212,0.16),transparent_36%),radial-gradient(circle_at_48%_92%,rgba(168,212,230,0.16),transparent_42%),linear-gradient(180deg,#ffffff,#fbf9fc)]" />
      <span className="absolute left-8 top-14 h-2 w-2 rounded-full bg-[#f3c5d4aa] blur-[0.5px]" />
      <span className="absolute right-10 top-20 h-1.5 w-1.5 rounded-full bg-[#a8d4e6cc] blur-[0.5px]" />
      <span className="absolute bottom-8 left-12 h-1.5 w-1.5 rounded-full bg-[#a695d899] blur-[0.5px]" />
      <div className="relative z-10 flex items-center gap-2 px-3 py-2">
        <span
          className={`rounded-full px-2 py-[2px] text-[9.5px] font-extrabold tracking-[0.5px] ${
            isActive
              ? "bg-emerald-500 text-white"
              : "bg-[#3a324a14] text-[#3a324a8c]"
          }`}
        >
          {isActive
            ? "ACTIVE"
            : listing.status === "paused"
              ? "一時停止"
              : listing.status === "matched"
                ? "MATCHED"
                : listing.status === "closed"
                  ? "完了"
                  : listing.status.toUpperCase()}
        </span>
        <div className="min-w-0 flex-1 truncate text-[10.5px] font-bold text-[#3a324a8c]">
          {[listing.haveGroupName, listing.haveGoodsTypeName]
            .filter(Boolean)
            .join(" × ") || "個別募集"}
        </div>
        {!readOnly && (
          <div className="flex items-center gap-1">
            <Link
              href={`/listings/${listing.id}/edit`}
              aria-label="個別募集を編集"
              title="編集"
              className="flex h-7 w-7 items-center justify-center rounded-full bg-white/85 text-[#a695d8] shadow-[0_2px_8px_rgba(58,50,74,0.08)] active:scale-95"
            >
              <EditIcon />
            </Link>
            <button
              type="button"
              onClick={onTogglePause}
              disabled={listing.status === "matched" || listing.status === "closed"}
              aria-label={listing.status === "paused" ? "個別募集を再開" : "個別募集を一時停止"}
              title={listing.status === "paused" ? "再開" : "一時停止"}
              className="flex h-7 w-7 items-center justify-center rounded-full bg-white/85 text-[#3a324acc] shadow-[0_2px_8px_rgba(58,50,74,0.08)] active:scale-95 disabled:opacity-40"
            >
              {listing.status === "paused" ? <PlayIcon /> : <PauseIcon />}
            </button>
            <button
              type="button"
              onClick={onDelete}
              aria-label="個別募集を削除"
              title="削除"
              className="flex h-7 w-7 items-center justify-center rounded-full bg-white/85 text-red-500 shadow-[0_2px_8px_rgba(58,50,74,0.08)] active:scale-95"
            >
              <TrashIcon />
            </button>
          </div>
        )}
      </div>

      <div className="relative z-10 px-3 pb-3">
        {mode === "duel" ? (
          <DeckDuel listing={listing} slot={wishSlots[0] ?? null} />
        ) : mode === "fan" ? (
          <DeckFan listing={listing} slots={wishSlots} />
        ) : (
          <DeckOrb listing={listing} slots={wishSlots} />
        )}
      </div>
    </article>
  );
}

function getDeckWishSlots(listing: ListingItem): DeckWishSlot[] {
  return [...listing.options]
    .sort((a, b) => a.position - b.position)
    .flatMap<DeckWishSlot>((option) => {
      if (option.isCashOffer) {
        return [{ key: `${option.id}:cash`, option, wish: null }];
      }
      return option.wishes.map((wish) => ({
        key: `${option.id}:${wish.id}`,
        option,
        wish,
      }));
    });
}

function DeckDuel({
  listing,
  slot,
}: {
  listing: ListingItem;
  slot: DeckWishSlot | null;
}) {
  return (
    <div className="relative grid min-h-[190px] grid-cols-[minmax(0,1fr)_44px_minmax(0,1fr)] items-center gap-2">
      <DeckCord variant="duel" />
      <div className="relative z-10 flex min-w-0 flex-col items-center">
        <DeckHaveVisual listing={listing} size={112} />
        <DeckCaption text="譲る" />
      </div>
      <div className="relative z-20 flex justify-center">
        <DeckKnot />
      </div>
      <div className="relative z-10 flex min-w-0 flex-col items-center">
        <DeckWishVisual slot={slot} size={112} />
        <DeckCaption text={deckWishCaption(slot)} chip={slot?.option} />
      </div>
    </div>
  );
}

function DeckFan({
  listing,
  slots,
}: {
  listing: ListingItem;
  slots: DeckWishSlot[];
}) {
  const visible = slots.slice(0, 3);
  const transforms = [
    "translate3d(-6px, 24px, 0) rotate(-10deg)",
    "translate3d(38px, 2px, 0) rotate(0deg)",
    "translate3d(82px, 24px, 0) rotate(10deg)",
  ];

  return (
    <div className="relative min-h-[190px]">
      <DeckCord variant="fan" />
      <div className="absolute left-1 top-10 z-20 flex flex-col items-center">
        <DeckHaveVisual listing={listing} size={104} />
        <DeckCaption text="譲る" />
      </div>
      <div className="absolute left-[114px] top-[88px] z-30">
        <DeckKnot compact />
      </div>
      <div className="absolute right-0 top-4 h-[162px] w-[178px]">
        {visible.map((slot, index) => (
          <div
            key={slot.key}
            className="absolute left-0 top-0 z-10 flex flex-col items-center"
            style={{ transform: transforms[index] }}
          >
            <DeckWishVisual slot={slot} size={78} />
          </div>
        ))}
        {slots.length > visible.length && (
          <span className="absolute bottom-2 right-3 z-30 rounded-full bg-[#3a324acc] px-2 py-1 text-[10px] font-extrabold text-white">
            +{slots.length - visible.length}
          </span>
        )}
      </div>
      <div className="absolute bottom-1 left-[142px] right-2 z-30 flex min-w-0 items-center justify-end">
        <DeckCaption text={deckWishCaption(visible[0] ?? null)} />
      </div>
    </div>
  );
}

function DeckOrb({
  listing,
  slots,
}: {
  listing: ListingItem;
  slots: DeckWishSlot[];
}) {
  const visible = slots.slice(0, 6);
  const positions: CSSProperties[] = [
    { left: 2, top: 8 },
    { right: 0, top: 8 },
    { left: 16, bottom: 18 },
    { right: 12, bottom: 20 },
    { left: 88, top: 0 },
    { left: 94, bottom: 0 },
  ];

  return (
    <div className="relative min-h-[198px]">
      <DeckCord variant="orb" />
      <div className="absolute left-1/2 top-1/2 z-20 flex -translate-x-1/2 -translate-y-1/2 flex-col items-center">
        <div className="rounded-[24px] bg-white/65 p-1 shadow-[0_12px_28px_rgba(58,50,74,0.14)] backdrop-blur-sm">
          <DeckHaveVisual listing={listing} size={102} />
        </div>
        <span className="mt-1 rounded-full bg-white/85 px-2 py-[2px] text-[9px] font-extrabold text-[#3a324a99] shadow-[0_2px_8px_rgba(58,50,74,0.08)]">
          {logicLabel(listing.haveLogic)}
        </span>
      </div>
      <div className="absolute inset-0 rounded-[18px] border border-white/60 bg-[radial-gradient(circle_at_50%_50%,rgba(166,149,216,0.2),transparent_34%)]" />
      {visible.map((slot, index) => (
        <div
          key={slot.key}
          className="absolute z-10 flex flex-col items-center"
          style={positions[index]}
        >
          <DeckWishVisual slot={slot} size={58} />
        </div>
      ))}
      {slots.length > visible.length && (
        <span className="absolute right-2 top-1/2 z-30 -translate-y-1/2 rounded-full bg-[#3a324acc] px-2 py-1 text-[10px] font-extrabold text-white">
          +{slots.length - visible.length}
        </span>
      )}
    </div>
  );
}

function DeckHaveVisual({
  listing,
  size,
}: {
  listing: ListingItem;
  size: number;
}) {
  if (listing.haves.length === 0) {
    return <DeckEmptyVisual label="譲" size={size} />;
  }

  if (listing.haves.length === 1) {
    return <DeckItemVisual item={listing.haves[0]} kind="have" size={size} />;
  }

  const visible = listing.haves.slice(0, 3);
  return (
    <div className="relative" style={{ width: size, height: size }}>
      {visible.map((item, index) => (
        <DeckItemVisual
          key={item.id}
          item={item}
          kind="have"
          size={size - index * 12}
          className="absolute"
          style={{
            left: index * 8,
            top: index * 8,
            zIndex: visible.length - index,
          }}
        />
      ))}
      <span className="absolute left-1 top-1 z-20 rounded-full bg-[#a8d4e6] px-2 py-[2px] text-[9px] font-extrabold text-white shadow-[0_2px_6px_rgba(58,50,74,0.16)]">
        {logicLabel(listing.haveLogic)}
      </span>
      {listing.haves.length > visible.length && (
        <span className="absolute bottom-1 right-1 z-20 rounded-full bg-[#3a324acc] px-2 py-[2px] text-[9px] font-extrabold text-white">
          +{listing.haves.length - visible.length}
        </span>
      )}
    </div>
  );
}

function DeckWishVisual({
  slot,
  size,
}: {
  slot: DeckWishSlot | null;
  size: number;
}) {
  if (!slot) return <DeckEmptyVisual label="求" size={size} />;
  if (slot.option.isCashOffer) {
    return <DeckCashVisual amount={slot.option.cashAmount} size={size} />;
  }
  if (!slot.wish) return <DeckEmptyVisual label="求" size={size} />;
  return <DeckItemVisual item={slot.wish} kind="wish" size={size} />;
}

function DeckItemVisual({
  item,
  kind,
  size,
  className = "",
  style,
}: {
  item: ListingHaveItem | ListingWishItem;
  kind: "have" | "wish";
  size: number;
  className?: string;
  style?: CSSProperties;
}) {
  const name = item.characterName ?? item.groupName ?? item.title;
  const hue = itemHueFromName(name);
  const stripeBg = `repeating-linear-gradient(135deg, hsl(${hue}, 30%, 88%) 0 6px, hsl(${hue}, 32%, 80%) 6px 12px)`;
  const hasPhoto = !!item.photoUrl;
  const radius = size >= 80 ? 18 : 13;

  return (
    <div
      className={`relative flex flex-shrink-0 items-center justify-center overflow-hidden border bg-white shadow-[0_8px_18px_rgba(58,50,74,0.16)] ${className} ${
        kind === "have" ? "border-[#a8d4e6]" : "border-[#f3c5d4]"
      }`}
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        background: hasPhoto ? "#fff" : stripeBg,
        ...style,
      }}
      title={`${item.title} ×${item.qty}`}
    >
      {hasPhoto && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={item.photoUrl!}
          alt={item.title}
          className="absolute inset-0 h-full w-full object-cover"
          decoding="async"
        />
      )}
      {!hasPhoto && (
        <span
          className="font-extrabold text-white/95"
          style={{
            fontSize: Math.max(16, Math.round(size * 0.32)),
            textShadow: `0 2px 4px hsla(${hue}, 30%, 28%, 0.5)`,
          }}
        >
          {name[0] || "?"}
        </span>
      )}
      <span className="absolute right-0 top-0 rounded-bl-lg bg-black/55 px-1.5 py-[1px] text-[9px] font-extrabold leading-tight text-white">
        ×{item.qty}
      </span>
    </div>
  );
}

function DeckCashVisual({
  amount,
  size,
}: {
  amount: number | null;
  size: number;
}) {
  return (
    <div
      className="flex flex-col items-center justify-center rounded-[18px] border border-[#7a9a8a55] bg-[#7a9a8a14] text-[#3a324a] shadow-[0_8px_18px_rgba(58,50,74,0.12)]"
      style={{ width: size, height: size }}
    >
      <span className="text-[24px] leading-none">¥</span>
      <span className="mt-1 max-w-[86%] truncate text-[10px] font-extrabold">
        {amount?.toLocaleString() ?? "相談"}
      </span>
    </div>
  );
}

function DeckEmptyVisual({
  label,
  size,
}: {
  label: string;
  size: number;
}) {
  return (
    <div
      className="flex items-center justify-center rounded-[18px] border border-dashed border-[#3a324a24] bg-white/70 text-[12px] font-extrabold text-[#3a324a66]"
      style={{ width: size, height: size }}
    >
      {label}
    </div>
  );
}

function DeckCord({ variant }: { variant: "duel" | "fan" | "orb" }) {
  const viewBox = variant === "orb" ? "0 0 320 198" : "0 0 320 190";
  const paths =
    variant === "duel"
      ? ["M82 96 C126 58 190 132 238 94"]
      : variant === "fan"
        ? [
            "M82 96 C128 44 190 48 248 58",
            "M84 98 C132 96 190 94 248 94",
            "M82 100 C128 150 190 142 248 132",
          ]
        : [
            "M160 100 C112 58 78 38 34 36",
            "M160 100 C212 56 244 38 292 36",
            "M160 100 C108 130 72 154 50 166",
            "M160 100 C212 132 248 154 286 164",
            "M160 100 C146 50 132 26 116 24",
            "M160 100 C172 148 134 176 124 184",
          ];
  return (
    <svg
      viewBox={viewBox}
      preserveAspectRatio="none"
      className="pointer-events-none absolute inset-0 z-0 h-full w-full"
      aria-hidden="true"
    >
      {paths.map((d) => (
        <g key={d}>
          <path
            d={d}
            fill="none"
            stroke="#ffffff"
            strokeLinecap="round"
            strokeWidth="7"
            opacity="0.88"
          />
          <path
            d={d}
            fill="none"
            stroke="#cbbce8"
            strokeLinecap="round"
            strokeWidth="2.2"
            opacity="0.92"
          />
          <path
            d={d}
            fill="none"
            stroke="#a695d8"
            strokeLinecap="round"
            strokeWidth="1.35"
            opacity="0.42"
            className="megrum-listing-cord-line"
          />
        </g>
      ))}
    </svg>
  );
}

function DeckKnot({ compact = false }: { compact?: boolean }) {
  const size = compact ? 30 : 36;
  return (
    <div
      className="megrum-listing-knot relative flex shrink-0 items-center justify-center rounded-full border border-white/80 bg-white/80 shadow-[0_8px_20px_rgba(166,149,216,0.18)] backdrop-blur-sm"
      style={{ width: size, height: size }}
      aria-hidden="true"
    >
      <svg
        width={compact ? 20 : 24}
        height={compact ? 20 : 24}
        viewBox="0 0 24 24"
      >
        <path
          d="M12 12C8.6 7.8 5.6 7.4 4.2 9.1 2.6 11 4.7 14 8 13.4c1.5-.3 2.8-.9 4-1.4Zm0 0c3.4-4.2 6.4-4.6 7.8-2.9 1.6 1.9-.5 4.9-3.8 4.3-1.5-.3-2.8-.9-4-1.4Z"
          fill="none"
          stroke="#a695d8"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="1.7"
        />
        <path
          d="M8 16c1.5-1.3 2.8-2.6 4-4 1.2 1.4 2.5 2.7 4 4"
          fill="none"
          stroke="#f3c5d4"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="1.6"
        />
      </svg>
    </div>
  );
}

function DeckCaption({
  text,
  chip,
}: {
  text: string;
  chip?: ListingOption;
}) {
  return (
    <div className="mt-2 flex max-w-full items-center justify-center gap-1 rounded-full bg-white/80 px-2 py-1 shadow-[0_4px_12px_rgba(58,50,74,0.07)] backdrop-blur-sm">
      {chip && <ExchangeChip option={chip} />}
      <span className="max-w-[112px] truncate text-[10px] font-extrabold text-[#3a324a]">
        {text}
      </span>
    </div>
  );
}

function deckWishCaption(slot: DeckWishSlot | null): string {
  if (!slot) return "求める";
  if (slot.option.isCashOffer) {
    return `¥${slot.option.cashAmount?.toLocaleString() ?? "相談"}`;
  }
  if (!slot.wish) return "求める";
  return `${itemLabel(slot.wish)} ×${slot.wish.qty}`;
}

/* ─── 個別募集カード ─── */

function ListingCard({
  listing,
  onTogglePause,
  onDelete,
  readOnly,
}: {
  listing: ListingItem;
  onTogglePause: () => void;
  onDelete: () => void;
  /** iter146：閲覧専用（他人プロフ表示時）— アクションボタン群を非表示 */
  readOnly?: boolean;
}) {
  const isActive = listing.status === "active";
  const isPaused = listing.status === "paused";
  const isClosed = listing.status === "closed";
  const isMatched = listing.status === "matched";

  return (
    <div
      className={`overflow-hidden rounded-2xl border bg-white shadow-[0_6px_18px_rgba(58,50,74,0.06)] ${
        isActive
          ? "border-[#a695d855] ring-1 ring-[#f3c5d41f]"
          : "border-[#3a324a14] opacity-70"
      }`}
    >
      {/* ヘッダ */}
      <div className="flex items-center gap-2 border-b border-[#3a324a08] bg-[linear-gradient(135deg,#fbf9fc,#ffffff)] px-3 py-2">
        <span
          className={`rounded-full px-2 py-[2px] text-[9.5px] font-extrabold tracking-[0.5px] ${
            isActive
              ? "bg-emerald-500 text-white"
              : isPaused
                ? "bg-[#3a324a14] text-[#3a324a8c]"
                : isMatched
                  ? "bg-[#a8d4e620] text-[#5a9bbe]"
                  : "bg-[#3a324a14] text-[#3a324a8c]"
          }`}
        >
          {isActive
            ? "ACTIVE"
            : isPaused
              ? "一時停止"
              : isMatched
                ? "MATCHED"
                : isClosed
                  ? "完了"
                  : listing.status.toUpperCase()}
        </span>
        {listing.haveGroupName && listing.haveGoodsTypeName && (
          <span className="truncate text-[10px] font-bold text-[#3a324a8c]">
            {listing.haveGroupName} × {listing.haveGoodsTypeName}
          </span>
        )}
        <div className="flex-1" />
        {!readOnly && (
          <div className="ml-0.5 flex items-center gap-1">
            <Link
              href={`/listings/${listing.id}/edit`}
              aria-label="個別募集を編集"
              title="編集"
              className="flex h-7 w-7 items-center justify-center rounded-full bg-[#a695d812] text-[#a695d8] transition-transform active:scale-95"
            >
              <EditIcon />
            </Link>
            <button
              type="button"
              onClick={onTogglePause}
              disabled={isMatched || isClosed}
              aria-label={isPaused ? "個別募集を再開" : "個別募集を一時停止"}
              title={isPaused ? "再開" : "一時停止"}
              className="flex h-7 w-7 items-center justify-center rounded-full bg-[#3a324a08] text-[#3a324acc] transition-transform active:scale-95 disabled:opacity-40"
            >
              {isPaused ? <PlayIcon /> : <PauseIcon />}
            </button>
            <button
              type="button"
              onClick={onDelete}
              aria-label="個別募集を削除"
              title="削除"
              className="flex h-7 w-7 items-center justify-center rounded-full bg-red-50 text-red-500 transition-transform active:scale-95"
            >
              <TrashIcon />
            </button>
          </div>
        )}
      </div>

      {/* 関係図 */}
      <div className="px-2 py-2.5">
        <Diagram listing={listing} />
      </div>

      {listing.note && (
        <div className="mx-3 mb-2 rounded-lg bg-[#3a324a06] px-2.5 py-1.5 text-[11px] text-[#3a324a]">
          {listing.note}
        </div>
      )}

    </div>
  );
}

function EditIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
      <path
        d="M2.4 10.3 2 12l1.7-.4 6.7-6.7-1.3-1.3-6.7 6.7Z"
        fill="none"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.4"
      />
      <path
        d="m8.4 4.2 1.3 1.3"
        stroke="currentColor"
        strokeLinecap="round"
        strokeWidth="1.4"
      />
    </svg>
  );
}

function PauseIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
      <path
        d="M4.5 3.2v7.6M9.5 3.2v7.6"
        stroke="currentColor"
        strokeLinecap="round"
        strokeWidth="1.8"
      />
    </svg>
  );
}

function PlayIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
      <path
        d="M5 3.4v7.2L10.5 7 5 3.4Z"
        fill="currentColor"
      />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
      <path
        d="M3.2 4.4h7.6M5.3 4.4V3.2h3.4v1.2M4.1 4.4l.5 6.4c.1.7.4 1 1.1 1h2.6c.7 0 1-.3 1.1-1l.5-6.4"
        fill="none"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.3"
      />
    </svg>
  );
}

/* ─── 関係図 — 左に譲 / 中央 SVG 線 / 右に選択肢縦並び ─── */

function Diagram({ listing }: { listing: ListingItem }) {
  const sortedOptions = [...listing.options].sort(
    (a, b) => a.position - b.position,
  );
  const haveH = getHaveBlockHeight(listing.haves.length);
  const optionHeights = sortedOptions.map(getOptionRowHeight);
  const optionsH =
    optionHeights.reduce((sum, h) => sum + h, 0) +
    Math.max(0, optionHeights.length - 1) * OPT_GAP;
  const containerH = Math.max(haveH, optionsH || OPT_SINGLE_H);
  const optionStartY = (containerH - optionsH) / 2;
  const optionTops = optionHeights.map((_, i) => {
    const previous =
      optionHeights.slice(0, i).reduce((sum, h) => sum + h, 0) + i * OPT_GAP;
    return optionStartY + previous;
  });
  const optionYs = optionTops.map((top, i) => top + optionHeights[i] / 2);
  const haveTop = (containerH - haveH) / 2;
  const haveAnchorY = haveTop + haveH / 2;

  const totalW = HAVE_W + SVG_W + RIGHT_W;

  return (
    <div className="overflow-x-auto">
      <div
        className="relative mx-auto"
        style={{
          width: totalW,
          height: containerH,
        }}
      >
        {/* SVG 線（全部実線） */}
        <svg
          width={totalW}
          height={containerH}
          className="pointer-events-none absolute left-0 top-0"
        >
          {sortedOptions.map((opt, i) => (
            <line
              key={opt.id}
              x1={HAVE_W}
              y1={haveAnchorY}
              x2={HAVE_W + SVG_W}
              y2={optionYs[i]}
              stroke="#a695d8"
              strokeWidth={1.8}
              strokeLinecap="round"
              opacity={0.7}
            />
          ))}
        </svg>

        {/* 左カラム：譲群 */}
        <div
          className="absolute left-0"
          style={{
            top: haveTop,
            width: HAVE_W,
            height: haveH,
          }}
        >
          <HaveBlock listing={listing} />
        </div>

        {/* 右カラム：選択肢縦並び */}
        {sortedOptions.map((opt, i) => (
          <div
            key={opt.id}
            className="absolute"
            style={{
              left: HAVE_W + SVG_W,
              top: optionTops[i],
              width: RIGHT_W,
              height: optionHeights[i],
            }}
          >
            <OptionRow option={opt} />
          </div>
        ))}
      </div>
    </div>
  );
}

function getHaveBlockHeight(count: number): number {
  if (count <= 1) return HAVE_SINGLE_H;
  return HAVE_MULTI_BASE_H + (count > 2 ? 10 : 0);
}

function getOptionRowHeight(option: ListingOption): number {
  if (option.isCashOffer) return OPT_CASH_H;
  return option.wishes.length > 1 ? OPT_MULTI_H : OPT_SINGLE_H;
}

function logicLabel(logic: "and" | "or"): string {
  return logic === "and" ? "すべて" : "1pick";
}

function itemLabel(item: ListingHaveItem | ListingWishItem): string {
  return item.characterName ?? item.groupName ?? item.title;
}

function itemHueFromName(name: string): number {
  const code = name.length > 0 ? name.charCodeAt(0) : 63;
  return (Math.abs(code * 17) + 260) % 360;
}

function hasConcreteWishImages(option: ListingOption): boolean {
  return option.wishes.length > 0 && option.wishes.every((w) => !!w.photoUrl);
}

function shouldShowExchangeType(option: ListingOption): boolean {
  return (
    !option.isCashOffer &&
    option.wishes.length > 0 &&
    !hasConcreteWishImages(option)
  );
}

function LogicTag({ logic }: { logic: "and" | "or" }) {
  return (
    <span
      className={`absolute left-1.5 top-1.5 rounded-full px-1.5 py-[1px] text-[8.5px] font-extrabold leading-tight ${
        logic === "and"
          ? "bg-[#a695d8] text-white"
          : "border border-[#a695d855] bg-white text-[#a695d8]"
      }`}
    >
      {logicLabel(logic)}
    </span>
  );
}

function ExchangeChip({ option }: { option: ListingOption }) {
  if (!shouldShowExchangeType(option)) return null;
  return (
    <span
      className="inline-flex rounded-full px-1.5 py-[1px] text-[8.5px] font-extrabold leading-tight text-white"
      style={{
        background:
          option.exchangeType === "same_kind"
            ? "#5fa884"
            : option.exchangeType === "cross_kind"
              ? "#d9826b"
              : "linear-gradient(135deg, #5fa884, #d9826b)",
      }}
    >
      {EXCHANGE_LABEL[option.exchangeType]}
    </span>
  );
}

function HaveBlock({ listing }: { listing: ListingItem }) {
  if (listing.haves.length === 0) {
    return (
      <div className="flex h-full items-center justify-center text-[9px] text-[#3a324a8c]">
        譲 — 0
      </div>
    );
  }

  if (listing.haves.length === 1) {
    return (
      <div className="flex h-full items-center justify-center">
        <ItemThumb item={listing.haves[0]} kind="have" />
      </div>
    );
  }

  return (
    <div className="relative flex h-full flex-col items-center justify-center gap-1 rounded-[12px] border border-[#a8d4e655] bg-[#a8d4e614] px-2 pb-2 pt-5">
      <LogicTag logic={listing.haveLogic} />
      <div className="flex flex-col gap-1">
        {listing.haves.slice(0, 2).map((h) => (
          <ItemThumb key={h.id} item={h} kind="have" />
        ))}
      </div>
      {listing.haves.length > 2 && (
        <span className="text-[8.5px] font-bold leading-none text-[#3a324a8c]">
          +{listing.haves.length - 2}
        </span>
      )}
    </div>
  );
}

/* ─── 選択肢 1 行 ─── */

function OptionRow({ option }: { option: ListingOption }) {
  if (!option.isCashOffer && option.wishes.length > 1) {
    return (
      <div className="relative flex h-full w-full items-center gap-2 rounded-[12px] border border-[#f3c5d466] bg-[#f3c5d412] px-2 pb-2 pt-5">
        <LogicTag logic={option.logic} />
        <div className="flex flex-shrink-0 gap-1">
          {option.wishes.slice(0, 3).map((w) => (
            <ItemThumb key={w.id} item={w} kind="wish" />
          ))}
        </div>
        <div className="min-w-0 flex-1">
          <div className="truncate text-[10px] font-bold text-[#3a324a]">
            {option.wishes
              .map((w) => `${itemLabel(w)} ×${w.qty}`)
              .join(" / ")}
          </div>
          <div className="mt-1 flex items-center gap-1">
            <ExchangeChip option={option} />
            {option.wishes.length > 3 && (
              <span className="text-[8.5px] font-bold text-[#3a324a8c]">
                +{option.wishes.length - 3}
              </span>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full w-full items-center gap-2 px-1 py-1">
      {option.isCashOffer ? (
        <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-md border border-[#7a9a8a55] bg-[#7a9a8a14] text-[16px]">
          💴
        </div>
      ) : (
        <div className="flex flex-shrink-0 gap-0.5">
          {option.wishes[0] && (
            <ItemThumb item={option.wishes[0]} kind="wish" />
          )}
        </div>
      )}
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-1 text-[9.5px]">
          <ExchangeChip option={option} />
        </div>
        <div className="mt-0.5 truncate text-[10px] font-bold text-[#3a324a]">
          {option.isCashOffer
            ? `¥${option.cashAmount?.toLocaleString() ?? "—"}`
            : option.wishes
                .map((w) => `${itemLabel(w)} ×${w.qty}`)
                .join(" / ")}
        </div>
      </div>
    </div>
  );
}

/* ─── アイテムサムネ ─── */

function ItemThumb({
  item,
  kind,
}: {
  item: ListingHaveItem | ListingWishItem;
  kind: "have" | "wish";
}) {
  const name = item.characterName ?? item.groupName ?? item.title;
  const hue = itemHueFromName(name);
  const stripeBg = `repeating-linear-gradient(135deg, hsl(${hue}, 28%, 86%) 0 4px, hsl(${hue}, 28%, 78%) 4px 8px)`;
  const initialShadow = `0 1px 2px hsla(${hue}, 30%, 30%, 0.5)`;
  const hasPhoto = !!item.photoUrl;
  const W = 36;
  const H = 36;
  return (
    <div
      className={`relative flex flex-shrink-0 items-center justify-center overflow-hidden rounded-md border shadow-[0_1px_3px_rgba(58,50,74,0.15)] ${
        kind === "have" ? "border-[#a8d4e6]" : "border-[#f3c5d4]"
      }`}
      style={{
        width: W,
        height: H,
        background: hasPhoto ? "#3a324a" : stripeBg,
      }}
      title={`${item.title} ×${item.qty}`}
    >
      {hasPhoto && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={item.photoUrl!}
          alt={item.title}
          className="absolute inset-0 h-full w-full object-cover"
          loading="lazy"
        />
      )}
      {!hasPhoto && (
        <span
          className="text-[14px] font-extrabold text-white/95"
          style={{ textShadow: initialShadow }}
        >
          {name[0] || "?"}
        </span>
      )}
      <span className="absolute right-0 top-0 rounded-bl-md bg-black/55 px-0.5 text-[7.5px] font-extrabold leading-tight text-white">
        ×{item.qty}
      </span>
    </div>
  );
}
