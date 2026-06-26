-- =====================================================================
-- iter1221: アカウント退会申請の保存と進行中取引ガード
-- =====================================================================

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  reasons text[] not null default '{}',
  note text,
  requested_at timestamptz not null default now(),
  deletion_scheduled_at timestamptz not null default (now() + interval '30 days'),
  status text not null default 'requested' check (status in ('requested', 'cancelled', 'completed')),
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (cardinality(reasons) between 1 and 8),
  check (note is null or length(note) <= 500)
);

comment on table public.account_deletion_requests is
  '退会申請の理由・任意メモ・30日猶予予定日を保持する監査用テーブル。';

create index if not exists idx_account_deletion_requests_user
  on public.account_deletion_requests(user_id, requested_at desc);

create index if not exists idx_account_deletion_requests_status
  on public.account_deletion_requests(status, deletion_scheduled_at);

drop trigger if exists trg_account_deletion_requests_updated_at on public.account_deletion_requests;
create trigger trg_account_deletion_requests_updated_at
  before update on public.account_deletion_requests
  for each row execute function public.set_updated_at();

alter table public.account_deletion_requests enable row level security;

drop policy if exists "Users can read own account deletion requests"
  on public.account_deletion_requests;
create policy "Users can read own account deletion requests"
  on public.account_deletion_requests for select
  using (auth.uid() = user_id);

grant select on public.account_deletion_requests to authenticated;

create or replace function public.request_account_deletion_for_viewer(
  p_reasons text[] default '{}',
  p_note text default null
)
returns table (
  user_id uuid,
  account_status text,
  deletion_requested_at timestamptz,
  deletion_scheduled_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_reasons text[];
  v_note text;
  v_requested_at timestamptz := now();
  v_scheduled_at timestamptz := v_requested_at + interval '30 days';
  v_has_ongoing_trade boolean;
  v_updated_user_id uuid;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select coalesce(array_agg(reason order by reason), array[]::text[])
    into v_reasons
  from (
    select distinct left(btrim(raw_reason), 64) as reason
    from unnest(coalesce(p_reasons, array[]::text[])) as raw_reason
  ) normalized_reasons
  where reason <> '';

  if cardinality(v_reasons) = 0 then
    raise exception 'ACCOUNT_DELETION_REASON_REQUIRED' using errcode = '22023';
  end if;

  if cardinality(v_reasons) > 8 then
    raise exception 'ACCOUNT_DELETION_TOO_MANY_REASONS' using errcode = '22023';
  end if;

  v_note := nullif(left(btrim(coalesce(p_note, '')), 500), '');

  select exists (
    select 1
    from public.proposals p
    where (p.sender_id = v_user_id or p.receiver_id = v_user_id)
      and p.status in ('sent', 'negotiating', 'agreement_one_side', 'agreed')
  )
    into v_has_ongoing_trade;

  if v_has_ongoing_trade then
    raise exception 'ONGOING_TRADE_EXISTS' using errcode = 'P0001';
  end if;

  update public.users u
     set account_status = 'deletion_requested',
         deletion_requested_at = v_requested_at,
         updated_at = v_requested_at
   where u.id = v_user_id
     and coalesce(u.account_status, 'active') not in ('suspended', 'deleted')
   returning u.id into v_updated_user_id;

  if v_updated_user_id is null then
    raise exception 'ACCOUNT_DELETION_UNAVAILABLE' using errcode = 'P0001';
  end if;

  insert into public.account_deletion_requests (
    user_id,
    reasons,
    note,
    requested_at,
    deletion_scheduled_at,
    status
  )
  values (
    v_user_id,
    v_reasons,
    v_note,
    v_requested_at,
    v_scheduled_at,
    'requested'
  );

  return query
  select
    v_user_id,
    'deletion_requested'::text,
    v_requested_at,
    v_scheduled_at;
end;
$$;

grant execute on function public.request_account_deletion_for_viewer(text[], text)
  to authenticated;
