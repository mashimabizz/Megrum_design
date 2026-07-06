-- 自分のグルームにもいいねできるようにする（iter1226.308）。
-- 20260706170000 でRLSは緩和済みだったが、実際のいいねは
-- set_groom_like_for_viewer RPC 経由のため、RPC内の own-post ガードも解除する。
-- ただし自分いいねでの掲載期限（expires_at）延長はさせない。
create or replace function public.set_groom_like_for_viewer(
  p_post_id uuid,
  p_is_liked boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_like_count integer := 0;
  is_own_post boolean := false;
begin
  if auth.uid() is null then
    raise exception 'login required';
  end if;

  if p_is_liked then
    if not public.can_view_groom_post(p_post_id, auth.uid()) then
      raise exception 'groom post is not visible';
    end if;

    select exists (
      select 1
        from public.groom_posts gp
       where gp.id = p_post_id
         and gp.user_id = auth.uid()
    ) into is_own_post;

    insert into public.groom_reactions (
      groom_post_id,
      user_id,
      reaction_type
    )
    values (
      p_post_id,
      auth.uid(),
      'like'
    )
    on conflict (groom_post_id, user_id, reaction_type) do nothing;

    get diagnostics inserted_like_count = row_count;

    if inserted_like_count > 0 and not is_own_post then
      update public.groom_posts
         set expires_at = greatest(coalesce(expires_at, now()), now()) + interval '3 hours',
             updated_at = now()
       where id = p_post_id
         and status = 'published';
    end if;
  else
    delete from public.groom_reactions
     where groom_post_id = p_post_id
       and user_id = auth.uid()
       and reaction_type = 'like';
  end if;
end;
$$;

revoke all on function public.set_groom_like_for_viewer(uuid, boolean) from public;
grant execute on function public.set_groom_like_for_viewer(uuid, boolean) to authenticated;
