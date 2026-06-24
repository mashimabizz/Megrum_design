-- ホーム候補詳細の所有者表示で性別を使えるよう、ホーム用ユーザーサマリに gender を追加する。

drop function if exists public.list_home_user_summaries_for_viewer(uuid, uuid, integer);

create or replace function public.list_home_user_summaries_for_viewer(
  p_user_id uuid default null,
  p_excluded_user_id uuid default null,
  p_limit integer default 500
)
returns table (
  id uuid,
  handle text,
  display_name text,
  primary_area text,
  avatar_url text,
  gender text,
  age integer,
  payment_methods text[],
  payment_note text,
  is_test_account boolean,
  average_stars double precision,
  evaluation_count integer,
  completed_trade_count integer
)
language sql
security definer
set search_path = public
as $$
  select
    u.id,
    u.handle,
    u.display_name,
    u.primary_area,
    u.avatar_url,
    u.gender,
    u.age,
    u.payment_methods,
    u.payment_note,
    u.is_test_account,
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
  where auth.uid() is not null
    and coalesce(u.account_status, 'active') not in ('suspended', 'deletion_requested', 'deleted')
    and (p_user_id is null or u.id = p_user_id)
    and (p_excluded_user_id is null or u.id <> p_excluded_user_id)
  group by
    u.id,
    u.handle,
    u.display_name,
    u.primary_area,
    u.avatar_url,
    u.gender,
    u.age,
    u.payment_methods,
    u.payment_note,
    u.is_test_account
  order by u.updated_at desc, u.id
  limit greatest(1, least(coalesce(p_limit, 500), 500));
$$;

comment on function public.list_home_user_summaries_for_viewer(uuid, uuid, integer) is
  'ホーム候補用に、ユーザーの公開プロフィール最小情報、性別、評価サマリを一覧取得する。';

revoke all on function public.list_home_user_summaries_for_viewer(uuid, uuid, integer) from public;
grant execute on function public.list_home_user_summaries_for_viewer(uuid, uuid, integer) to authenticated;
