-- iter166: 管理者権限・監査ログ・有料権限のサーバー管理基盤
-- 管理者画面は service role 経由でのみ変更し、クライアントから直接変更できない。

create table public.admin_roles (
  user_id uuid primary key references public.users(id) on delete cascade,
  role text not null check (role in ('owner', 'support', 'trust_safety', 'billing', 'viewer')),
  permissions text[] not null default '{}',
  status text not null default 'active' check (status in ('active', 'disabled')),
  requires_mfa boolean not null default true,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_admin_roles_status on public.admin_roles(status);
create index idx_admin_roles_role on public.admin_roles(role);

comment on table public.admin_roles is '管理者ロールと権限。変更は管理者Server Actionからservice roleで実行し、監査ログを残す。';
comment on column public.admin_roles.permissions is '例: users.read, users.update_status, roles.read, roles.manage, billing.read, entitlements.manage, audit.read。ownerまたは*は全権限。';

create trigger trg_admin_roles_updated_at
  before update on public.admin_roles
  for each row execute function public.set_updated_at();

create table public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text,
  reason text,
  before_state jsonb,
  after_state jsonb,
  request_ip text,
  user_agent text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index idx_admin_audit_logs_actor on public.admin_audit_logs(actor_user_id, created_at desc);
create index idx_admin_audit_logs_target on public.admin_audit_logs(target_type, target_id, created_at desc);
create index idx_admin_audit_logs_created_at on public.admin_audit_logs(created_at desc);

comment on table public.admin_audit_logs is '管理者操作の監査ログ。ユーザー状態、管理者権限、有料権限の変更を記録する。';

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  plan_type text not null check (plan_type in ('premium_monthly', 'premium_yearly', 'monthly', 'yearly')),
  status text not null check (
    status in (
      'incomplete',
      'incomplete_expired',
      'trialing',
      'active',
      'past_due',
      'cancelled',
      'canceled',
      'unpaid',
      'expired'
    )
  ),
  started_at timestamptz,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancelled_at timestamptz,
  cancel_at_period_end boolean not null default false,
  transaction_provider text not null check (transaction_provider in ('stripe', 'apple', 'google', 'manual')),
  transaction_provider_subscription_id text,
  transaction_provider_customer_id text,
  price_id text,
  product_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subscriptions
  add constraint subscriptions_provider_subscription_unique
  unique (transaction_provider, transaction_provider_subscription_id);
create index idx_subscriptions_user_status on public.subscriptions(user_id, status);
create index idx_subscriptions_customer on public.subscriptions(transaction_provider, transaction_provider_customer_id);

comment on table public.subscriptions is 'Premium等の有料プラン契約。Stripe/Apple/Google/manual を同じ形で保持する。';

create trigger trg_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

create table public.plan_overrides (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  feature_key text not null,
  active boolean not null default true,
  reason text not null,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by uuid references public.users(id) on delete set null,
  revoked_at timestamptz,
  revoked_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index idx_plan_overrides_user_feature on public.plan_overrides(user_id, feature_key, active);
create index idx_plan_overrides_expires_at on public.plan_overrides(expires_at);

comment on table public.plan_overrides is '管理者による有料機能・権限の手動付与/停止。必ずadmin_audit_logsとセットで扱う。';

create table public.user_entitlements (
  user_id uuid not null references public.users(id) on delete cascade,
  feature_key text not null,
  active boolean not null default true,
  source text not null check (source in ('subscription', 'manual_override', 'system', 'purchase')),
  subscription_id uuid references public.subscriptions(id) on delete set null,
  override_id uuid references public.plan_overrides(id) on delete set null,
  granted_at timestamptz not null default now(),
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, feature_key)
);

create index idx_user_entitlements_feature_active on public.user_entitlements(feature_key, active);
create index idx_user_entitlements_user_active on public.user_entitlements(user_id, active);
create index idx_user_entitlements_expires_at on public.user_entitlements(expires_at);

comment on table public.user_entitlements is 'ユーザーに現在付与されている機能権限。Premium判定や管理者上書きの集約点。';

create trigger trg_user_entitlements_updated_at
  before update on public.user_entitlements
  for each row execute function public.set_updated_at();

create table public.stripe_webhook_events (
  event_id text primary key,
  event_type text not null,
  status text not null default 'processing' check (status in ('processing', 'processed', 'failed', 'ignored')),
  payload jsonb not null,
  processed_at timestamptz,
  last_error text,
  created_at timestamptz not null default now()
);

create index idx_stripe_webhook_events_type on public.stripe_webhook_events(event_type, created_at desc);
create index idx_stripe_webhook_events_status on public.stripe_webhook_events(status, created_at desc);

comment on table public.stripe_webhook_events is 'Stripe webhookの冪等性・処理結果管理。event_idを主キーにして重複処理を防ぐ。';

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.admin_roles ar
      where ar.user_id = auth.uid()
        and ar.status = 'active'
    );
$$;

create or replace function public.admin_has_permission(requested_permission text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.admin_roles ar
      where ar.user_id = auth.uid()
        and ar.status = 'active'
        and (
          ar.role = 'owner'
          or '*' = any(ar.permissions)
          or requested_permission = any(ar.permissions)
          or (split_part(requested_permission, '.', 1) || '.*') = any(ar.permissions)
        )
    );
$$;

revoke all on function public.is_admin() from public;
revoke all on function public.admin_has_permission(text) from public;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.admin_has_permission(text) to authenticated;

alter table public.admin_roles enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.subscriptions enable row level security;
alter table public.plan_overrides enable row level security;
alter table public.user_entitlements enable row level security;
alter table public.stripe_webhook_events enable row level security;

create policy "Admins can read roles" on public.admin_roles
  for select to authenticated
  using (user_id = auth.uid() or public.admin_has_permission('roles.read'));

create policy "Admins can read audit logs" on public.admin_audit_logs
  for select to authenticated
  using (public.admin_has_permission('audit.read'));

create policy "Users can read own entitlements" on public.user_entitlements
  for select to authenticated
  using (user_id = auth.uid());

-- subscriptions / plan_overrides / stripe_webhook_events はユーザーへ直接公開しない。
-- ユーザー向け表示は server route が必要な列だけ返す。
-- 管理者画面・webhook は server-side service role 経由で読み書きする。
