-- =====================================================================
-- iter1226.267: Revoke notification devices on account deletion request
-- =====================================================================
-- Account deletion requests immediately move the user into
-- deletion_requested. Stop future mobile push delivery at the same boundary
-- by revoking every active device token owned by the requester.

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

  update public.notification_devices device
     set revoked_at = v_requested_at,
         updated_at = v_requested_at
   where device.user_id = v_user_id
     and device.revoked_at is null;

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
