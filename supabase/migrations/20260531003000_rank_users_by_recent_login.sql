-- Search sorting helper.
-- Returns only the relative rank for candidate users so clients can sort
-- search results by recent login without exposing login timestamps.

create or replace function public.rank_users_by_recent_login(p_user_ids uuid[])
returns table (
  user_id uuid,
  login_rank integer
)
language sql
security definer
set search_path = public
as $$
  select
    ranked.user_id,
    ranked.login_rank::integer
  from (
    select
      u.id as user_id,
      row_number() over (
        order by coalesce(u.last_login_at, u.created_at) desc, u.created_at desc, u.id
      ) as login_rank
    from public.users u
    where u.id = any(coalesce(p_user_ids, '{}'::uuid[]))
      and u.account_status = 'active'
  ) ranked;
$$;

revoke all on function public.rank_users_by_recent_login(uuid[]) from public;
grant execute on function public.rank_users_by_recent_login(uuid[]) to authenticated;
