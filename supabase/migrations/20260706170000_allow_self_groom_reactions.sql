-- 自分のグルームにもいいねできるようにする（iter1226.303）。
-- 既存ポリシーの gp.user_id <> auth.uid() 条件を外す以外は同じ。
drop policy if exists "Users can insert own groom reactions" on public.groom_reactions;
create policy "Users can insert own groom reactions"
  on public.groom_reactions for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.groom_posts gp
      where gp.id = groom_reactions.groom_post_id
        and public.can_view_groom_post(gp.id, auth.uid())
    )
  );
