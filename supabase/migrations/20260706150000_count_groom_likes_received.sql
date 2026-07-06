-- =====================================================================
-- iter1226.298: プロフィールにグルームでもらったいいね数を表示する
-- =====================================================================
-- groom_reactions は RLS で自分の行しか読めないため、
-- 「そのユーザーのグルームが受け取った like 総数」を返す集計RPCを用意する。
-- 件数のみの公開情報で、誰が押したかは開示しない。

create or replace function public.count_groom_likes_received(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
  from public.groom_reactions reaction
  join public.groom_posts post on post.id = reaction.groom_post_id
  where post.user_id = p_user_id
    and reaction.reaction_type = 'like';
$$;

revoke all on function public.count_groom_likes_received(uuid) from public;
grant execute on function public.count_groom_likes_received(uuid) to authenticated;

-- =====================================================================
-- 完了
-- =====================================================================
