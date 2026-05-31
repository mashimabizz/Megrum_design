-- =====================================================================
-- iter346: Swift Native 相手プロフィール / 評価一覧 RPC
-- =====================================================================
-- user_evaluations のRLSは取引参加者向けに閉じているため、プロフィールで
-- 公開してよい最小情報だけを返す SECURITY DEFINER RPC を用意する。

create or replace function public.get_public_user_profile_for_viewer(
  p_user_id uuid
)
returns table (
  id uuid,
  handle text,
  display_name text,
  avatar_url text,
  primary_area text,
  account_status text,
  average_stars double precision,
  evaluation_count integer,
  completed_trade_count integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return;
  end if;

  return query
  select
    u.id,
    u.handle,
    u.display_name,
    u.avatar_url,
    u.primary_area,
    u.account_status,
    avg(e.stars)::double precision as average_stars,
    count(e.id)::integer as evaluation_count,
    (
      select count(*)::integer
      from public.proposals p
      where (p.sender_id = u.id or p.receiver_id = u.id)
        and p.status = 'completed'
    ) as completed_trade_count
  from public.users u
  left join public.user_evaluations e
    on e.ratee_id = u.id
  where u.id = p_user_id
    and coalesce(u.account_status, 'active') not in ('suspended', 'deletion_requested', 'deleted')
  group by u.id, u.handle, u.display_name, u.avatar_url, u.primary_area, u.account_status;
end;
$$;

comment on function public.get_public_user_profile_for_viewer(uuid) is
  'ログイン済みユーザー向けに、相手プロフィール上半分と評価サマリに必要な公開情報だけを返す。';

create or replace function public.list_user_evaluations_for_profile(
  p_user_id uuid,
  p_limit integer default 50
)
returns table (
  id uuid,
  rater_id uuid,
  rater_handle text,
  rater_display_name text,
  rater_avatar_url text,
  stars integer,
  comment text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return;
  end if;

  return query
  select
    e.id,
    e.rater_id,
    r.handle as rater_handle,
    r.display_name as rater_display_name,
    r.avatar_url as rater_avatar_url,
    e.stars,
    e.comment,
    e.created_at
  from public.user_evaluations e
  join public.users ratee
    on ratee.id = e.ratee_id
  left join public.users r
    on r.id = e.rater_id
  where e.ratee_id = p_user_id
    and coalesce(ratee.account_status, 'active') not in ('suspended', 'deletion_requested', 'deleted')
    and coalesce(r.account_status, 'active') not in ('suspended', 'deletion_requested', 'deleted')
  order by e.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
end;
$$;

comment on function public.list_user_evaluations_for_profile(uuid, integer) is
  '相手プロフィールの評価一覧に表示する、評価者の公開情報と星・コメントだけを返す。';

revoke all on function public.get_public_user_profile_for_viewer(uuid) from public;
revoke all on function public.list_user_evaluations_for_profile(uuid, integer) from public;
grant execute on function public.get_public_user_profile_for_viewer(uuid) to authenticated;
grant execute on function public.list_user_evaluations_for_profile(uuid, integer) to authenticated;
