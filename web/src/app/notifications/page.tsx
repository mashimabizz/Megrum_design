import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { BottomNav } from "@/components/home/BottomNav";
import { HeaderBack } from "@/components/auth/HeaderBack";
import {
  NotificationsView,
  type NotificationItem,
} from "./NotificationsView";

export const metadata = {
  title: "通知 — Megrum",
};

export default async function NotificationsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 未読を上、既読を下、それぞれ created_at desc
  const { data: rows } = await supabase
    .from("notifications")
    .select("id, kind, title, body, link_path, read_at, created_at")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(100);

  const items: NotificationItem[] = ((rows as
    | {
        id: string;
        kind: string;
        title: string;
        body: string | null;
        link_path: string | null;
        read_at: string | null;
        created_at: string;
      }[]
    | null) ?? []
  ).map((r) => ({
    id: r.id,
    kind: r.kind as NotificationItem["kind"],
    title: r.title,
    body: r.body,
    linkPath: r.link_path,
    readAt: r.read_at,
    createdAt: r.created_at,
  }));

  const unreadCount = items.filter((i) => !i.readAt).length;

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc] pb-[88px]">
      <HeaderBack
        title="通知"
        sub={
          unreadCount > 0
            ? `未読 ${unreadCount} 件 / 全 ${items.length} 件`
            : `全 ${items.length} 件 すべて既読`
        }
        backHref="/"
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-4 pt-3">
        <NotificationsView items={items} unreadCount={unreadCount} />
      </div>
      <BottomNav />
    </main>
  );
}
