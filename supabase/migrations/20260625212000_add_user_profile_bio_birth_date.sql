-- iter995: プロフィール編集の自己紹介と生年月日
-- 自己紹介は公開プロフィールで表示できる任意項目。
-- 生年月日は本人編集用の非公開項目で、公開プロフィールには年齢だけを使う。

alter table public.users
  add column if not exists bio text;

alter table public.users
  drop constraint if exists users_bio_length;

alter table public.users
  add constraint users_bio_length
  check (bio is null or char_length(bio) <= 500);

alter table public.users
  add column if not exists birth_date date;

alter table public.users
  drop constraint if exists users_birth_date_lower_bound;

alter table public.users
  add constraint users_birth_date_lower_bound
  check (birth_date is null or birth_date >= date '1900-01-01');

comment on column public.users.bio is
  'プロフィールに表示する自己紹介。公開プロフィールで表示できる任意テキスト。';

comment on column public.users.birth_date is
  '本人が編集する生年月日。公開プロフィールには直接表示しない。';

grant select (bio) on public.users to anon, authenticated;
grant select (birth_date) on public.users to authenticated;
grant update (bio, birth_date, age) on public.users to authenticated;

drop function if exists public.get_public_user_profile_for_viewer(uuid);

create or replace function public.get_public_user_profile_for_viewer(
  p_user_id uuid
)
returns table (
  id uuid,
  handle text,
  display_name text,
  bio text,
  avatar_url text,
  primary_area text,
  gender text,
  age integer,
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
    u.bio,
    u.avatar_url,
    u.primary_area,
    u.gender,
    u.age,
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
  group by
    u.id,
    u.handle,
    u.display_name,
    u.bio,
    u.avatar_url,
    u.primary_area,
    u.gender,
    u.age,
    u.account_status;
end;
$$;

comment on function public.get_public_user_profile_for_viewer(uuid) is
  'ログイン済みユーザー向けに、相手プロフィール上半分と評価サマリに必要な公開情報だけを返す。自己紹介 bio を含み、生年月日は含めない。';

revoke all on function public.get_public_user_profile_for_viewer(uuid) from public;
grant execute on function public.get_public_user_profile_for_viewer(uuid) to authenticated;
