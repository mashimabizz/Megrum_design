"use client";

/**
 * iter79-C: D-1 + D-2 統合申告フォーム
 *
 * Megrum/c-dispute.jsx の D1Category + D2Evidence 準拠：
 * - 上部に warning バナー（送信後編集不可・運営 24h 確認）
 * - 取引メタ
 * - カテゴリ選択（5 種、ラジオ風）
 * - 自動添付写真（C-3 で撮影した証跡を表示）
 * - 追加写真（最大 3 枚アップロード可）
 * - 事実メモ（textarea）
 * - 「書き方のコツ」ヒントカード
 * - 申告を送信 sticky CTA
 */

import { useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { submitDispute } from "@/app/disputes/actions";
import { createClient as createBrowserClient } from "@/lib/supabase/client";

type Category = "short" | "wrong" | "noshow" | "cancel" | "other";

const CATEGORIES: { id: Category; label: string; sub: string }[] = [
  {
    id: "short",
    label: "受け取った点数が少ない",
    sub: "合意した枚数より少なかった",
  },
  {
    id: "wrong",
    label: "グッズが違う / 状態が悪い",
    sub: "別メンバー・偽物・破損など",
  },
  {
    id: "noshow",
    label: "相手が現れなかった",
    sub: "合流時間に来なかった・連絡途絶",
  },
  {
    id: "cancel",
    label: "合意済みのキャンセル",
    sub: "事前に双方合意した取消・体調不良など",
  },
  { id: "other", label: "その他", sub: "上記に当てはまらない" },
];

export function DisputeNewForm({
  proposalId,
  partnerHandle,
  meetupSummary,
  autoAttachedPhotoUrls,
}: {
  proposalId: string;
  partnerHandle: string;
  partnerDisplayName: string;
  meetupSummary: string;
  autoAttachedPhotoUrls: string[];
}) {
  const router = useRouter();
  const [category, setCategory] = useState<Category | null>(null);
  const [factMemo, setFactMemo] = useState("");
  const [extraPaths, setExtraPaths] = useState<string[]>([]);
  const [extraPreviews, setExtraPreviews] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const memoRequired = category !== "noshow"; // noshow は任意

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
      const path = `${proposalId}/dispute-${Date.now()}.${ext}`;
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
      // プレビュー用に signed URL（短期）
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

  function handleSubmit() {
    if (!category) {
      setError("カテゴリを選んでください");
      return;
    }
    if (memoRequired && !factMemo.trim()) {
      setError("事実メモを入力してください");
      return;
    }
    if (
      !confirm(
        "送信後は内容を編集できません。アカウント名は相手に共有されます。送信しますか？",
      )
    )
      return;
    setError(null);
    startTransition(async () => {
      const r = await submitDispute({
        proposalId,
        category,
        factMemo: factMemo.trim() || undefined,
        evidencePhotoStoragePaths: extraPaths,
      });
      if (r?.error) {
        setError(r.error);
        return;
      }
      if (r?.disputeId) router.push(`/disputes/${r.disputeId}`);
    });
  }

  return (
    <div className="space-y-3.5 pb-24">
      {/* warning バナー */}
      <div className="flex gap-2.5 rounded-[12px] border border-[#d9826b40] bg-[#fff5f0] p-3">
        <div className="flex h-[22px] w-[22px] flex-shrink-0 items-center justify-center rounded-full bg-[#d9826b] text-[12px] font-extrabold text-white">
          !
        </div>
        <div className="text-[11.5px] leading-[1.6] text-[#3a324a]">
          事実関係の確認のため、<b>送信後は内容を編集できません</b>。
          <br />
          あなたのアカウント名は相手に共有されます。
          <br />
          申告は運営が <b>24 時間以内に確認</b>します。
        </div>
      </div>

      {/* 取引メタ */}
      <Section label="取引">
        <div className="rounded-2xl border border-[#3a324a14] bg-white px-3.5 py-3">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-[10px] bg-[linear-gradient(135deg,#a695d822,#a8d4e622)] text-[12px] font-extrabold text-[#a695d8]">
              {partnerHandle[0]?.toUpperCase() ?? "?"}
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-[12.5px] font-bold text-[#3a324a]">
                @{partnerHandle}
              </div>
              <div className="mt-0.5 truncate text-[10.5px] text-[#3a324a8c]">
                {meetupSummary}
              </div>
            </div>
          </div>
        </div>
      </Section>

      {/* カテゴリ選択 */}
      <Section label="該当する項目">
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
          {CATEGORIES.map((cat, i) => {
            const selected = category === cat.id;
            return (
              <button
                key={cat.id}
                type="button"
                onClick={() => setCategory(cat.id)}
                className={`flex w-full items-start gap-3 px-3.5 py-3 text-left ${
                  selected ? "bg-[#a695d810]" : "bg-transparent"
                } ${i < CATEGORIES.length - 1 ? "border-b border-[#3a324a08]" : ""}`}
              >
                <div
                  className={`mt-0.5 flex h-[18px] w-[18px] flex-shrink-0 items-center justify-center rounded-full border-[1.5px] ${
                    selected
                      ? "border-[#a695d8] bg-[#a695d8]"
                      : "border-[#3a324a40] bg-transparent"
                  }`}
                >
                  {selected && (
                    <svg width="9" height="7" viewBox="0 0 9 7">
                      <path
                        d="M1 3.5L3.5 6 8 1"
                        stroke="#fff"
                        strokeWidth="1.6"
                        fill="none"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  )}
                </div>
                <div className="min-w-0 flex-1">
                  <div
                    className={`text-[13px] ${
                      selected ? "font-bold text-[#3a324a]" : "font-medium text-[#3a324a]"
                    }`}
                  >
                    {cat.label}
                  </div>
                  <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">
                    {cat.sub}
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </Section>

      {/* 証跡写真 */}
      <Section
        label={`証跡写真${memoRequired ? "（必須）" : "（任意）"}`}
        hint={`${autoAttachedPhotoUrls.length + extraPaths.length} / ${autoAttachedPhotoUrls.length + 3}`}
      >
        <div className="rounded-2xl border border-[#3a324a14] bg-white p-3.5">
          <div className="mb-2.5 text-[11.5px] leading-[1.5] text-[#3a324a8c]">
            C-3 で撮影した取引完了時の証跡写真は自動添付されます。
            {memoRequired && (
              <>
                <br />
                必要に応じて追加の写真をアップロードしてください。
              </>
            )}
          </div>
          {/* 自動添付 */}
          {autoAttachedPhotoUrls.length > 0 && (
            <div className="mb-2.5 grid grid-cols-3 gap-2">
              {autoAttachedPhotoUrls.map((url, i) => (
                <div
                  key={i}
                  className="relative aspect-[4/5] overflow-hidden rounded-[10px] border-[0.5px] border-[#3a324a14]"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={url}
                    alt={`取引証跡 ${i + 1}`}
                    className="absolute inset-0 h-full w-full object-cover"
                  />
                  <div className="absolute left-1.5 top-1.5 rounded-[4px] bg-white/92 px-1.5 py-[2px] text-[8.5px] font-bold text-[#3a324a]">
                    取引完了時 ・ 自動
                  </div>
                </div>
              ))}
            </div>
          )}
          {/* 追加 */}
          <div className="grid grid-cols-3 gap-2">
            {extraPreviews.map((url, i) => (
              <div
                key={i}
                className="relative aspect-[4/5] overflow-hidden rounded-[10px] border-[0.5px] border-[#3a324a14]"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={url}
                  alt={`追加証跡 ${i + 1}`}
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
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                  <rect
                    x="2"
                    y="4"
                    width="14"
                    height="11"
                    rx="1.5"
                    stroke="#3a324a8c"
                    strokeWidth="1.2"
                  />
                  <circle
                    cx="9"
                    cy="10"
                    r="2.5"
                    stroke="#3a324a8c"
                    strokeWidth="1.2"
                  />
                  <path
                    d="M6 4l1-1.5h4L12 4"
                    stroke="#3a324a8c"
                    strokeWidth="1.2"
                  />
                </svg>
                {uploading ? "アップ中…" : "追加"}
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
          <div className="mt-2 text-[10.5px] text-[#3a324a8c]">
            任意で最大 3 枚まで追加できます
          </div>
        </div>
      </Section>

      {/* 事実メモ */}
      <Section label={`事実メモ${memoRequired ? "（必須）" : "（任意）"}`}>
        <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
          <textarea
            value={factMemo}
            onChange={(e) => setFactMemo(e.target.value)}
            rows={6}
            maxLength={4000}
            placeholder="例：合流時間に行きましたが、相手から「点数が3枚しか集まっていない」と言われ、3枚で受け取りました。チャットで合意した5枚の証跡が残っています。"
            className="block w-full resize-none border-0 bg-transparent p-3.5 text-[16px] leading-relaxed text-[#3a324a] placeholder:text-[#3a324a4d] focus:outline-none"
          />
        </div>
      </Section>

      {/* 書き方のコツ */}
      <div className="rounded-[10px] bg-[#a695d810] px-3 py-2.5 text-[10.5px] leading-[1.6] text-[#3a324a]">
        <b>📝 書き方のコツ</b>
        <br />
        ・時系列で事実を整理してください（◯時に何が起きたか）
        <br />
        ・推測・感情ではなく観察した事実を
        <br />
        ・該当するチャットメッセージは運営が自動で照合します
      </div>

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* sticky CTA */}
      <div className="fixed inset-x-0 bottom-0 border-t border-[#a695d822] bg-white/96 px-[18px] pb-7 pt-3 backdrop-blur-xl">
        <div className="mx-auto w-full max-w-md">
          <button
            type="button"
            onClick={handleSubmit}
            disabled={pending || !category || (memoRequired && !factMemo.trim())}
            className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-[14px] font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)] disabled:opacity-50"
          >
            {pending ? "送信中…" : "申告を送信"}
          </button>
        </div>
      </div>
    </div>
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
