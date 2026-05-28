import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ScheduleForm } from "../ScheduleForm";

export const metadata = {
  title: "予定を編集 — Megrum",
};

export default async function ScheduleEditPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data } = await supabase
    .from("schedules")
    .select("id, title, start_at, end_at, all_day, note")
    .eq("id", id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (!data) notFound();

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="予定を編集" backHref="/schedules" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-12 pt-5">
        <ScheduleForm
          mode="edit"
          initial={{
            id: data.id,
            title: data.title,
            startAt: data.start_at,
            endAt: data.end_at,
            allDay: data.all_day,
            note: data.note,
          }}
        />
      </div>
    </main>
  );
}
