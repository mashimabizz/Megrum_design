-- iter1223: メグルムプラス（月額500円）の権限・ランキング・個別募集上限の土台。

alter table public.subscriptions
  drop constraint if exists subscriptions_plan_type_check;

alter table public.subscriptions
  add constraint subscriptions_plan_type_check check (
    plan_type in (
      'megrum_plus_monthly',
      'premium_monthly',
      'premium_yearly',
      'meguri_plus_monthly',
      'monthly',
      'yearly'
    )
  );

comment on table public.subscriptions is
  'メグルムプラス等の有料プラン契約。Stripe/Apple/Google/manual を同じ形で保持する。';

comment on table public.user_entitlements is
  'ユーザーに現在付与されている機能権限。メグルムプラス判定や管理者上書きの集約点。';

create or replace function public.list_megrum_plus_user_ids_for_viewer(
  p_user_ids uuid[]
)
returns table (
  user_id uuid
)
language sql
stable
security definer
set search_path = public
as $$
  select distinct entitlement.user_id
    from public.user_entitlements entitlement
   where auth.uid() is not null
     and entitlement.user_id = any(coalesce(p_user_ids, '{}'::uuid[]))
     and entitlement.feature_key = 'megrum_plus'
     and entitlement.active = true
     and (
       entitlement.expires_at is null
       or entitlement.expires_at > now()
     );
$$;

comment on function public.list_megrum_plus_user_ids_for_viewer(uuid[]) is
  'ホーム/検索ランキング用に、指定ユーザーIDのうちメグルムプラスが有効なIDだけを返す。';

revoke all on function public.list_megrum_plus_user_ids_for_viewer(uuid[]) from public;
grant execute on function public.list_megrum_plus_user_ids_for_viewer(uuid[]) to authenticated;

create or replace function public.enforce_individual_listing_free_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  active_listing_count integer;
begin
  if new.status not in ('active', 'paused', 'matched') then
    return new;
  end if;

  if public.has_active_entitlement(new.user_id, 'megrum_plus') then
    return new;
  end if;

  select count(*)
    into active_listing_count
    from public.listings listing
   where listing.user_id = new.user_id
     and listing.status in ('active', 'paused', 'matched')
     and (tg_op = 'INSERT' or listing.id <> new.id);

  if active_listing_count >= 3 then
    raise exception '無料プランでは個別募集は3件までです'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_individual_listing_free_limit on public.listings;
create trigger trg_enforce_individual_listing_free_limit
  before insert or update of user_id, status on public.listings
  for each row execute function public.enforce_individual_listing_free_limit();

create or replace function public.sync_megrum_plus_purchase_for_viewer(
  p_product_id text,
  p_transaction_id text,
  p_original_transaction_id text,
  p_expires_at timestamptz default null,
  p_verified_at timestamptz default now()
)
returns table (
  feature_key text,
  active boolean,
  source text,
  granted_at timestamptz,
  expires_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  viewer_id uuid := auth.uid();
  subscription_id uuid;
  active_access boolean;
  provider_subscription_id text;
begin
  if viewer_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  if p_product_id <> 'megrum.plus.monthly' then
    raise exception 'unsupported product_id: %', p_product_id using errcode = '22023';
  end if;

  provider_subscription_id := nullif(trim(coalesce(p_original_transaction_id, p_transaction_id)), '');
  if provider_subscription_id is null then
    raise exception 'transaction id is required' using errcode = '22023';
  end if;

  if p_expires_at is null then
    raise exception 'subscription expiration is required' using errcode = '22023';
  end if;

  active_access := p_expires_at > now();

  insert into public.subscriptions (
    user_id,
    plan_type,
    status,
    started_at,
    current_period_start,
    current_period_end,
    transaction_provider,
    transaction_provider_subscription_id,
    product_id,
    metadata
  )
  values (
    viewer_id,
    'megrum_plus_monthly',
    case when active_access then 'active' else 'expired' end,
    coalesce(p_verified_at, now()),
    coalesce(p_verified_at, now()),
    p_expires_at,
    'apple',
    provider_subscription_id,
    p_product_id,
    jsonb_build_object(
      'transaction_id', p_transaction_id,
      'original_transaction_id', p_original_transaction_id,
      'verified_at', coalesce(p_verified_at, now())
    )
  )
  on conflict (transaction_provider, transaction_provider_subscription_id)
  do update set
    plan_type = excluded.plan_type,
    status = excluded.status,
    current_period_start = excluded.current_period_start,
    current_period_end = excluded.current_period_end,
    product_id = excluded.product_id,
    metadata = excluded.metadata,
    updated_at = now()
  where public.subscriptions.user_id = excluded.user_id
  returning id into subscription_id;

  if subscription_id is null then
    raise exception 'purchase transaction already belongs to another user'
      using errcode = '23505';
  end if;

  insert into public.user_entitlements (
    user_id,
    feature_key,
    active,
    source,
    subscription_id,
    override_id,
    granted_at,
    expires_at,
    metadata
  )
  values (
    viewer_id,
    'megrum_plus',
    active_access,
    'subscription',
    subscription_id,
    null,
    coalesce(p_verified_at, now()),
    p_expires_at,
    jsonb_build_object(
      'product_id', p_product_id,
      'transaction_id', p_transaction_id,
      'original_transaction_id', p_original_transaction_id
    )
  )
  on conflict (user_id, feature_key)
  do update set
    active = excluded.active,
    source = excluded.source,
    subscription_id = excluded.subscription_id,
    override_id = null,
    expires_at = excluded.expires_at,
    metadata = excluded.metadata,
    updated_at = now();

  return query
    select entitlement.feature_key,
           entitlement.active,
           entitlement.source,
           entitlement.granted_at,
           entitlement.expires_at,
           entitlement.updated_at
      from public.user_entitlements entitlement
     where entitlement.user_id = viewer_id
       and entitlement.feature_key in ('megrum_plus', 'premium', 'meguri_plus')
     order by entitlement.feature_key;
end;
$$;

comment on function public.sync_megrum_plus_purchase_for_viewer(text, text, text, timestamptz, timestamptz) is
  'StoreKitで検証済みのメグルムプラス購入を user_entitlements へ同期する。App Store Server APIによるサーバー検証は本番前に追加する。';

revoke all on function public.sync_megrum_plus_purchase_for_viewer(text, text, text, timestamptz, timestamptz) from public;
grant execute on function public.sync_megrum_plus_purchase_for_viewer(text, text, text, timestamptz, timestamptz) to authenticated;
