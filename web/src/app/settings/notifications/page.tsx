import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { NotificationSettingsView } from "./NotificationSettingsView";

export const metadata = {
  title: "通知設定 — Megrum",
};

export default async function NotificationSettingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: settings } = await supabase
    .from("user_notification_settings")
    .select("email_enabled")
    .eq("user_id", user.id)
    .maybeSingle();

  const emailEnabled =
    (settings?.email_enabled as boolean | undefined) ?? true;

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="通知設定"
        sub="チャネルごとの ON/OFF を切替"
        backHref="/settings"
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        <NotificationSettingsView
          emailEnabled={emailEnabled}
          email={user.email ?? null}
        />
      </div>
    </main>
  );
}
