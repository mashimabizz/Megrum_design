import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { BottomNav } from "@/components/home/BottomNav";
import { SchedulesView, type ScheduleItem } from "./SchedulesView";

export const metadata = {
  title: "スケジュール — Megrum",
};

type ScheduleRow = {
  id: string;
  title: string;
  start_at: string;
  end_at: string;
  all_day: boolean;
  note: string | null;
};

export default async function SchedulesPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: rows } = await supabase
    .from("schedules")
    .select("id, title, start_at, end_at, all_day, note")
    .eq("user_id", user.id)
    .order("start_at", { ascending: true });

  const items: ScheduleItem[] = ((rows as ScheduleRow[]) ?? []).map((r) => ({
    id: r.id,
    title: r.title,
    startAt: r.start_at,
    endAt: r.end_at,
    allDay: r.all_day,
    note: r.note,
  }));

  return (
    <>
      <main
        className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc] pb-[88px]"
        style={{
          fontFamily: '"Noto Sans JP", -apple-system, system-ui',
          color: "#3a324a",
        }}
      >
        <HeaderBack
          title="スケジュール"
          sub="自分の予定（AW とは別 · 打診時にカレンダー公開すると相手と重ね見可）"
          backHref="/profile"
        />

        <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-4 pt-4">
          <div className="mb-3 flex justify-end">
            <Link
              href="/schedules/new"
              className="inline-flex items-center gap-[5px] rounded-full bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-[14px] py-2 text-[12px] font-bold text-white shadow-[0_4px_10px_rgba(166,149,216,0.31)] transition-all duration-150 active:scale-[0.97]"
            >
              <svg
                width="11"
                height="11"
                viewBox="0 0 11 11"
                fill="none"
                stroke="#fff"
                strokeWidth="1.8"
                strokeLinecap="round"
              >
                <path d="M5.5 1v9M1 5.5h9" />
              </svg>
              予定を追加
            </Link>
          </div>
          <SchedulesView items={items} />
        </div>
      </main>
      <BottomNav />
    </>
  );
}
