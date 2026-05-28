import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ProfileEditForm } from "./ProfileEditForm";

export const metadata = {
  title: "プロフィール編集 — Megrum",
};

export default async function ProfileEditPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("users")
    .select("handle, display_name, gender, primary_area, avatar_url")
    .eq("id", user.id)
    .maybeSingle();

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="プロフィール編集" backHref="/profile" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-12 pt-5">
        <ProfileEditForm
          initial={{
            handle: profile?.handle ?? "",
            displayName: profile?.display_name ?? "",
            gender:
              (profile?.gender as
                | "female"
                | "male"
                | "other"
                | "no_answer"
                | null) ?? null,
            primaryArea: profile?.primary_area ?? "",
            avatarUrl: (profile?.avatar_url as string | null) ?? null,
          }}
        />
      </div>
    </main>
  );
}
