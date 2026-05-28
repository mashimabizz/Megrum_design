"use client";

import dynamic from "next/dynamic";
import Link from "next/link";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { extendProposal, respondToProposal } from "@/app/propose/actions";

const MapPicker = dynamic(() => import("@/components/map/MapPicker"), {
  ssr: false,
  loading: () => (
    <div className="flex h-full w-full items-center justify-center bg-[#e8eef0] text-[11px] text-[#3a324a8c]">
      地図を読み込み中…
    </div>
  ),
});

export type ProposalItem = {
  id: string;
  label: string;
  title: string;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  qty: number;
};

export type ProposalMeetupCandidate = {
  startAt: string;
  endAt: string;
  placeName: string;
  lat: number;
  lng: number;
  mode: "today" | "scheduled";
};

export type ProposalDetail = {
  id: string;
  isReceiver: boolean;
  isSender: boolean;
  matchType: "perfect" | "forward" | "backward";
  status:
    | "sent"
    | "negotiating"
    | "agreement_one_side"
    | "agreed"
    | "completed"
    | "rejected"
    | "expired"
    | "cancelled";
  senderItems: ProposalItem[];
  receiverItems: ProposalItem[];
  message: string;
  messageTone: "standard" | "casual" | "polite" | null;
  meetupStartAt: string | null;
  meetupEndAt: string | null;
  meetupPlaceName: string | null;
  meetupLat: number | null;
  meetupLng: number | null;
  meetupCandidates: ProposalMeetupCandidate[];
  exposeCalendar: boolean;
  cashOffer: boolean;
  cashAmount: number | null;
  listingId: string | null;
  expiresAt: string | null;
  lastActionAt: string | null;
  createdAt: string;
  rejectedTemplate: string | null;
  partner: {
    id: string;
    handle: string;
    displayName: string;
    primaryArea: string | null;
  };
  /** iter77-B: 自動添付情報 */
  partnerRatingAvg: number | null;
  partnerRatingCount: number;
  partnerTradeCount: number;
  /** 提案された待ち合わせ時間が自分の AW と重なるか */
  matchAw: boolean;
  /** 相手の最新の服装写真（合意済以降にアップされたもの） */
  partnerOutfitPhotoUrl: string | null;
  /** iter78-E: 延長回数（最大 3） */
  extensionCount: number;
};

const STATUS_LABEL: Record<ProposalDetail["status"], string> = {
  sent: "未応答",
  negotiating: "ネゴ中",
  agreement_one_side: "一方合意",
  agreed: "合意済",
  completed: "完了",
  rejected: "拒否",
  expired: "期限切れ",
  cancelled: "取消",
};

const STATUS_COLOR: Record<ProposalDetail["status"], string> = {
  sent: "bg-[#a8d4e6] text-white",
  negotiating: "bg-[#f3c5d4] text-[#3a324a]",
  agreement_one_side: "bg-[#a695d8] text-white",
  agreed: "bg-emerald-500 text-white",
  completed: "bg-emerald-500 text-white",
  rejected: "bg-[#3a324a14] text-[#3a324a8c]",
  expired: "bg-[#3a324a14] text-[#3a324a8c]",
  cancelled: "bg-[#3a324a14] text-[#3a324a8c]",
};

const REJECT_TEMPLATES: { id: string; label: string }[] = [
  { id: "ratio", label: "条件が合わない" },
  { id: "timing", label: "時間が合わない" },
  { id: "place", label: "場所が遠い" },
  { id: "no_reason", label: "理由非開示" },
];
const INITIAL_RENDER_NOW_MS = Date.now();

export function ProposalDetailView({ detail }: { detail: ProposalDetail }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [rejectMode, setRejectMode] = useState(false);
  const fallbackMeetup =
    detail.meetupStartAt &&
    detail.meetupEndAt &&
    detail.meetupPlaceName &&
    detail.meetupLat != null &&
    detail.meetupLng != null
      ? {
          startAt: detail.meetupStartAt,
          endAt: detail.meetupEndAt,
          placeName: detail.meetupPlaceName,
          lat: detail.meetupLat,
          lng: detail.meetupLng,
          mode: "scheduled" as const,
        }
      : null;
  const meetupCandidates =
    detail.meetupCandidates.length > 0
      ? detail.meetupCandidates
      : fallbackMeetup
        ? [fallbackMeetup]
        : [];
  const primaryMeetup = meetupCandidates[0] ?? null;

  const canRespond =
    detail.isReceiver &&
    (detail.status === "sent" || detail.status === "negotiating");

  function handleAction(
    action: "accept" | "reject" | "negotiate",
    rejectedTemplate?: string,
  ) {
    setError(null);
    startTransition(async () => {
      const r = await respondToProposal({
        id: detail.id,
        action,
        rejectedTemplate,
      });
      if (r?.error) {
        setError(r.error);
        return;
      }
      router.refresh();
    });
  }

  // iter78-E: 期限延長
  function handleExtend() {
    if (!confirm("打診の期限を 7 日間延長しますか？")) return;
    setError(null);
    startTransition(async () => {
      const r = await extendProposal({ id: detail.id });
      if (r?.error) {
        setError(r.error);
        return;
      }
      router.refresh();
    });
  }

  return (
    <div className="space-y-4">
      {/* ヘッダーカード（送信者プロフィール） */}
      <section className="rounded-2xl border border-[#3a324a14] bg-white p-3.5">
        <div className="mb-2 flex items-center gap-2">
          <span
            className={`rounded-full px-2 py-[2px] text-[9.5px] font-extrabold tracking-[0.3px] ${STATUS_COLOR[detail.status]}`}
          >
            {STATUS_LABEL[detail.status]}
          </span>
          {detail.cashOffer && (
            <span className="rounded-full bg-[#7a9a8a14] px-2 py-[2px] text-[10px] font-bold text-[#7a9a8a]">
              💴 定価交換
            </span>
          )}
          <span
            className={`rounded-[3px] px-1.5 py-[1px] text-[9px] font-bold tracking-[0.3px] text-white ${
              detail.isReceiver ? "bg-[#a695d8]" : "bg-[#a8d4e6]"
            }`}
          >
            {detail.isReceiver ? "←受信" : "送信→"}
          </span>
          <div className="flex-1" />
          {detail.expiresAt && (
            <ExpiresLabel
              iso={detail.expiresAt}
              status={detail.status}
              nowMs={INITIAL_RENDER_NOW_MS}
            />
          )}
        </div>

        <div className="flex items-center gap-2.5">
          <div className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-full bg-[linear-gradient(135deg,#f3c5d455,#a695d855)] text-[15px] font-extrabold text-[#3a324a]">
            {detail.partner.displayName[0] || "?"}
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-[14px] font-extrabold text-[#3a324a]">
              @{detail.partner.handle}
            </div>
            <div className="mt-0.5 flex flex-wrap items-center gap-1.5 text-[10.5px] text-[#3a324a8c]">
              {detail.partnerRatingAvg !== null ? (
                <span className="font-bold text-[#3a324a]">
                  ★{detail.partnerRatingAvg.toFixed(1)}
                  <span className="ml-0.5 text-[9.5px] text-[#3a324a8c]">
                    ({detail.partnerRatingCount})
                  </span>
                </span>
              ) : (
                <span className="text-[#3a324a8c]">★— (新規)</span>
              )}
              <span>·</span>
              <span>取引 {detail.partnerTradeCount}回</span>
              {detail.partner.primaryArea && (
                <>
                  <span>·</span>
                  <span>{detail.partner.primaryArea}</span>
                </>
              )}
            </div>
          </div>
          <Link
            href={`/users/${detail.partner.id}`}
            className="flex-shrink-0 rounded-full border border-[#a695d855] bg-white px-3 py-1.5 text-[10.5px] font-bold text-[#a695d8] active:scale-[0.97]"
          >
            プロフ
          </Link>
        </div>
      </section>

      {/* iter78-E: 期限警告バナー（残 3 日以下のときのみ表示） */}
      <ExpireBanner
        expiresAt={detail.expiresAt}
        extensionCount={detail.extensionCount}
        status={detail.status}
        onExtend={handleExtend}
        pending={pending}
        nowMs={INITIAL_RENDER_NOW_MS}
      />

      {/* iter77-B: 提案内容を統合カード化（紫グラデ・「📩 提案内容」バッジ・待ち合わせ内包） */}
      <section
        className="overflow-hidden rounded-[16px] border-[1.5px] border-[#a695d840] p-4"
        style={{
          background:
            "linear-gradient(135deg, rgba(166,149,216,0.10), rgba(168,212,230,0.10))",
        }}
      >
        <div className="mb-2.5 text-[9.5px] font-extrabold tracking-[0.5px] text-[#a695d8]">
          📩 提案内容
        </div>

        {/* 受け取る */}
        <div className="mb-3">
          <div className="mb-1.5 text-[10.5px] font-bold text-[#3a324a8c]">
            あなたが受け取る
          </div>
          {detail.cashOffer && detail.isReceiver ? (
            <div className="rounded-md border border-[#7a9a8a55] bg-[#7a9a8a14] p-2.5">
              <div className="text-[9.5px] font-bold text-[#7a9a8a]">
                💴 定価交換
              </div>
              <div className="mt-0.5 text-[15px] font-extrabold tabular-nums text-[#3a324a]">
                ¥{detail.cashAmount?.toLocaleString() ?? "—"}
              </div>
            </div>
          ) : (
            <ItemList
              items={
                detail.isReceiver ? detail.senderItems : detail.receiverItems
              }
              accent="have"
            />
          )}
        </div>

        <div className="my-1.5 flex items-center justify-center text-[#a695d8]">
          <svg width="22" height="22" viewBox="0 0 22 22">
            <path
              d="M5 8h12M14 4l4 4-4 4M17 14H5M8 18l-4-4 4-4"
              stroke="#a695d8"
              strokeWidth="1.6"
              fill="none"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>

        {/* 出す */}
        <div className="mb-3">
          <div className="mb-1.5 text-[10.5px] font-bold text-[#3a324a8c]">
            あなたが出す
          </div>
          {detail.cashOffer && detail.isSender ? (
            <div className="rounded-md border border-[#7a9a8a55] bg-[#7a9a8a14] p-2.5">
              <div className="text-[9.5px] font-bold text-[#7a9a8a]">
                💴 定価交換
              </div>
              <div className="mt-0.5 text-[15px] font-extrabold tabular-nums text-[#3a324a]">
                ¥{detail.cashAmount?.toLocaleString() ?? "—"}
              </div>
            </div>
          ) : (
            <ItemList
              items={
                detail.isReceiver ? detail.receiverItems : detail.senderItems
              }
              accent="wish"
            />
          )}
        </div>

        {/* 待ち合わせ（提案内包） */}
        <div className="mt-3 overflow-hidden rounded-[10px] border border-[#a695d833] bg-white/70">
          <div className="flex flex-wrap items-center gap-1.5 px-3 pb-1 pt-2.5">
            <span className="rounded-full bg-white px-2 py-[2px] text-[9.5px] font-extrabold tracking-[0.4px] text-[#a695d8]">
              📍 交換できる候補
            </span>
            {detail.matchAw && (
              <span
                className="rounded-full px-2 py-[2px] text-[9px] font-extrabold tracking-[0.3px] text-white"
                style={{
                  background:
                    "linear-gradient(135deg, #a695d8, #f3c5d4)",
                }}
              >
                ★ あなたのAWと一致
              </span>
            )}
          </div>
          <div className="space-y-2 px-3 pb-2.5">
            {meetupCandidates.length > 0 ? (
              meetupCandidates.map((candidate, index) => (
                <div
                  key={`${candidate.startAt}-${candidate.placeName}-${index}`}
                  className={`rounded-[10px] border px-3 py-2 ${
                    index === 0
                      ? "border-[#a695d855] bg-[#a695d80d]"
                      : "border-[#3a324a14] bg-white"
                  }`}
                >
                  <div className="mb-1 flex items-center gap-1.5">
                    <span className="rounded-full bg-white px-2 py-[2px] text-[9px] font-extrabold text-[#a695d8]">
                      候補{index + 1}
                    </span>
                    {index === 0 && (
                      <span className="text-[9px] font-bold text-[#3a324a8c]">
                        主候補
                      </span>
                    )}
                  </div>
                  <div className="text-[13px] font-extrabold tabular-nums text-[#3a324a]">
                    {formatRange(candidate.startAt, candidate.endAt)}
                  </div>
                  <div className="text-[11.5px] font-bold text-[#3a324a]">
                    📍 {candidate.placeName}
                  </div>
                </div>
              ))
            ) : (
              <div className="text-[13px] font-bold text-[#3a324a8c]">—</div>
            )}
          </div>
          {primaryMeetup && (
            <div className="h-[140px] w-full border-t border-[#3a324a14]">
              <MapPicker
                center={[primaryMeetup.lat, primaryMeetup.lng]}
                radiusM={120}
                onCenterChange={() => {}}
                className="h-full w-full"
              />
            </div>
          )}
        </div>
      </section>

      {/* メッセージ */}
      <Section
        label="メッセージ"
        hint={
          detail.messageTone === "casual"
            ? "カジュアル"
            : detail.messageTone === "polite"
              ? "丁寧"
              : detail.messageTone === "standard"
                ? "標準"
                : undefined
        }
      >
        <pre className="whitespace-pre-wrap break-words rounded-2xl border border-[#3a324a14] bg-white p-3 text-[13px] leading-relaxed text-[#3a324a]">
          {detail.message || "（本文なし）"}
        </pre>
      </Section>

      {/* iter77-B: 自動添付情報 */}
      <Section label="自動添付情報">
        <div className="rounded-2xl border border-[#3a324a14] bg-white px-3 py-1">
          <AttachRow
            label="評価サマリ"
            value={
              detail.partnerRatingAvg !== null
                ? `★${detail.partnerRatingAvg.toFixed(1)} ・ 取引${detail.partnerTradeCount}回`
                : `★— (新規) ・ 取引${detail.partnerTradeCount}回`
            }
          />
          <AttachRow
            label="相手の服装写真"
            value={
              detail.partnerOutfitPhotoUrl
                ? "共有済（取引チャットで確認）"
                : "未共有（合意後に共有）"
            }
          />
          <AttachRow
            label="スケジュール共有"
            value={detail.exposeCalendar ? "ON" : "OFF"}
            tone={detail.exposeCalendar ? "lavender" : "mute"}
            // iter146：共有 ON のとき相手のスケジュール表示への導線を出す
            action={
              detail.exposeCalendar
                ? {
                    href: `/proposals/${detail.id}/schedules`,
                    label: "スケジュールを表示する",
                  }
                : undefined
            }
            isLast={!detail.listingId && !detail.rejectedTemplate}
          />
          {detail.listingId && (
            <AttachRow
              label="個別募集経由"
              value={`listing #${detail.listingId.slice(0, 8)}`}
              tag="@Megrum"
              isLast={!detail.rejectedTemplate}
            />
          )}
          {detail.rejectedTemplate && (
            <AttachRow
              label="拒否理由"
              value={
                REJECT_TEMPLATES.find((t) => t.id === detail.rejectedTemplate)
                  ?.label ?? detail.rejectedTemplate
              }
              tone="warn"
              isLast
            />
          )}
        </div>
      </Section>

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* iter77-B: 受信者向け CTA — モックアップ準拠で縦 3 つ */}
      {canRespond && !rejectMode && (
        <div className="space-y-2">
          <button
            type="button"
            disabled={pending}
            onClick={() => handleAction("accept")}
            className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[15px] text-center text-[14px] font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)] disabled:opacity-50"
          >
            ✓ 承諾する
          </button>
          <button
            type="button"
            disabled={pending}
            onClick={() => handleAction("negotiate")}
            className="block w-full rounded-[14px] border-[1.5px] border-[#a695d8] bg-white px-6 py-[14px] text-center text-[14px] font-bold tracking-[0.3px] text-[#a695d8] disabled:opacity-50"
          >
            反対提案する（ネゴ）
          </button>
          <button
            type="button"
            disabled={pending}
            onClick={() => setRejectMode(true)}
            className="block w-full px-6 py-3 text-center text-[13px] font-semibold text-[#3a324a8c] disabled:opacity-50"
          >
            拒否する
          </button>
        </div>
      )}

      {canRespond && rejectMode && (
        <div className="space-y-2 rounded-2xl border border-[#d9826b55] bg-[#fff5f0] p-3">
          <div className="text-[12px] font-bold text-[#d9826b]">
            拒否理由を選んでください（任意）
          </div>
          <div className="grid grid-cols-2 gap-1.5">
            {REJECT_TEMPLATES.map((t) => (
              <button
                key={t.id}
                type="button"
                disabled={pending}
                onClick={() => handleAction("reject", t.id)}
                className="rounded-[10px] border border-[#3a324a14] bg-white px-2 py-2 text-[11.5px] font-bold text-[#3a324a] disabled:opacity-50"
              >
                {t.label}
              </button>
            ))}
          </div>
          <button
            type="button"
            disabled={pending}
            onClick={() => handleAction("reject")}
            className="block w-full rounded-[10px] bg-[#d9826b] px-3 py-2 text-center text-[11.5px] font-bold text-white disabled:opacity-50"
          >
            理由なしで拒否を確定
          </button>
          <button
            type="button"
            onClick={() => setRejectMode(false)}
            className="block w-full text-center text-[10.5px] text-[#3a324a8c]"
          >
            ← 戻る
          </button>
        </div>
      )}

      {/* 合意済 / ネゴ中 → 取引チャットへの導線（双方向） */}
      {(detail.status === "agreed" ||
        detail.status === "negotiating" ||
        detail.status === "agreement_one_side") && (
        <Link
          href={`/transactions/${detail.id}`}
          className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-sm font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)] active:scale-[0.97]"
        >
          {detail.status === "agreed"
            ? "💬 取引チャットへ進む →"
            : "💬 ネゴチャットへ進む →"}
        </Link>
      )}

      {/* 送信者向けの状態表示 */}
      {detail.isSender && (
        <div className="rounded-2xl border border-[#3a324a14] bg-[#fbf9fc] p-3 text-[11.5px] leading-relaxed text-[#3a324a8c]">
          {detail.status === "sent"
            ? "相手の応答を待っています。期限切れまでに応答がなければ自動で expired になります。"
            : detail.status === "negotiating"
              ? "ネゴ中です。チャットで条件を相談できます。"
              : detail.status === "agreed"
                ? "合意済 ✓ — 取引チャットで当日の段取りを進めましょう。"
                : detail.status === "rejected"
                  ? "拒否されました。"
                  : detail.status === "expired"
                    ? "期限切れになりました。"
                    : detail.status === "cancelled"
                      ? "取消されました。"
                      : ""}
        </div>
      )}
    </div>
  );
}

/* ─── sub-components ─── */

/* iter78-E: 期限警告バナー（残 3 日以下のときに目立つ表示 + 延長ボタン） */
function ExpireBanner({
  expiresAt,
  extensionCount,
  status,
  onExtend,
  pending,
  nowMs,
}: {
  expiresAt: string | null;
  extensionCount: number;
  status: ProposalDetail["status"];
  onExtend: () => void;
  pending: boolean;
  nowMs: number;
}) {
  if (!expiresAt) return null;
  if (
    status !== "sent" &&
    status !== "negotiating" &&
    status !== "agreement_one_side"
  )
    return null;

  const remainMs = new Date(expiresAt).getTime() - nowMs;
  const remainDays = Math.ceil(remainMs / (1000 * 60 * 60 * 24));
  if (remainDays > 3) return null;

  const tone =
    remainDays <= 1 ? "warn" : remainDays <= 2 ? "amber" : "lavender";
  const bgClass =
    tone === "warn"
      ? "border-[#d9826b80] bg-[#fff5f0]"
      : tone === "amber"
        ? "border-amber-300 bg-amber-50"
        : "border-[#a695d855] bg-[#a695d80a]";
  const labelClass =
    tone === "warn"
      ? "text-[#d9826b]"
      : tone === "amber"
        ? "text-amber-700"
        : "text-[#a695d8]";
  const iconText = tone === "warn" ? "⚠️" : "⏰";
  const headlineText =
    remainDays <= 0
      ? "本日期限切れ"
      : remainDays === 1
        ? "あと 1 日で期限切れ"
        : `あと ${remainDays} 日で期限切れ`;
  const canExtend = extensionCount < 3;

  return (
    <div
      className={`flex items-center gap-2.5 rounded-2xl border px-3 py-2.5 ${bgClass}`}
    >
      <span className="text-[16px]">{iconText}</span>
      <div className="min-w-0 flex-1">
        <div className={`text-[12px] font-extrabold ${labelClass}`}>
          {headlineText}
        </div>
        <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">
          延長 {extensionCount}/3 回 ・ 早めに承諾／反対提案／延長を
        </div>
      </div>
      <button
        type="button"
        onClick={onExtend}
        disabled={pending || !canExtend}
        className={`flex-shrink-0 rounded-full px-3 py-1.5 text-[11px] font-extrabold tracking-[0.3px] text-white shadow-[0_2px_5px_rgba(0,0,0,0.15)] disabled:opacity-50 ${
          tone === "warn"
            ? "bg-[#d9826b]"
            : tone === "amber"
              ? "bg-amber-500"
              : "bg-[#a695d8]"
        }`}
      >
        {canExtend ? "+7日延長" : "延長上限"}
      </button>
    </div>
  );
}

function ExpiresLabel({
  iso,
  status,
  nowMs,
}: {
  iso: string;
  status: ProposalDetail["status"];
  nowMs: number;
}) {
  if (status !== "sent" && status !== "negotiating") return null;
  const days = Math.max(
    0,
    Math.ceil((new Date(iso).getTime() - nowMs) / (1000 * 60 * 60 * 24)),
  );
  return (
    <span
      className={`text-[10px] tabular-nums ${
        days <= 1 ? "font-bold text-[#d9826b]" : "text-[#3a324a8c]"
      }`}
    >
      残 {days}日
    </span>
  );
}

function Section({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="mb-1.5 flex items-baseline justify-between px-1">
        <span className="text-[10.5px] font-bold uppercase tracking-[0.6px] text-[#3a324a8c]">
          {label}
        </span>
        {hint && (
          <span className="text-[9.5px] font-bold text-[#a695d8]">{hint}</span>
        )}
      </div>
      {children}
    </div>
  );
}

/**
 * iter77-B: モックアップ風の縦リスト（アイテム名 + qty バッジ）
 */
function ItemList({
  items,
  accent,
}: {
  items: ProposalItem[];
  accent: "have" | "wish";
}) {
  if (items.length === 0) {
    return (
      <div className="rounded-md border border-dashed border-[#3a324a14] bg-white/40 px-3 py-2 text-[11px] italic text-[#3a324a4d]">
        —
      </div>
    );
  }
  return (
    <div className="space-y-1.5">
      {items.map((it) => {
        const hue =
          Math.abs(
            [...it.label].reduce((s, c) => s + c.charCodeAt(0), 0) ?? 0,
          ) % 360;
        const stripeBg = `repeating-linear-gradient(135deg, hsl(${hue}, 35%, 78%) 0 5px, hsl(${hue}, 35%, 70%) 5px 10px)`;
        const initialShadow = `0 1px 3px hsla(${hue}, 30%, 30%, 0.5)`;
        const hasPhoto = !!it.photoUrl;
        return (
          <div
            key={it.id}
            className="flex items-center gap-2.5 rounded-[10px] bg-white/70 px-2.5 py-1.5"
          >
            <div
              className={`relative flex h-[40px] w-[28px] flex-shrink-0 items-center justify-center overflow-hidden rounded-[5px] border ${
                accent === "have" ? "border-[#a8d4e6]" : "border-[#f3c5d4]"
              }`}
              style={{ background: hasPhoto ? "#3a324a" : stripeBg }}
            >
              {hasPhoto && (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={it.photoUrl!}
                  alt={it.label}
                  className="absolute inset-0 h-full w-full object-cover"
                  loading="lazy"
                />
              )}
              {!hasPhoto && (
                <span
                  className="text-[14px] font-extrabold text-white/95"
                  style={{ textShadow: initialShadow }}
                >
                  {it.label[0] || "?"}
                </span>
              )}
            </div>
            <span className="min-w-0 flex-1 truncate text-[13px] font-bold text-[#3a324a]">
              {it.label}
              {it.goodsTypeName && (
                <span className="ml-1.5 text-[10.5px] font-medium text-[#3a324a8c]">
                  {it.goodsTypeName}
                </span>
              )}
            </span>
            <span className="flex-shrink-0 text-[13px] font-extrabold tabular-nums text-[#a695d8]">
              ×{it.qty}
            </span>
          </div>
        );
      })}
    </div>
  );
}

/**
 * iter77-B: 自動添付情報の 1 行（ラベル ・ 値 ・ 任意でタグ）
 */
function AttachRow({
  label,
  value,
  tag,
  tone = "ink",
  action,
  isLast,
}: {
  label: string;
  value: string;
  tag?: string;
  tone?: "ink" | "lavender" | "warn" | "mute";
  /** iter146：行内に副次的なリンクを置く（例：スケジュール表示） */
  action?: { href: string; label: string };
  isLast?: boolean;
}) {
  const valueColor =
    tone === "lavender"
      ? "text-[#a695d8]"
      : tone === "warn"
        ? "text-[#d9826b]"
        : tone === "mute"
          ? "text-[#3a324a8c]"
          : "text-[#3a324a]";
  return (
    <div
      className={`flex items-center gap-2 py-1.5 text-[11.5px] ${
        isLast ? "" : "border-b border-[#3a324a08]"
      }`}
    >
      <span className="w-[110px] flex-shrink-0 text-[#3a324a8c]">{label}</span>
      <span className={`flex-1 font-bold ${valueColor}`}>{value}</span>
      {action && (
        <Link
          href={action.href}
          className="flex-shrink-0 rounded-full bg-[#a695d8] px-2.5 py-[3px] text-[10px] font-extrabold tracking-[0.2px] text-white shadow-[0_2px_6px_rgba(166,149,216,0.33)] transition-all active:scale-[0.97]"
        >
          {action.label}
        </Link>
      )}
      {tag && (
        <span className="rounded-full bg-[#a695d814] px-2 py-[2px] text-[9px] font-extrabold text-[#a695d8]">
          {tag}
        </span>
      )}
    </div>
  );
}

function formatRange(startIso: string, endIso: string): string {
  const tokyoParts = (iso: string) => {
    const parts = new Intl.DateTimeFormat("ja-JP-u-ca-gregory", {
      timeZone: "Asia/Tokyo",
      year: "numeric",
      month: "numeric",
      day: "numeric",
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23",
    }).formatToParts(new Date(iso));
    const get = (type: string) =>
      parts.find((part) => part.type === type)?.value ?? "";
    return {
      month: get("month"),
      day: get("day"),
      weekday: get("weekday"),
      hour: get("hour"),
      minute: get("minute"),
      dateKey: `${get("year")}-${get("month")}-${get("day")}`,
    };
  };
  const s = tokyoParts(startIso);
  const e = tokyoParts(endIso);
  const sameDay = s.dateKey === e.dateKey;
  const dateFmt = (d: ReturnType<typeof tokyoParts>) =>
    `${d.month}/${d.day}(${d.weekday})`;
  const timeFmt = (d: ReturnType<typeof tokyoParts>) =>
    `${d.hour}:${d.minute}`;
  return sameDay
    ? `${dateFmt(s)} ${timeFmt(s)}〜${timeFmt(e)}`
    : `${dateFmt(s)} ${timeFmt(s)} 〜 ${dateFmt(e)} ${timeFmt(e)}`;
}
