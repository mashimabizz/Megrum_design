/**
 * iter67.6 改訂：マッチカードを 2 種類に分離
 *
 * - **ListingMatchCard**：個別募集（listing）経由マッチ。条件パターン chip、
 *   定価交換サブバッジ、詳細モーダル開閉ボタン
 * - **SimpleMatchCard**：wish ベースの通常マッチ。
 *
 * MatchCard wrapper が listing 情報の有無で振り分け。
 *
 * 距離表示（現地モード ON 時のみ）：distanceText prop で渡す。
 */

import Link from "next/link";
import type { ReactNode } from "react";
import { useState } from "react";
import { MatchDetailModal } from "./MatchDetailModal";
import { Avatar } from "@/components/common/Avatar";

export type MiniItem = {
  id: string;
  label: string;
  goodsTypeName: string | null;
  photoUrl: string | null;
  hue: number;
};

/**
 * iter104: 関係図に「相手の譲から候補」を写真で並べるため、
 * 各 wish に candidates: 相手の inventory item 配列を持たせる。
 *
 * - my listing context: candidates = 相手 (partner) の inv で、my wish にヒットしたもの
 * - partner listing context: candidates = 私 (me) の inv で、partner の wish にヒットしたもの
 *   （= 私が出せる候補）
 */
export type MatchCardOption = {
  id: string;
  position: number;
  logic: "and" | "or";
  exchangeType: "same_kind" | "cross_kind" | "any";
  isCashOffer: boolean;
  cashAmount: number | null;
  matched: boolean;
  wishes: {
    item: MiniItem;
    qty: number;
    /** iter104: この wish にヒットした「相手側 inv 候補」 */
    candidates: { item: MiniItem; qty: number }[];
  }[];
  /**
   * iter67.8: この選択肢を有効化したときに **追加で** 自分が出すアイテム + qty
   * - 自分の listing：[]（譲は listing 共通なので listing.perOptionMyCommitment 側で）
   * - 相手の listing：option.matchedTheirInvIds × wishQtys（私の inv に対応）
   */
  myAdditionalCommitments: { itemId: string; qty: number }[];
};

export type MatchCardListingInfo = {
  listingId: string;
  haveLogic: "and" | "or";
  haves: { item: MiniItem; qty: number; matched: boolean }[];
  options: MatchCardOption[];
  /** iter67.8: 自分が listing オーナーか（true=私の listing / false=相手の listing） */
  isMyListing: boolean;
  /**
   * iter67.8: 1 選択肢を選ぶごとに **追加で** 自分が出すアイテム + qty
   * - 自分の listing：listing.haveIds × listing.haveQtys（共通）
   * - 相手の listing：[]（私の譲は option ごとに違う）
   */
  perOptionMyCommitment: { itemId: string; qty: number }[];
};

export type MatchCardData = {
  id: string;
  partnerId: string;
  userName: string;
  userHandle: string;
  /** iter125: パートナーのアバター URL */
  userAvatarUrl: string | null;
  myGives: MiniItem[];
  theirGives: MiniItem[];
  matchType: "complete" | "they_want_you" | "you_want_them";
  distance: string;
  exchangeType?: "same_kind" | "cross_kind" | "any";
  listingBadge?: "set" | "any" | null;
  hasCashOffer?: boolean;
  myMatchedListings?: MatchCardListingInfo[];
  partnerMatchedListings?: MatchCardListingInfo[];
  /** iter71-F: 双方向 listing マッチ（自分も相手も個別募集が同時に成立）*/
  bothSidesListingMatch?: boolean;
  /** iter72-B: listing マッチの種類（"both" / "mine_only" / "partner_only" / "none"） */
  listingMatchKind?: "both" | "mine_only" | "partner_only" | "none";
  /** 現地モード ON 時の距離テキスト（例「約 250m」「約 1.2km」） */
  distanceText?: string;
  /** 自分/相手ともに現地交換モードで、日時・範囲が重なった候補 */
  localAvailable?: boolean;
  /**
   * iter67.8：詳細モーダルでの在庫オーバーチェック用。
   * 自分の inv id → 在庫数（quantity）の Map
   */
  myInventoryQty?: Record<string, number>;
};

const EXCHANGE_LABEL: Record<"same_kind" | "cross_kind" | "any", string> = {
  same_kind: "同種のみ",
  cross_kind: "異種のみ",
  any: "どちらでも",
};

type MatchPatternId =
  | "both_conditions"
  | "my_condition"
  | "partner_condition"
  | "no_condition"
  | "wish_mutual";

type MatchPatternMeta = {
  id: MatchPatternId;
  label: string;
  sub: string;
  cta: string;
  borderClass: string;
  shadowClass: string;
  chipClass: string;
  background: string;
};

function getMatchPattern(card: MatchCardData): MatchPatternMeta {
  const hasMyListing = !!card.myMatchedListings?.length;
  const hasPartnerListing = !!card.partnerMatchedListings?.length;

  if (hasMyListing && hasPartnerListing) {
    return {
      id: "both_conditions",
      label: "双方の条件が交差",
      sub: "あなたの条件にも、相手の条件にも候補あり",
      cta: "条件を選んで打診 →",
      borderClass: "border-megrum-lavender",
      shadowClass: "shadow-[0_14px_36px_rgba(166,149,216,0.26)]",
      chipClass:
        "bg-gradient-to-r from-megrum-pink to-megrum-lavender text-white shadow-[0_3px_10px_rgba(166,149,216,0.35)]",
      background:
        "linear-gradient(180deg, rgba(166,149,216,0.16) 0%, rgba(243,197,212,0.10) 45%, rgba(255,255,255,0.95) 100%)",
    };
  }

  if (hasMyListing) {
    return {
      id: "my_condition",
      label: "あなたの条件で候補",
      sub: "相手の譲があなたの条件にヒット",
      cta: "条件を選んで打診 →",
      borderClass: "border-megrum-lavender/55",
      shadowClass: "shadow-[0_10px_28px_rgba(166,149,216,0.18)]",
      chipClass: "bg-megrum-lavender/15 text-megrum-lavender",
      background:
        "linear-gradient(180deg, rgba(166,149,216,0.10) 0%, rgba(255,255,255,0.96) 60%, rgba(255,255,255,1) 100%)",
    };
  }

  if (hasPartnerListing) {
    return {
      id: "partner_condition",
      label: "相手の条件に応えられる",
      sub: "あなたの譲が相手の条件にヒット",
      cta: "条件を選んで打診 →",
      borderClass: "border-megrum-sky/70",
      shadowClass: "shadow-[0_10px_28px_rgba(168,212,230,0.25)]",
      chipClass: "bg-megrum-sky/25 text-[#5c8da8]",
      background:
        "linear-gradient(180deg, rgba(168,212,230,0.18) 0%, rgba(255,255,255,0.96) 58%, rgba(255,255,255,1) 100%)",
    };
  }

  if (card.matchType === "complete") {
    return {
      id: "wish_mutual",
      label: "譲 × wish 双方向",
      sub: "個別条件なしで、お互いの譲と wish が一致",
      cta: "打診する",
      borderClass: "border-megrum-pink/70",
      shadowClass: "shadow-[0_10px_26px_rgba(243,197,212,0.20)]",
      chipClass: "bg-megrum-pink/30 text-[#b66f87]",
      background:
        "linear-gradient(180deg, rgba(243,197,212,0.13) 0%, rgba(255,255,255,0.98) 62%, rgba(255,255,255,1) 100%)",
    };
  }

  return {
    id: "no_condition",
    label: "片方向の候補",
    sub: "どちらかの譲と wish が一致",
    cta: "打診する",
    borderClass: "border-[#3a324a14]",
    shadowClass: "shadow-[0_8px_22px_rgba(58,50,74,0.08)]",
    chipClass: "bg-[#3a324a0a] text-[#3a324a8c]",
    background: "linear-gradient(180deg, #ffffff 0%, #ffffff 100%)",
  };
}

function LocalPossibilityPill({ card }: { card: MatchCardData }) {
  return card.localAvailable ? (
    <span className="inline-flex items-center gap-1 rounded-full bg-megrum-lavender px-2 py-0.5 text-[10px] font-extrabold text-white shadow-[0_3px_10px_rgba(166,149,216,0.35)]">
      <span className="text-[9px]">LIVE</span>
      {card.distanceText ? card.distanceText : "現地OK"}
    </span>
  ) : (
    <span className="rounded-full border border-[#3a324a14] bg-white/85 px-2 py-0.5 text-[10px] font-bold text-[#3a324a8c]">
      全国候補
    </span>
  );
}

function CardShell({
  card,
  featured,
  children,
}: {
  card: MatchCardData;
  featured: boolean;
  children: ReactNode;
}) {
  const pattern = getMatchPattern(card);
  const local = card.localAvailable === true;
  return (
    <div
      className={
        local
          ? "match-card-local-aura rounded-2xl"
          : "rounded-2xl"
      }
    >
      {local && (
        <>
          <span className="match-card-local-spark match-card-local-spark-1" />
          <span className="match-card-local-spark match-card-local-spark-2" />
          <span className="match-card-local-spark match-card-local-spark-3" />
        </>
      )}
      <div
        className={`match-card-inner relative overflow-hidden rounded-2xl border bg-white ${
          local ? "border-[#3a324a14]" : pattern.borderClass
        } ${pattern.shadowClass} ${featured ? "p-4" : "p-3.5"}`}
        style={{ background: local ? "#ffffff" : pattern.background }}
      >
        {children}
      </div>
    </div>
  );
}

/* ─── dispatcher ─────────────────────────────────────── */

export function MatchCard({
  card,
  myAvatarUrl,
  featured = false,
}: {
  card: MatchCardData;
  /** iter125: 自分のアバター URL（モーダル内 MiniAvatar 用） */
  myAvatarUrl: string | null;
  /** 注目マッチ枠では少し大きめに表示 */
  featured?: boolean;
}) {
  const isListingMatch =
    !!(card.myMatchedListings?.length || card.partnerMatchedListings?.length);
  return isListingMatch ? (
    <ListingMatchCard
      card={card}
      myAvatarUrl={myAvatarUrl}
      featured={featured}
    />
  ) : (
    <SimpleMatchCard card={card} featured={featured} />
  );
}

/* ─── 個別募集マッチカード（リッチ） ────────────────── */

function ListingMatchCard({
  card,
  myAvatarUrl,
  featured,
}: {
  card: MatchCardData;
  myAvatarUrl: string | null;
  featured: boolean;
}) {
  const [modalOpen, setModalOpen] = useState(false);
  const pattern = getMatchPattern(card);

  return (
    <>
      <CardShell card={card} featured={featured}>
        {/* Header */}
        <div className="flex items-start gap-2">
          <Link
            href={`/users/${card.partnerId}`}
            className="flex min-w-0 flex-1 items-center gap-2 rounded-xl transition-all active:scale-[0.99]"
          >
            <Avatar
              url={card.userAvatarUrl}
              fallbackName={card.userName}
              size={featured ? 32 : 30}
              variant="circle"
            />
            <div className="min-w-0 flex-1">
              <div className="truncate text-[12px] font-bold text-gray-900">
                @{card.userHandle}
              </div>
              <div className="mt-0.5 text-[9.5px] tabular-nums text-gray-500">
                {card.distance}
              </div>
            </div>
          </Link>
          <span
            className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${pattern.chipClass}`}
          >
            {pattern.label}
          </span>
        </div>

        {/* Trade preview */}
        <div className="mt-3 grid grid-cols-[1fr_auto_1fr] items-center gap-2.5 rounded-2xl bg-[#a8d4e614] p-2.5">
          <SidePanel
            label={`相手の譲（${card.theirGives.length}）`}
            items={card.theirGives}
            align="left"
            featured={featured}
          />
          <div className="flex flex-col items-center gap-1">
            <ArrowDot color="#a695d8" dir="right" />
            <ArrowDot color="#a8d4e6" dir="left" />
          </div>
          <SidePanel
            label={`あなたの譲（${card.myGives.length}）`}
            items={card.myGives}
            align="right"
            accent="#f3c5d4cc"
            featured={featured}
          />
        </div>

        {/* バッジ群 */}
        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          <LocalPossibilityPill card={card} />
          {card.hasCashOffer && (
            <span className="rounded-full border border-[#7a9a8a55] bg-[#7a9a8a14] px-2 py-0.5 text-[10px] font-bold text-[#7a9a8a]">
              💴 定価交換も受付
            </span>
          )}
          <button
            type="button"
            onClick={() => setModalOpen(true)}
            className="ml-auto inline-flex items-center gap-0.5 rounded-full bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-2.5 py-[3px] text-[10px] font-extrabold text-white shadow-[0_2px_6px_rgba(166,149,216,0.35)] active:scale-[0.97]"
          >
            詳細 →
          </button>
        </div>

        {/* CTA — iter72-C: partner_only は相手の listing 条件をプリフィルした打診へ */}
        <div className="mt-3">
          <button
            type="button"
            onClick={() => setModalOpen(true)}
            className="w-full rounded-xl bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-3 py-2.5 text-center text-[13px] font-bold tracking-[0.4px] text-white shadow-[0_4px_12px_rgba(166,149,216,0.4)] transition-all duration-150 active:scale-[0.97]"
          >
            {pattern.cta}
          </button>
        </div>
      </CardShell>

      {modalOpen && (
        <MatchDetailModal
          partnerHandle={card.userHandle}
          partnerId={card.partnerId}
          partnerAvatarUrl={card.userAvatarUrl}
          myAvatarUrl={myAvatarUrl}
          myListings={card.myMatchedListings ?? []}
          partnerListings={card.partnerMatchedListings ?? []}
          myInventoryQty={card.myInventoryQty ?? {}}
          onClose={() => setModalOpen(false)}
        />
      )}
    </>
  );
}

/* ─── 通常マッチカード（シンプル） ──────────────────── */

function SimpleMatchCard({
  card,
  featured,
}: {
  card: MatchCardData;
  featured: boolean;
}) {
  const pattern = getMatchPattern(card);

  return (
    <CardShell card={card} featured={featured}>
      <div className="relative flex items-start gap-2">
        <Link
          href={`/users/${card.partnerId}`}
          className="flex min-w-0 flex-1 items-center gap-2 rounded-xl transition-all active:scale-[0.99]"
        >
          <Avatar
            url={card.userAvatarUrl}
            fallbackName={card.userName}
            size={featured ? 32 : 30}
            variant="circle"
          />
          <div className="min-w-0 flex-1">
            <div className="truncate text-[12px] font-bold text-gray-900">
              @{card.userHandle}
            </div>
            <div className="mt-0.5 text-[9.5px] tabular-nums text-gray-500">
              {card.distance}
            </div>
          </div>
        </Link>
        <span
          className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${pattern.chipClass}`}
        >
          {pattern.label}
        </span>
      </div>

      <div className="mt-3 grid grid-cols-[1fr_auto_1fr] items-center gap-2.5 rounded-2xl bg-[#a8d4e614] p-2.5">
        <SidePanel
          label={`相手の譲（${card.theirGives.length}）`}
          items={card.theirGives}
          align="left"
          featured={featured}
        />
        <div className="flex flex-col items-center gap-1">
          <ArrowDot color="#a695d8" dir="right" />
          <ArrowDot color="#a8d4e6" dir="left" />
        </div>
        <SidePanel
          label={`あなたの譲（${card.myGives.length}）`}
          items={card.myGives}
          align="right"
          accent="#f3c5d4cc"
          featured={featured}
        />
      </div>

      {card.exchangeType && card.exchangeType !== "any" && (
        <div className="mt-2 flex items-center gap-1.5">
          <span
            className="rounded-full px-2 py-0.5 text-[10px] font-bold text-white"
            style={{
              background:
                card.exchangeType === "same_kind"
                  ? "#5fa884"
                  : "#d9826b",
            }}
          >
            {EXCHANGE_LABEL[card.exchangeType]}
          </span>
          <span className="text-[9.5px] text-gray-500">
            ※ 相手の自己申告
          </span>
        </div>
      )}

      <div className="mt-2 flex flex-wrap items-center gap-1.5">
        <LocalPossibilityPill card={card} />
      </div>

      <div className="mt-3">
        <Link
          href={`/propose/${card.partnerId}?matchType=${card.matchType}`}
          className="block w-full rounded-xl bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-3 py-2.5 text-center text-[13px] font-bold tracking-[0.4px] text-white shadow-[0_4px_12px_rgba(166,149,216,0.4)] transition-all duration-150 active:scale-[0.97]"
        >
          {pattern.cta}
        </Link>
      </div>
    </CardShell>
  );
}

/* ─── shared sub-components ─────────────────────────── */

function SidePanel({
  label,
  items,
  align,
  accent,
  featured = false,
}: {
  label: string;
  items: MiniItem[];
  align: "left" | "right";
  accent?: string;
  featured?: boolean;
}) {
  return (
    <div>
      <div
        className={`mb-1.5 px-1 text-[9.5px] font-bold tracking-[0.6px] text-gray-500 ${
          align === "right" ? "text-right" : "text-left"
        }`}
      >
        {label}
      </div>
      {items.length === 0 ? (
        <div
          className={`text-[10px] italic text-gray-400 ${
            align === "right" ? "text-right" : "text-left"
          } px-1`}
        >
          —
        </div>
      ) : (
        <div
          className={`flex flex-wrap gap-1 ${
            align === "right" ? "justify-end" : "justify-start"
          } px-1`}
        >
          {items.slice(0, 4).map((it) => (
            <Tcg key={it.id} item={it} accent={accent} featured={featured} />
          ))}
          {items.length > 4 && (
            <div className="flex h-7 items-end px-0.5 text-[10px] text-gray-500">
              +{items.length - 4}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function Tcg({
  item,
  accent,
  featured = false,
}: {
  item: MiniItem;
  accent?: string;
  featured?: boolean;
}) {
  const stripeBg = `repeating-linear-gradient(135deg, hsl(${item.hue}, 28%, 86%) 0 5px, hsl(${item.hue}, 28%, 78%) 5px 10px)`;
  const initialShadow = `0 1px 3px hsla(${item.hue}, 30%, 30%, 0.5)`;
  const hasPhoto = !!item.photoUrl;

  return (
    <div
      className="relative overflow-hidden rounded-md border border-white/40 shadow-[0_1px_3px_rgba(58,50,74,0.15)]"
      style={{
        width: featured ? 34 : 28,
        height: featured ? 46 : 38,
        background: hasPhoto ? "#3a324a" : stripeBg,
      }}
      title={`${item.label}${item.goodsTypeName ? ` · ${item.goodsTypeName}` : ""}`}
    >
      {hasPhoto && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={item.photoUrl!}
          alt={item.label}
          className="absolute inset-0 h-full w-full object-cover"
          loading="lazy"
        />
      )}
      {!hasPhoto && (
        <div
          className="absolute inset-0 flex items-center justify-center text-[14px] font-extrabold text-white/95"
          style={{ textShadow: initialShadow }}
        >
          {item.label[0] || "?"}
        </div>
      )}
      {accent && !hasPhoto && (
        <div
          className="absolute inset-x-0 bottom-0 h-1"
          style={{ background: accent }}
        />
      )}
    </div>
  );
}

function ArrowDot({
  color,
  dir,
}: {
  color: string;
  dir: "left" | "right";
}) {
  return (
    <div
      className="flex h-5 w-5 items-center justify-center rounded-full text-white"
      style={{
        background: color,
        boxShadow: `0 2px 5px ${color}80`,
      }}
    >
      <svg width="10" height="10" viewBox="0 0 10 10">
        {dir === "right" ? (
          <path
            d="M2 5h6m-2-2l2 2-2 2"
            stroke="#fff"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
            fill="none"
          />
        ) : (
          <path
            d="M8 5H2m2-2L2 5l2 2"
            stroke="#fff"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
            fill="none"
          />
        )}
      </svg>
    </div>
  );
}
