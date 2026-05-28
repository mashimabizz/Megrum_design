"use client";

import Link from "next/link";
import { useTransition } from "react";
import { logout } from "@/app/auth/actions";
import { Avatar } from "@/components/common/Avatar";

type Props = {
  /** iter148: 自分の user.id（評価一覧へのリンク用） */
  userId: string;
  profile: {
    handle: string;
    displayName: string;
    gender: string | null;
    primaryArea: string | null;
    emailVerifiedAt: string | null;
    /** iter122: プロフ画像 URL（avatars バケット publicUrl） */
    avatarUrl: string | null;
  };
  oshiGroups: {
    groupId: string;
    groupName: string;
    members: { id: string; name: string }[];
  }[];
  awCount: number; // iter86: 現地モード切替時のみ設定する単一 AW（残置のため互換用）
  listingsCount: number;
  tradeCount: number;
  /** iter148: 評価サマリ */
  ratingAvg: number | null;
  ratingCount: number;
};

/**
 * プロフ画面（自分用）
 *
 * iter148:
 * - hero パネルを他人プロフと同仕様に統一（上半分のみ + 右側に評価）
 * - 右上のプロフ編集 gear アイコンを撤去（アイデンティティ section から行える）
 * - 各セクションが上から順にフェードインするスタガーアニメーション
 */
export function ProfileView({
  userId,
  profile,
  oshiGroups,
  tradeCount,
  ratingAvg,
  ratingCount,
}: Props) {
  const oshiSummaryText = oshiGroups
    .slice(0, 2)
    .map(
      (g) =>
        `${g.groupName}${
          g.members.length ? ` · ${g.members.map((m) => m.name).join(" / ")}` : ""
        }`,
    )
    .join(" ／ ");

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc] pb-[88px] text-[#3a324a]">
      {/* ヘッダー（safe-area + タイトルのみ — iter148: gear アイコン撤去） */}
      <div className="border-b border-[#3a324a14] bg-white px-[18px] pb-3 pt-12">
        <div className="mx-auto flex max-w-md items-center justify-between">
          <h1 className="text-[19px] font-extrabold tracking-wide text-gray-900">
            プロフ
          </h1>
        </div>
      </div>

      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-[18px] pt-[14px]">
        {/* iter148: hero — 他人プロフと同じ「上半分のみ + 右側評価」レイアウト */}
        <div
          className="animate-section-fade-down mb-[18px] overflow-hidden rounded-2xl p-5 text-white shadow-[0_10px_24px_rgba(166,149,216,0.30)]"
          style={{
            background: "linear-gradient(135deg, #a695d8, #a8d4e6)",
            animationDelay: "0ms",
          }}
        >
          <div className="flex items-center gap-3">
            <Avatar
              url={profile.avatarUrl}
              fallbackName={profile.displayName || profile.handle}
              size={56}
              variant="rounded"
              className="border-2 border-white/30"
            />
            <div className="min-w-0 flex-1">
              <div className="text-[16px] font-extrabold">
                @{profile.handle || "未設定"}
              </div>
              <div className="mt-0.5 text-[12px] font-bold opacity-90">
                {profile.displayName || "（表示名未設定）"}
              </div>
              <div className="mt-0.5 text-[10.5px] opacity-85">
                {profile.primaryArea ?? "エリア未設定"} ・ 取引 {tradeCount} 回
              </div>
            </div>
            {/* iter148: 評価サマリパネル — タップで評価一覧へ */}
            <Link
              href={`/users/${userId}/evaluations`}
              aria-label="評価一覧を見る"
              className="flex flex-shrink-0 flex-col items-center justify-center rounded-[12px] bg-white/15 px-2.5 py-1.5 backdrop-blur-sm transition-all active:scale-[0.96] active:bg-white/25"
            >
              <span
                className="text-[15px] font-extrabold leading-none"
                style={{ fontFamily: '"Inter Tight", sans-serif' }}
              >
                {ratingAvg !== null ? `★${ratingAvg.toFixed(1)}` : "★—"}
              </span>
              <span className="mt-0.5 text-[9.5px] tabular-nums opacity-90">
                {ratingCount} 件
              </span>
              <span className="mt-0.5 text-[8.5px] tracking-wide opacity-80">
                詳細 ›
              </span>
            </Link>
          </div>
        </div>

        {/* アイデンティティ */}
        <div
          className="animate-section-fade-down"
          style={{ animationDelay: "80ms" }}
        >
          <Section label="アイデンティティ">
            <Link href="/profile/edit" className="block">
              <RowItem
                icon="👤"
                title="プロフィール編集"
                sub="ハンドル・表示名・性別・エリア"
                chevron
              />
            </Link>
            <Link href="/profile/oshi" className="block">
              <RowItem
                icon="💜"
                title="推し設定"
                sub={
                  oshiGroups.length === 0
                    ? "未設定 · タップで追加"
                    : `${oshiGroups.length}グループ · ${oshiSummaryText}`
                }
                chevron
              />
            </Link>
            <Link href="/schedules" className="block">
              <RowItem
                icon="📅"
                title="スケジュール"
                sub="自分の予定（取引と無関係の用事も登録可）"
                chevron
              />
            </Link>
          </Section>
        </div>

        {/* 通知・サポート */}
        <div
          className="animate-section-fade-down"
          style={{ animationDelay: "160ms" }}
        >
          <Section label="通知・サポート">
            <RowLink
              href="/settings/notifications"
              icon="🔔"
              title="通知設定"
              sub="メール通知の ON/OFF"
            />
            <RowLink
              href="/help"
              icon="?"
              title="ヘルプ・FAQ"
              sub="使い方・取引の流れ・運営連絡"
            />
          </Section>
        </div>

        {/* Logout */}
        <div
          className="animate-section-fade-down"
          style={{ animationDelay: "240ms" }}
        >
          <Section>
            <LogoutRow />
          </Section>
        </div>

        <div className="pb-3 pt-1 text-center text-[10px] text-[#3a324a4d]">
          Megrum MVP · build dev
        </div>
      </div>
    </main>
  );
}

/* ─── Sub-components ─────────────────────────────────────── */

function Section({
  label,
  hint,
  children,
}: {
  label?: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-3.5">
      {label && (
        <div className="mb-1.5 flex items-baseline justify-between px-1">
          <span className="text-[11px] font-bold uppercase tracking-wider text-[#a695d8]">
            {label}
          </span>
          {hint && (
            <span className="text-[10px] text-[#3a324a8c]">{hint}</span>
          )}
        </div>
      )}
      <div className="overflow-hidden rounded-[14px] border border-[#3a324a0f] bg-white">
        {children}
      </div>
    </div>
  );
}

function Row({ children }: { children: React.ReactNode }) {
  return (
    <div className="border-b border-[#3a324a0f] last:border-0">{children}</div>
  );
}

/**
 * iter83: クリック可能な行（Row + RowItem の chevron 付き Link）
 */
function RowLink({
  href,
  icon,
  title,
  sub,
}: {
  href: string;
  icon: string;
  title: string;
  sub?: string;
}) {
  return (
    <Row>
      <Link href={href} className="block active:scale-[0.99]">
        <RowItem icon={icon} title={title} sub={sub} chevron />
      </Link>
    </Row>
  );
}

/**
 * 統一規格の Row 内コンテンツ:
 *   - icon: 32x32 の固定四角ボックス（中央揃え、絵文字/シンボル何でも同サイズ）
 *   - title + sub の左揃え
 *   - 右端: chevron or 「準備中」chip（大きさ固定）
 *   - 全体は items-center、padding 固定（14px 14px）
 */
function RowItem({
  icon,
  title,
  sub,
  subColor,
  chevron,
  comingSoon,
}: {
  icon: string;
  title: string;
  sub?: string;
  subColor?: string;
  chevron?: boolean;
  comingSoon?: boolean;
}) {
  return (
    <div
      className={`flex items-center gap-3 px-3.5 py-3 ${
        comingSoon ? "opacity-60" : ""
      }`}
    >
      <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center text-[18px] leading-none">
        {icon}
      </div>
      <div className="min-w-0 flex-1">
        <div className="text-[13px] font-bold leading-tight">{title}</div>
        {sub && (
          <div
            className="mt-0.5 text-[10.5px] leading-snug"
            style={{ color: subColor ?? "#3a324a8c" }}
          >
            {sub}
          </div>
        )}
      </div>
      <div className="flex w-[44px] flex-shrink-0 items-center justify-end">
        {chevron && (
          <span className="text-[16px] font-bold leading-none text-[#a695d8]">
            ›
          </span>
        )}
        {comingSoon && (
          <span className="rounded-full bg-[#3a324a08] px-2 py-0.5 text-[9.5px] font-bold text-[#3a324a8c]">
            準備中
          </span>
        )}
      </div>
    </div>
  );
}

function LogoutRow() {
  const [pending, startTransition] = useTransition();
  return (
    <div className="border-b border-[#3a324a0f] last:border-0">
      <form
        action={() => {
          startTransition(async () => {
            await logout();
          });
        }}
      >
        <button
          type="submit"
          disabled={pending}
          className="block w-full px-3.5 py-3 text-center text-[12.5px] font-semibold text-[#3a324a8c] disabled:opacity-50"
        >
          {pending ? "ログアウト中…" : "ログアウト"}
        </button>
      </form>
    </div>
  );
}
