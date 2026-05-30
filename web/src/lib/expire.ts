/**
 * iter78-E: 打診の lazy expire（cron 不要）
 *
 * proposals.expires_at < 現在時刻 で status が
 * sent / negotiating / agreement_one_side のものを `expired` にまとめて遷移させる。
 *
 * 使い方：取引一覧・打診一覧・取引チャット・打診詳細など、
 * proposals を読むサーバコンポーネントで `await autoExpireProposals(supabase, userId)`
 * を fetch 前に呼ぶ。
 *
 * RLS：自分が sender or receiver の打診のみ更新できる UPDATE policy が既に存在するため、
 * 自分の関わる打診のみ反映される。他人の打診は別 user の SSR で expire される。
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import { participantOrFilter } from "@/lib/supabaseFilters";

export async function autoExpireProposals(
  supabase: SupabaseClient,
  userId: string,
): Promise<void> {
  const nowIso = new Date().toISOString();
  await supabase
    .from("proposals")
    .update({ status: "expired", last_action_at: nowIso })
    .or(participantOrFilter("sender_id", "receiver_id", userId))
    .in("status", ["sent", "negotiating", "agreement_one_side"])
    .lt("expires_at", nowIso);
}
