"use client";

/**
 * iter79-C: 申告ステータス画面（D-3 / D-5 / D-6 一本化）
 *
 * Megrum/c-dispute.jsx 準拠：
 * - D-3 (status='submitted')：受付番号 + 「今後の流れ」 4 ステップ + 申告中の制限
 * - D-5 (status='response_pending' / 'arbitrating')：タイムライン進捗 + 提出済証跡 + 制限
 * - D-6 (status='closed')：結果通知（cancelled / upheld / partial）+ 評価への反映
 */

import Link from "next/link";
import { useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import {
  respondToDispute,
  sendDisputeMessage,
  withdrawDispute,
} from "@/app/disputes/actions";
import { createClient as createBrowserClient } from "@/lib/supabase/client";

const CATEGORY_LABEL: Record<DisputeDetail["category"], string> = {
  short: "受け取った点数が少ない",
  wrong: "グッズが違う / 状態が悪い",
  noshow: "相手が現れなかった",
  cancel: "合意済みのキャンセル",
  other: "その他",
};

export type DisputeDetail = {
  id: string;
  proposalId: string;
  iAmReporter: boolean;
  partnerHandle: string;
  partnerDisplayName: string;
  category: "short" | "wrong" | "noshow" | "cancel" | "other";
  factMemo: string | null;
  extraPhotoUrls: string[];
  autoAttachedPhotoUrls: string[];
  status: "submitted" | "response_pending" | "arbitrating" | "closed";
  outcome: "cancelled" | "upheld" | "partial" | null;
  operatorComment: string | null;
  ticketNo: string;
  respondentDeadlineAt: string | null;
  operatorDeadlineAt: string | null;
  submittedAt: string;
  closedAt: string | null;
  /** iter80-D4: 相手側反論 */
  respondentResponse: "accepted" | "disputed" | "silent" | null;
  respondentResponseText: string | null;
  respondentEvidenceUrls: string[];
  respondentRespondedAt: string | null;
  /** iter89-D5d: dispute_messages（時系列） */
  messages: {
    id: string;
    senderRole: "reporter" | "respondent" | "operator";
    body: string;
    photoUrls: string[];
    createdAt: string;
    isMine: boolean;
  }[];
};

export function DisputeView({ detail }: { detail: DisputeDetail }) {
  // iter80-D4: respondent でまだ未回答 + status が submitted/response_pending → 反論フロー
  if (
    !detail.iAmReporter &&
    !detail.respondentResponse &&
    (detail.status === "submitted" || detail.status === "response_pending")
  ) {
    return <RespondentResponseView detail={detail} />;
  }
  if (detail.status === "closed") {
    return <ClosedView detail={detail} />;
  }
  if (detail.status === "submitted") {
    return <SubmittedView detail={detail} />;
  }
  return <ArbitrationView detail={detail} />;
}

/* ─── iter80-D4: 受信者の反論フロー（D-4 / 拡張で反論本文 + 証跡） ─── */

function RespondentResponseView({ detail }: { detail: DisputeDetail }) {
  const router = useRouter();
  const [mode, setMode] = useState<"choose" | "dispute">("choose");
  const [responseText, setResponseText] = useState("");
  const [extraPaths, setExtraPaths] = useState<string[]>([]);
  const [extraPreviews, setExtraPreviews] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function handleAddPhoto(file: File | null) {
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setError("画像ファイルを選んでください");
      return;
    }
    if (file.size > 8 * 1024 * 1024) {
      setError("8MB 以下の画像にしてください");
      return;
    }
    if (extraPaths.length >= 3) {
      setError("追加写真は最大 3 枚までです");
      return;
    }
    setError(null);
    setUploading(true);
    try {
      const sb = createBrowserClient();
      const ext = file.name.split(".").pop()?.toLowerCase() || "jpg";
      const path = `${detail.proposalId}/dispute-resp-${Date.now()}.${ext}`;
      const { error: upErr } = await sb.storage
        .from("chat-photos")
        .upload(path, file, {
          contentType: file.type,
          upsert: false,
        });
      if (upErr) {
        setError(upErr.message || "アップロード失敗");
        return;
      }
      const { data: signed } = await sb.storage
        .from("chat-photos")
        .createSignedUrl(path, 60 * 60);
      setExtraPaths((prev) => [...prev, path]);
      setExtraPreviews((prev) => [...prev, signed?.signedUrl ?? ""]);
    } catch (e) {
      setError(e instanceof Error ? e.message : "アップロード失敗");
    } finally {
      setUploading(false);
    }
  }

  function removeExtra(idx: number) {
    setExtraPaths((prev) => prev.filter((_, i) => i !== idx));
    setExtraPreviews((prev) => prev.filter((_, i) => i !== idx));
  }

  function handleAccept() {
    if (
      !confirm(
        "申告内容が事実であると認めますか？取引はキャンセル扱いとなります。",
      )
    )
      return;
    setError(null);
    startTransition(async () => {
      const r = await respondToDispute({
        id: detail.id,
        response: "accepted",
      });
      if (r?.error) setError(r.error);
      else router.refresh();
    });
  }

  function handleSubmitDispute() {
    if (!responseText.trim()) {
      setError("反論内容を入力してください");
      return;
    }
    if (
      !confirm(
        "反論を提出します。送信後は内容を編集できません。続けますか？",
      )
    )
      return;
    setError(null);
    startTransition(async () => {
      const r = await respondToDispute({
        id: detail.id,
        response: "disputed",
        responseText,
        evidencePhotoStoragePaths: extraPaths,
      });
      if (r?.error) setError(r.error);
      else router.refresh();
    });
  }

  return (
    <div className="space-y-3.5 pb-24">
      {/* warning バナー（D-4 上部） */}
      <div className="rounded-[14px] border border-[#d9826b40] bg-[#fff5f0] p-3.5">
        <div className="mb-1.5 flex items-center gap-2">
          <span className="flex h-[22px] w-[22px] items-center justify-center rounded-full bg-[#d9826b] text-[12px] font-extrabold text-white">
            !
          </span>
          <span className="text-[13px] font-extrabold text-[#3a324a]">
            申告がありました
          </span>
        </div>
        <div className="text-[11.5px] leading-[1.6] text-[#3a324a]">
          事実確認にご協力ください。以下の内容についてあなたの認識をお聞かせください。
        </div>
        {detail.respondentDeadlineAt && (
          <div className="mt-2 text-[10.5px] text-[#3a324a8c]">
            回答期限：{formatDateTime(detail.respondentDeadlineAt)}
          </div>
        )}
      </div>

      {/* 申告内容サマリ */}
      <Section label="申告内容">
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
          <Row label="申告者" value={`@${detail.partnerHandle}`} />
          <Row label="カテゴリ" value={CATEGORY_LABEL[detail.category]} />
          <Row label="送信日時" value={formatDateTime(detail.submittedAt)} />
          {detail.factMemo && (
            <div className="border-t border-[#3a324a08] px-3.5 py-3">
              <div className="mb-1 text-[10.5px] font-bold text-[#3a324a8c]">
                事実メモ（申告者）
              </div>
              <pre className="whitespace-pre-wrap break-words text-[12px] leading-relaxed text-[#3a324a]">
                {detail.factMemo}
              </pre>
            </div>
          )}
          {(detail.autoAttachedPhotoUrls.length > 0 ||
            detail.extraPhotoUrls.length > 0) && (
            <div className="border-t border-[#3a324a08] p-3.5">
              <div className="mb-2 text-[10.5px] font-bold text-[#3a324a8c]">
                提出済み証跡
              </div>
              <div className="grid grid-cols-3 gap-2">
                {[
                  ...detail.autoAttachedPhotoUrls,
                  ...detail.extraPhotoUrls,
                ].map((url, i) => (
                  <div
                    key={i}
                    className="relative aspect-[4/5] overflow-hidden rounded-[10px] border-[0.5px] border-[#3a324a14]"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={url}
                      alt={`evidence-${i}`}
                      className="absolute inset-0 h-full w-full object-cover"
                    />
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </Section>

      {/* mode === "choose": 3 択 */}
      {mode === "choose" && (
        <Section label="あなたの選択">
          <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
            <button
              type="button"
              onClick={handleAccept}
              disabled={pending}
              className="flex w-full flex-col gap-0.5 border-b border-[#3a324a08] px-3.5 py-3 text-left disabled:opacity-50"
            >
              <span className="text-[12.5px] font-bold text-[#3a324a]">
                事実です。間違いを認めます
              </span>
              <span className="text-[10.5px] font-bold text-[#d9826b]">
                → 取引は取消・★ は据え置き
              </span>
            </button>
            <button
              type="button"
              onClick={() => setMode("dispute")}
              className="flex w-full flex-col gap-0.5 border-b border-[#3a324a08] px-3.5 py-3 text-left"
            >
              <span className="text-[12.5px] font-bold text-[#3a324a]">
                事実と異なります。反論を提出します
              </span>
              <span className="text-[10.5px] font-bold text-[#a695d8]">
                → 次画面で詳細を入力（推奨）
              </span>
            </button>
            <div className="px-3.5 py-3 text-[#3a324a8c]">
              <div className="text-[12.5px] font-medium">
                回答せず 24 時間経過
              </div>
              <div className="text-[10.5px]">
                → 申告内容が事実と推定されます
              </div>
            </div>
          </div>
        </Section>
      )}

      {/* mode === "dispute": 反論フォーム */}
      {mode === "dispute" && (
        <>
          <Section label="あなたの反論（必須）">
            <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
              <textarea
                value={responseText}
                onChange={(e) => setResponseText(e.target.value)}
                rows={6}
                maxLength={4000}
                placeholder="例：合意した点数は 3 枚です（5 枚ではありません）。チャット履歴をご確認ください。"
                className="block w-full resize-none border-0 bg-transparent p-3.5 text-[16px] leading-relaxed text-[#3a324a] placeholder:text-[#3a324a4d] focus:outline-none"
              />
            </div>
          </Section>

          <Section label="補強証跡（任意・最大 3 枚）">
            <div className="rounded-2xl border border-[#3a324a14] bg-white p-3.5">
              <div className="grid grid-cols-3 gap-2">
                {extraPreviews.map((url, i) => (
                  <div
                    key={i}
                    className="relative aspect-[4/5] overflow-hidden rounded-[10px] border-[0.5px] border-[#3a324a14]"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={url}
                      alt={`extra-${i}`}
                      className="absolute inset-0 h-full w-full object-cover"
                    />
                    <button
                      type="button"
                      onClick={() => removeExtra(i)}
                      aria-label="削除"
                      className="absolute right-1 top-1 flex h-5 w-5 items-center justify-center rounded-full bg-black/65 text-[12px] font-bold text-white"
                    >
                      ✕
                    </button>
                  </div>
                ))}
                {extraPaths.length < 3 && (
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploading}
                    className="flex aspect-[4/5] flex-col items-center justify-center gap-1 rounded-[10px] border border-dashed border-[#a695d855] bg-[#fbf9fc] text-[10px] text-[#3a324a8c] disabled:opacity-50"
                  >
                    {uploading ? "アップ中…" : "+ 追加"}
                  </button>
                )}
              </div>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => {
                  const f = e.target.files?.[0] ?? null;
                  handleAddPhoto(f);
                  if (e.target) e.target.value = "";
                }}
              />
            </div>
          </Section>
        </>
      )}

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* sticky CTA */}
      <div className="fixed inset-x-0 bottom-0 border-t border-[#a695d822] bg-white/96 px-[18px] pb-7 pt-3 backdrop-blur-xl">
        <div className="mx-auto w-full max-w-md space-y-2">
          {mode === "choose" ? (
            <button
              type="button"
              onClick={() => setMode("dispute")}
              className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-[14px] font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)]"
            >
              反論を提出する
            </button>
          ) : (
            <>
              <button
                type="button"
                onClick={handleSubmitDispute}
                disabled={pending || !responseText.trim()}
                className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-[14px] font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)] disabled:opacity-50"
              >
                {pending ? "送信中…" : "反論を送信"}
              </button>
              <button
                type="button"
                onClick={() => setMode("choose")}
                className="block w-full px-6 py-2 text-center text-[12px] font-semibold text-[#3a324a8c]"
              >
                ← 戻る
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

/* ─── D-3: 送信完了 ─── */

function SubmittedView({ detail }: { detail: DisputeDetail }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleWithdraw() {
    if (!confirm("申告を取り下げますか？取引は通常通り処理されます。")) return;
    setError(null);
    startTransition(async () => {
      const r = await withdrawDispute({ id: detail.id });
      if (r?.error) setError(r.error);
      else router.push(`/transactions/${detail.proposalId}`);
    });
  }

  return (
    <div className="space-y-3.5 pb-20">
      {/* hero */}
      <div className="rounded-2xl border border-[#3a324a14] bg-white p-5 text-center">
        <div className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-full bg-[#a695d810]">
          <svg width="26" height="26" viewBox="0 0 26 26" fill="none">
            <circle cx="13" cy="13" r="11" stroke="#a695d8" strokeWidth="1.6" />
            <path
              d="M8 13l3 3 7-7"
              stroke="#a695d8"
              strokeWidth="1.8"
              strokeLinecap="round"
              strokeLinejoin="round"
              fill="none"
            />
          </svg>
        </div>
        <div className="text-[18px] font-extrabold tracking-[0.3px] text-[#3a324a]">
          受付番号 {detail.ticketNo}
        </div>
        <div className="mt-1 text-[12px] text-[#3a324a8c]">
          運営が 24 時間以内に一次回答します
        </div>
      </div>

      {/* 今後の流れ */}
      <Section label="今後の流れ">
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
          {(
            [
              {
                n: "1",
                label: "相手に通知",
                sub: "事実確認の機会を提供（最大 24h）",
                state: "now",
              },
              {
                n: "2",
                label: "運営による事実確認",
                sub: "チャット履歴・証跡を双方分照合",
                state: "next",
              },
              {
                n: "3",
                label: "一次回答",
                sub: "24 時間以内 ・ 通知でお知らせ",
                state: "next",
              },
              {
                n: "4",
                label: "結果通知 / 評価反映",
                sub: "取引完了 or 取消 or 追加調査",
                state: "next",
              },
            ] as const
          ).map((s, i, arr) => (
            <div
              key={s.n}
              className={`flex items-start gap-3 px-3.5 py-3 ${
                i < arr.length - 1 ? "border-b border-[#3a324a08]" : ""
              }`}
            >
              <div
                className={`mt-0.5 flex h-[22px] w-[22px] flex-shrink-0 items-center justify-center rounded-full text-[11px] font-extrabold ${
                  s.state === "now"
                    ? "bg-[#a695d8] text-white"
                    : "bg-[#fbf9fc] text-[#3a324a8c]"
                }`}
              >
                {s.n}
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-1.5 text-[12.5px] font-bold text-[#3a324a]">
                  {s.label}
                  {s.state === "now" && (
                    <span className="rounded-[4px] bg-[#a695d8] px-1.5 py-[1px] text-[9px] font-extrabold text-white">
                      進行中
                    </span>
                  )}
                </div>
                <div className="mt-0.5 text-[11px] text-[#3a324a8c]">
                  {s.sub}
                </div>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* 申告中の制限 */}
      <Section label="申告中の制限">
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
          <div className="border-b border-[#3a324a08] px-3.5 py-3 text-[12px] leading-[1.6] text-[#3a324a]">
            <b>新規打診のみ一時制限</b>されます
            <br />
            <span className="text-[11px] text-[#3a324a8c]">
              既に進行中の取引は通常通り続行できます ・ 相手側も同じ制限
            </span>
          </div>
          <div className="px-3.5 py-3 text-[12px] leading-[1.6] text-[#3a324a]">
            <b>評価の反映は保留</b>されます
            <br />
            <span className="text-[11px] text-[#3a324a8c]">
              結論が出るまで ★ ・ 取引数に算入されません
            </span>
          </div>
        </div>
      </Section>

      {/* 申告内容サマリ */}
      <SummarySection detail={detail} />

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* CTA */}
      <div className="space-y-2 pt-2">
        <Link
          href="/"
          className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-[14px] font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)]"
        >
          ホームに戻る
        </Link>
        {detail.iAmReporter && (
          <button
            type="button"
            onClick={handleWithdraw}
            disabled={pending}
            className="block w-full px-6 py-3 text-center text-[12px] font-semibold text-[#3a324a8c] disabled:opacity-50"
          >
            申告を取り下げる
          </button>
        )}
      </div>
    </div>
  );
}

/* ─── D-5: 仲裁中ステータス ─── */

function ArbitrationView({ detail }: { detail: DisputeDetail }) {
  return (
    <div className="space-y-3.5 pb-20">
      {/* SLA banner */}
      {detail.operatorDeadlineAt && (
        <SlaBanner
          deadlineAt={detail.operatorDeadlineAt}
          label="運営の一次回答期限"
        />
      )}

      {/* 進捗タイムライン */}
      <Section label="進捗">
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white p-3.5">
          <Timeline detail={detail} />
        </div>
      </Section>

      {/* 提出済証跡 */}
      <SummarySection detail={detail} />

      {/* iter80-D4: 相手の反論（あれば表示） */}
      {detail.respondentResponse && (
        <Section label={`相手の反論（${detail.iAmReporter ? `@${detail.partnerHandle}` : "あなた"}）`}>
          <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
            <Row
              label="回答"
              value={
                detail.respondentResponse === "accepted"
                  ? "事実を認める"
                  : detail.respondentResponse === "disputed"
                    ? "反論あり"
                    : "無回答（事実推定）"
              }
            />
            {detail.respondentRespondedAt && (
              <Row
                label="回答日時"
                value={formatDateTime(detail.respondentRespondedAt)}
              />
            )}
            {detail.respondentResponseText && (
              <div className="border-t border-[#3a324a08] px-3.5 py-3">
                <div className="mb-1 text-[10.5px] font-bold text-[#3a324a8c]">
                  反論内容
                </div>
                <pre className="whitespace-pre-wrap break-words text-[12px] leading-relaxed text-[#3a324a]">
                  {detail.respondentResponseText}
                </pre>
              </div>
            )}
            {detail.respondentEvidenceUrls.length > 0 && (
              <div className="border-t border-[#3a324a08] p-3.5">
                <div className="mb-2 text-[10.5px] font-bold text-[#3a324a8c]">
                  反論側の補強証跡（{detail.respondentEvidenceUrls.length}枚）
                </div>
                <div className="grid grid-cols-3 gap-2">
                  {detail.respondentEvidenceUrls.map((url, i) => (
                    <div
                      key={i}
                      className="relative aspect-[4/5] overflow-hidden rounded-[10px] border-[0.5px] border-[#3a324a14]"
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={url}
                        alt={`respondent-evidence-${i}`}
                        className="absolute inset-0 h-full w-full object-cover"
                      />
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </Section>
      )}

      {/* 現在の制限 */}
      <Section label="現在の制限">
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
          <RestrictionRow label="新規打診" value="制限中" tone="warn" />
          <RestrictionRow label="進行中の取引" value="継続可能" tone="ok" />
          <RestrictionRow label="★ ・ 取引数の集計" value="保留" tone="warn" isLast />
        </div>
      </Section>

      {/* iter89-D5d: 運営とのやりとり */}
      <DisputeMessagingSection detail={detail} />
    </div>
  );
}

/* ─── D-6: 結果通知 ─── */

function ClosedView({ detail }: { detail: DisputeDetail }) {
  const variants = {
    cancelled: {
      title: "取引取消が認められました",
      sub: `${detail.ticketNo} ・ 申告内容が事実と確認されました`,
      tone: "ok",
      summary:
        "取引は無効となり、両者の評価には反映されません。",
      actions: [
        { l: "相手の評価", v: "保留→取消（影響なし）" },
        { l: "あなたの評価", v: "保留→影響なし" },
        { l: "取引数", v: "加算されません" },
      ],
    },
    upheld: {
      title: "相手側の説明が認められました",
      sub: "申告不成立 ・ 評価入力フェーズに戻ります",
      tone: "mute",
      summary:
        "提出された証跡から、相手の説明が事実と判断されました。取引は完了として処理されます。",
      actions: [
        { l: "相手の評価", v: "通常通り反映" },
        { l: "あなたの評価", v: "通常通り反映" },
        { l: "取引数", v: "+1" },
      ],
    },
    partial: {
      title: "部分的に認められました",
      sub: "両者の主張に一部理由あり ・ 取引数のみ加算",
      tone: "amber",
      summary:
        "両者の主張に一定の理由がありました。評価への反映は部分的になります。",
      actions: [
        { l: "相手の評価", v: "部分反映" },
        { l: "あなたの評価", v: "部分反映" },
        { l: "取引数", v: "+1" },
      ],
    },
  } as const;
  const v =
    variants[detail.outcome ?? "cancelled"] ?? variants.cancelled;
  const toneColor =
    v.tone === "ok" ? "#22c55e" : v.tone === "amber" ? "#e0a847" : "#9ca3af";

  return (
    <div className="space-y-3.5 pb-20">
      {/* 結果 hero */}
      <div className="rounded-2xl border border-[#3a324a14] bg-white p-5 text-center">
        <div
          className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full"
          style={{ background: `${toneColor}1a`, color: toneColor }}
        >
          {v.tone === "ok" ? (
            <svg width="22" height="22" viewBox="0 0 22 22">
              <path
                d="M5 11l4 4 9-9"
                stroke={toneColor}
                strokeWidth="2"
                fill="none"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          ) : (
            <svg width="22" height="22" viewBox="0 0 22 22">
              <path
                d="M6 6l10 10M16 6L6 16"
                stroke={toneColor}
                strokeWidth="2"
                fill="none"
                strokeLinecap="round"
              />
            </svg>
          )}
        </div>
        <div className="text-[16px] font-extrabold text-[#3a324a]">
          {v.title}
        </div>
        <div className="mt-1 text-[11px] text-[#3a324a8c]">{v.sub}</div>
      </div>

      {/* 運営コメント */}
      <Section label="運営からのコメント">
        <div className="rounded-2xl border border-[#3a324a14] bg-white p-3.5 text-[12px] leading-[1.7] text-[#3a324a]">
          {detail.operatorComment ?? v.summary}
          <div className="mt-2 text-[10.5px] text-[#3a324a8c]">
            {detail.closedAt
              ? `${formatDateTime(detail.closedAt)} ・ Megrum サポート`
              : "Megrum サポート"}
          </div>
        </div>
      </Section>

      {/* 評価・取引への反映 */}
      <Section label="評価・取引への反映">
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
          {v.actions.map((a, i, arr) => (
            <div
              key={a.l}
              className={`flex items-center justify-between px-3.5 py-3 text-[12px] ${
                i < arr.length - 1 ? "border-b border-[#3a324a08]" : ""
              }`}
            >
              <span className="text-[#3a324a8c]">{a.l}</span>
              <span className="font-bold text-[#3a324a]">{a.v}</span>
            </div>
          ))}
        </div>
      </Section>

      <SummarySection detail={detail} />

      {/* iter89-D5d: 過去のやりとり（クローズ後は閲覧のみ） */}
      {detail.messages.length > 0 && (
        <DisputeMessagingSection detail={detail} />
      )}

      <div className="pt-2">
        <Link
          href="/"
          className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-[14px] font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)]"
        >
          ホームに戻る
        </Link>
      </div>
    </div>
  );
}

/* ─── iter89-D5d: 運営とのやりとり（dispute_messages 時系列 + 返信フォーム） ─── */

function DisputeMessagingSection({ detail }: { detail: DisputeDetail }) {
  const router = useRouter();
  const [draft, setDraft] = useState("");
  const [extraPaths, setExtraPaths] = useState<string[]>([]);
  const [extraPreviews, setExtraPreviews] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function handleAddPhoto(file: File | null) {
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setError("画像ファイルを選んでください");
      return;
    }
    if (file.size > 8 * 1024 * 1024) {
      setError("8MB 以下の画像にしてください");
      return;
    }
    if (extraPaths.length >= 3) {
      setError("添付写真は最大 3 枚までです");
      return;
    }
    setError(null);
    setUploading(true);
    try {
      const sb = createBrowserClient();
      const ext = file.name.split(".").pop()?.toLowerCase() || "jpg";
      const path = `${detail.proposalId}/dispute-msg-${Date.now()}.${ext}`;
      const { error: upErr } = await sb.storage
        .from("chat-photos")
        .upload(path, file, {
          contentType: file.type,
          upsert: false,
        });
      if (upErr) {
        setError(upErr.message || "アップロード失敗");
        return;
      }
      const { data: signed } = await sb.storage
        .from("chat-photos")
        .createSignedUrl(path, 60 * 60);
      setExtraPaths((prev) => [...prev, path]);
      setExtraPreviews((prev) => [...prev, signed?.signedUrl ?? ""]);
    } catch (e) {
      setError(e instanceof Error ? e.message : "アップロード失敗");
    } finally {
      setUploading(false);
    }
  }
  function removeExtra(idx: number) {
    setExtraPaths((prev) => prev.filter((_, i) => i !== idx));
    setExtraPreviews((prev) => prev.filter((_, i) => i !== idx));
  }

  function handleSend() {
    if (!draft.trim()) {
      setError("本文を入力してください");
      return;
    }
    setError(null);
    startTransition(async () => {
      const r = await sendDisputeMessage({
        disputeId: detail.id,
        body: draft.trim(),
        evidencePhotoStoragePaths: extraPaths,
      });
      if (r?.error) setError(r.error);
      else {
        setDraft("");
        setExtraPaths([]);
        setExtraPreviews([]);
        router.refresh();
      }
    });
  }

  return (
    <Section label="運営とのやりとり">
      <div className="space-y-2">
        {/* メッセージ一覧 */}
        {detail.messages.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white px-3.5 py-3 text-[11px] text-[#3a324a8c]">
            まだやりとりはありません。運営から追加の質問が届くか、
            自分から追加情報を送ると、ここに表示されます。
          </div>
        ) : (
          <div className="space-y-1.5">
            {detail.messages.map((m) => (
              <DisputeMessageBubble key={m.id} m={m} />
            ))}
          </div>
        )}

        {/* 返信フォーム（クローズ前のみ） */}
        {detail.status !== "closed" && (
          <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
            <textarea
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              rows={3}
              maxLength={4000}
              placeholder="運営に追加情報を送る（自由記述）"
              className="block w-full resize-none border-0 bg-transparent p-3.5 text-[16px] leading-relaxed text-[#3a324a] placeholder:text-[#3a324a4d] focus:outline-none"
            />

            {/* 添付プレビュー */}
            {(extraPreviews.length > 0 || extraPaths.length < 3) && (
              <div className="border-t border-[#3a324a08] px-3.5 py-2">
                <div className="grid grid-cols-3 gap-2">
                  {extraPreviews.map((url, i) => (
                    <div
                      key={i}
                      className="relative aspect-[4/5] overflow-hidden rounded-[8px] border-[0.5px] border-[#3a324a14]"
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={url}
                        alt={`extra-${i}`}
                        className="absolute inset-0 h-full w-full object-cover"
                      />
                      <button
                        type="button"
                        onClick={() => removeExtra(i)}
                        aria-label="削除"
                        className="absolute right-1 top-1 flex h-5 w-5 items-center justify-center rounded-full bg-black/65 text-[12px] font-bold text-white"
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                  {extraPaths.length < 3 && (
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={uploading}
                      className="flex aspect-[4/5] flex-col items-center justify-center gap-1 rounded-[8px] border border-dashed border-[#a695d855] bg-[#fbf9fc] text-[10px] text-[#3a324a8c] disabled:opacity-50"
                    >
                      {uploading ? "アップ中…" : "+ 写真"}
                    </button>
                  )}
                </div>
              </div>
            )}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => {
                const f = e.target.files?.[0] ?? null;
                handleAddPhoto(f);
                if (e.target) e.target.value = "";
              }}
            />

            <div className="flex justify-end gap-1.5 border-t border-[#3a324a08] px-3 py-2">
              <button
                type="button"
                onClick={handleSend}
                disabled={pending || !draft.trim()}
                className="rounded-[10px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-4 py-1.5 text-[11.5px] font-extrabold text-white shadow-[0_2px_5px_rgba(166,149,216,0.4)] disabled:opacity-50"
              >
                {pending ? "送信中…" : "送信"}
              </button>
            </div>
          </div>
        )}

        {error && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
            {error}
          </div>
        )}
      </div>
    </Section>
  );
}

function DisputeMessageBubble({
  m,
}: {
  m: DisputeDetail["messages"][number];
}) {
  // 役割別の表示
  const isOperator = m.senderRole === "operator";
  const align = m.isMine ? "items-end" : "items-start";
  const bg = isOperator
    ? "bg-[linear-gradient(135deg,#a695d822,#a8d4e622)] border border-[#a695d855]"
    : m.isMine
      ? "bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] text-white"
      : "bg-white border border-[#3a324a14] text-[#3a324a]";
  const roleLabel = isOperator
    ? "🛟 Megrum サポート"
    : m.senderRole === "reporter"
      ? "申告者"
      : "被申告者";
  return (
    <div className={`flex flex-col gap-0.5 ${align}`}>
      <div
        className={`max-w-[88%] overflow-hidden rounded-[14px] ${bg} px-3 py-2`}
      >
        <div
          className={`mb-0.5 flex items-center gap-1.5 text-[10px] font-extrabold ${
            isOperator
              ? "text-[#a695d8]"
              : m.isMine
                ? "text-white/85"
                : "text-[#3a324a8c]"
          }`}
        >
          {roleLabel}
        </div>
        <div className="whitespace-pre-wrap break-words text-[12.5px] leading-relaxed">
          {m.body}
        </div>
        {m.photoUrls.length > 0 && (
          <div className="mt-2 grid grid-cols-3 gap-1.5">
            {m.photoUrls.map((url, i) => (
              <a
                key={i}
                href={url}
                target="_blank"
                rel="noopener noreferrer"
                className="relative aspect-[4/5] overflow-hidden rounded-[6px] border border-white/40"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={url}
                  alt={`msg-${i}`}
                  className="absolute inset-0 h-full w-full object-cover"
                />
              </a>
            ))}
          </div>
        )}
      </div>
      <span className="px-1 text-[9px] tabular-nums text-[#3a324a8c]">
        {formatDateTime(m.createdAt)}
      </span>
    </div>
  );
}

/* ─── 共通：申告内容サマリ ─── */

function SummarySection({ detail }: { detail: DisputeDetail }) {
  return (
    <Section label="申告内容">
      <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
        <Row label="申告者" value={detail.iAmReporter ? "あなた" : `@${detail.partnerHandle}`} />
        <Row label="相手" value={detail.iAmReporter ? `@${detail.partnerHandle}` : "あなた"} />
        <Row label="カテゴリ" value={CATEGORY_LABEL[detail.category]} />
        <Row label="送信日時" value={formatDateTime(detail.submittedAt)} />
        {detail.factMemo && (
          <div className="border-t border-[#3a324a08] px-3.5 py-3">
            <div className="mb-1 text-[10.5px] font-bold text-[#3a324a8c]">
              事実メモ
            </div>
            <pre className="whitespace-pre-wrap break-words text-[12px] leading-relaxed text-[#3a324a]">
              {detail.factMemo}
            </pre>
          </div>
        )}
        {(detail.autoAttachedPhotoUrls.length > 0 ||
          detail.extraPhotoUrls.length > 0) && (
          <div className="border-t border-[#3a324a08] p-3.5">
            <div className="mb-2 text-[10.5px] font-bold text-[#3a324a8c]">
              提出済み証跡（{detail.autoAttachedPhotoUrls.length +
                detail.extraPhotoUrls.length}
              枚）
            </div>
            <div className="grid grid-cols-3 gap-2">
              {detail.autoAttachedPhotoUrls.map((url, i) => (
                <div
                  key={`auto-${i}`}
                  className="relative aspect-[4/5] overflow-hidden rounded-[10px] border-[0.5px] border-[#3a324a14]"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={url}
                    alt={`auto-${i}`}
                    className="absolute inset-0 h-full w-full object-cover"
                  />
                  <div className="absolute left-1.5 top-1.5 rounded-[4px] bg-white/92 px-1.5 py-[2px] text-[8.5px] font-bold text-[#3a324a]">
                    自動
                  </div>
                </div>
              ))}
              {detail.extraPhotoUrls.map((url, i) => (
                <div
                  key={`extra-${i}`}
                  className="relative aspect-[4/5] overflow-hidden rounded-[10px] border-[0.5px] border-[#3a324a14]"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={url}
                    alt={`extra-${i}`}
                    className="absolute inset-0 h-full w-full object-cover"
                  />
                  <div className="absolute left-1.5 top-1.5 rounded-[4px] bg-white/92 px-1.5 py-[2px] text-[8.5px] font-bold text-[#3a324a]">
                    追加
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </Section>
  );
}

/* ─── 共通サブ ─── */

function Section({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="mb-1.5 px-1 text-[10.5px] font-bold uppercase tracking-[0.6px] text-[#3a324a8c]">
        {label}
      </div>
      {children}
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between border-b border-[#3a324a08] px-3.5 py-2.5 last:border-b-0">
      <span className="text-[10.5px] text-[#3a324a8c]">{label}</span>
      <span className="text-[12.5px] font-bold text-[#3a324a]">{value}</span>
    </div>
  );
}

function RestrictionRow({
  label,
  value,
  tone,
  isLast,
}: {
  label: string;
  value: string;
  tone: "ok" | "warn";
  isLast?: boolean;
}) {
  return (
    <div
      className={`flex items-center justify-between px-3.5 py-3 text-[12px] ${
        isLast ? "" : "border-b border-[#3a324a08]"
      }`}
    >
      <span className="text-[#3a324a]">{label}</span>
      <span
        className={`text-[11px] font-extrabold ${
          tone === "ok" ? "text-emerald-600" : "text-[#d9826b]"
        }`}
      >
        {value}
      </span>
    </div>
  );
}

function SlaBanner({
  deadlineAt,
  label,
}: {
  deadlineAt: string;
  label: string;
}) {
  const remainMs = new Date(deadlineAt).getTime() - Date.now();
  const remainHours = Math.max(0, Math.floor(remainMs / (60 * 60_000)));
  const remainMins = Math.max(
    0,
    Math.floor((remainMs % (60 * 60_000)) / 60_000),
  );
  const tone = remainMs <= 0 ? "warn" : remainHours <= 6 ? "warn" : "amber";
  const bgClass =
    tone === "warn"
      ? "border-[#d9826b40] bg-[#fff5f0]"
      : "border-amber-300 bg-amber-50";
  const labelColor =
    tone === "warn" ? "text-[#d9826b]" : "text-amber-700";
  return (
    <div
      className={`flex items-center gap-2.5 rounded-[12px] border px-3 py-2.5 ${bgClass}`}
    >
      <div
        className={`flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-[10px] text-white ${
          tone === "warn" ? "bg-[#d9826b]" : "bg-amber-500"
        }`}
      >
        <div className="text-center leading-none">
          <div className="text-[13px] font-extrabold">
            {remainHours}
          </div>
          <div className="text-[7px] font-bold opacity-90">
            :{String(remainMins).padStart(2, "0")}
          </div>
        </div>
      </div>
      <div className="min-w-0 flex-1">
        <div className={`text-[12px] font-extrabold ${labelColor}`}>
          残り {remainHours} 時間 {remainMins} 分
        </div>
        <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">{label}</div>
      </div>
    </div>
  );
}

/* ─── 進捗タイムライン ─── */

function Timeline({ detail }: { detail: DisputeDetail }) {
  const steps = [
    {
      label: "申告受付",
      time: formatDateTime(detail.submittedAt),
      done: true,
    },
    {
      label:
        detail.status === "response_pending"
          ? "相手の回答を待っています"
          : "相手の回答受領",
      time:
        detail.status === "response_pending"
          ? "進行中"
          : detail.respondentDeadlineAt
            ? "完了"
            : "—",
      done: detail.status === "arbitrating" || detail.status === "closed",
      current: detail.status === "response_pending",
    },
    {
      label: "運営による事実確認",
      time:
        detail.status === "arbitrating"
          ? "進行中"
          : detail.status === "closed"
            ? "完了"
            : "—",
      done: detail.status === "closed",
      current: detail.status === "arbitrating",
    },
    {
      label: "一次回答",
      time: detail.operatorDeadlineAt
        ? `${formatDateTime(detail.operatorDeadlineAt)} まで`
        : "—",
      done: detail.status === "closed",
    },
  ];

  return (
    <div>
      {steps.map((s, i, arr) => (
        <div
          key={s.label}
          className={`relative flex items-start gap-3 ${i < arr.length - 1 ? "pb-3.5" : ""}`}
        >
          {i < arr.length - 1 && (
            <div
              className="absolute bottom-0 left-[9px] top-[22px] w-[1.5px]"
              style={{ background: s.done ? "#a695d8" : "#3a324a14" }}
            />
          )}
          <div
            className={`relative z-[1] mt-[1px] flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full ${
              s.done
                ? "bg-[#a695d8]"
                : s.current
                  ? "border-[2px] border-[#a695d8] bg-white"
                  : "bg-[#fbf9fc]"
            }`}
          >
            {s.done && (
              <svg width="10" height="8" viewBox="0 0 10 8">
                <path
                  d="M1 4l3 3 5-6"
                  stroke="#fff"
                  strokeWidth="1.6"
                  fill="none"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            )}
            {s.current && (
              <div className="h-2 w-2 rounded-full bg-[#a695d8]" />
            )}
          </div>
          <div className="min-w-0 flex-1">
            <div
              className={`text-[12.5px] ${s.current ? "font-bold" : "font-semibold"} text-[#3a324a]`}
            >
              {s.label}
            </div>
            <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">
              {s.time}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function formatDateTime(iso: string): string {
  const d = new Date(iso);
  return `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(2, "0")}/${String(d.getDate()).padStart(2, "0")} ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}
