import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ScheduleForm } from "../ScheduleForm";

export const metadata = {
  title: "予定を追加 — Megrum",
};

export default async function ScheduleNewPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="予定を追加" backHref="/schedules" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-12 pt-5">
        <ScheduleForm mode="create" />
      </div>
    </main>
  );
}
