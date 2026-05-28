import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "相手のスケジュール — Megrum",
};

/**
 * iter146：打診相手のスケジュール表示。
 *
 * 表示条件：
 * - I am sender or receiver of proposal `id`
 * - proposal.expose_calendar = true
 *
 * 表示対象：相手（partner）の schedules テーブル全件。
 */
export default async function PartnerSchedulesPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user: me },
  } = await supabase.auth.getUser();
  if (!me) redirect("/login");

  const { data: proposal } = await supabase
    .from("proposals")
    .select(
      "id, sender_id, receiver_id, expose_calendar, status, meetup_start_at, meetup_end_at",
    )
    .eq("id", id)
    .maybeSingle();
  if (!proposal) notFound();

  const isSender = proposal.sender_id === me.id;
  const isReceiver = proposal.receiver_id === me.id;
  if (!isSender && !isReceiver) notFound();
  if (!proposal.expose_calendar) {
    // 共有 OFF なら詳細画面へ戻す
    redirect(`/proposals/${id}`);
  }

  const partnerId = (isSender ? proposal.receiver_id : proposal.sender_id) as
    | string
    | null;
  if (!partnerId) notFound();

  // partner の最低限のプロフ情報（ヘッダー用）
  const { data: partner } = await supabase
    .from("users")
    .select("id, handle, display_name, avatar_url")
    .eq("id", partnerId)
    .maybeSingle();

  // partner の schedules を全件取得（過去 1 ヶ月以降）
  const oneMonthAgo = new Date();
  oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
  const { data: rows } = await supabase
    .from("schedules")
    .select("id, title, start_at, end_at, all_day, note")
    .eq("user_id", partnerId)
    .gte("end_at", oneMonthAgo.toISOString())
    .order("start_at", { ascending: true });

  type Row = {
    id: string;
    title: string;
    start_at: string;
    end_at: string;
    all_day: boolean;
    note: string | null;
  };
  const items = ((rows as Row[]) ?? []).map((r) => ({
    id: r.id,
    title: r.title,
    startAt: r.start_at,
    endAt: r.end_at,
    allDay: r.all_day,
    note: r.note,
  }));

  // 提案された待ち合わせ時刻（ハイライト表示用）
  const meetupStart = (proposal.meetup_start_at as string | null) ?? null;
  const meetupEnd = (proposal.meetup_end_at as string | null) ?? null;

  // 過去・今後で分割
  const nowMs = Date.now();
  const upcoming = items.filter((i) => new Date(i.endAt).getTime() >= nowMs);
  const past = items.filter((i) => new Date(i.endAt).getTime() < nowMs);

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title={partner ? `@${partner.handle} の予定` : "相手の予定"}
        sub="スケジュール共有 ON"
        backHref={`/proposals/${id}`}
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        {/* 提案中の待ち合わせ時刻バナー */}
        {meetupStart && meetupEnd && (
          <div className="mb-3 rounded-[14px] border border-[#a695d855] bg-[linear-gradient(120deg,#a695d80f,#a8d4e60f)] px-3.5 py-2.5">
            <div className="text-[10.5px] font-bold tracking-[0.3px] text-[#a695d8]">
              提案中の待ち合わせ
            </div>
            <div className="mt-0.5 text-[12.5px] font-extrabold tabular-nums text-[#3a324a]">
              {fmtRange(meetupStart, meetupEnd, false)}
            </div>
            <div className="mt-1 text-[10.5px] leading-snug text-[#3a324a8c]">
              ↓ この時間と被る予定があるか確認しましょう
            </div>
          </div>
        )}

        {items.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white py-10 text-center text-[12px] text-[#3a324a8c]">
            相手は予定を登録していません
          </div>
        ) : (
          <div className="space-y-4">
            {upcoming.length > 0 && (
              <Section label="今後の予定" count={upcoming.length}>
                {upcoming.map((s) => (
                  <ReadOnlyScheduleCard
                    key={s.id}
                    item={s}
                    meetupStart={meetupStart}
                    meetupEnd={meetupEnd}
                  />
                ))}
              </Section>
            )}
            {past.length > 0 && (
              <Section label="過去" count={past.length} dim>
                {past.slice(0, 10).map((s) => (
                  <ReadOnlyScheduleCard
                    key={s.id}
                    item={s}
                    meetupStart={meetupStart}
                    meetupEnd={meetupEnd}
                  />
                ))}
              </Section>
            )}
          </div>
        )}

        {/* 戻るリンク */}
        <div className="mt-6 text-center">
          <Link
            href={`/proposals/${id}`}
            className="inline-block text-[12px] font-bold text-[#a695d8]"
          >
            ← 打診詳細に戻る
          </Link>
        </div>
      </div>
    </main>
  );
}

function Section({
  label,
  count,
  dim,
  children,
}: {
  label: string;
  count: number;
  dim?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div
        className={`mb-1.5 flex items-baseline justify-between px-1 ${
          dim ? "opacity-60" : ""
        }`}
      >
        <span className="text-[10.5px] font-bold uppercase tracking-[0.6px] text-[#3a324a8c]">
          {label}
        </span>
        <span className="text-[9.5px] font-bold tabular-nums text-[#a695d8]">
          {count} 件
        </span>
      </div>
      <div className="space-y-2">{children}</div>
    </div>
  );
}

function ReadOnlyScheduleCard({
  item,
  meetupStart,
  meetupEnd,
}: {
  item: {
    id: string;
    title: string;
    startAt: string;
    endAt: string;
    allDay: boolean;
    note: string | null;
  };
  meetupStart: string | null;
  meetupEnd: string | null;
}) {
  // 提案中の待ち合わせと重なるか
  const conflicts =
    meetupStart && meetupEnd
      ? new Date(item.endAt).getTime() > new Date(meetupStart).getTime() &&
        new Date(item.startAt).getTime() < new Date(meetupEnd).getTime()
      : false;
  return (
    <div
      className={`rounded-2xl border bg-white px-3.5 py-3 ${
        conflicts
          ? "border-[#d9826b] shadow-[0_4px_12px_rgba(217,130,107,0.18)]"
          : "border-[#3a324a14]"
      }`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="text-[13px] font-extrabold leading-snug text-[#3a324a]">
          {item.title}
        </div>
        {conflicts && (
          <span className="flex-shrink-0 rounded-full bg-[#d9826b] px-2 py-[2px] text-[9px] font-extrabold tracking-[0.3px] text-white">
            時間が重複
          </span>
        )}
      </div>
      <div className="mt-1 text-[11px] tabular-nums text-[#3a324a8c]">
        {fmtRange(item.startAt, item.endAt, item.allDay)}
      </div>
      {item.note && (
        <div className="mt-1.5 text-[11px] leading-snug text-[#3a324a]">
          {item.note}
        </div>
      )}
    </div>
  );
}

function fmtRange(startISO: string, endISO: string, allDay: boolean): string {
  const sd = new Date(startISO);
  const ed = new Date(endISO);
  const wd = (d: Date) =>
    ["日", "月", "火", "水", "木", "金", "土"][d.getDay()];
  const date = (d: Date) => `${d.getMonth() + 1}/${d.getDate()} (${wd(d)})`;
  const time = (d: Date) =>
    `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;

  if (allDay) {
    if (
      sd.getFullYear() === ed.getFullYear() &&
      sd.getMonth() === ed.getMonth() &&
      sd.getDate() === ed.getDate()
    ) {
      return `${date(sd)} 終日`;
    }
    return `${date(sd)} 〜 ${date(ed)}`;
  }
  const sameDay =
    sd.getFullYear() === ed.getFullYear() &&
    sd.getMonth() === ed.getMonth() &&
    sd.getDate() === ed.getDate();
  if (sameDay) {
    return `${date(sd)} ${time(sd)} 〜 ${time(ed)}`;
  }
  return `${date(sd)} ${time(sd)} 〜 ${date(ed)} ${time(ed)}`;
}
