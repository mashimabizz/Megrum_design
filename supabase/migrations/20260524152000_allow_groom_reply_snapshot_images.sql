-- =====================================================================
-- iter165.1: Groom reply snapshot image access
-- =====================================================================
-- 目的:
-- - グルーム投稿が expired / archived になった後も、返信スレッド参加者は
--   返信時点の投稿画像を署名URLで見返せるようにする。

create or replace function public.can_view_groom_object(object_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.groom_posts gp
     where gp.image_path = object_name
       and public.can_view_groom_post(gp.id, auth.uid())
  )
  or exists (
    select 1
      from public.groom_replies gr
     where gr.groom_snapshot ->> 'image_path' = object_name
       and (gr.sender_id = auth.uid() or gr.recipient_id = auth.uid())
  );
$$;

revoke all on function public.can_view_groom_object(text) from public;
grant execute on function public.can_view_groom_object(text) to authenticated;

-- =====================================================================
-- 完了
-- =====================================================================
