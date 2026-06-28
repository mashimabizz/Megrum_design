-- iter1226.32: 標準交換条件を相手プロフィールで読めるように保存する。
-- 現地/発送での交換条件は公開プロフィール上で確認される情報として扱い、
-- 本人だけが作成・更新でき、認証済みユーザーは閲覧できる。

create table if not exists public.user_exchange_settings (
  user_id uuid primary key references public.users(id) on delete cascade,
  preference text not null default 'both',
  local_prefecture text,
  local_date_keys text[] not null default '{}',
  local_date_details jsonb not null default '{}'::jsonb,
  mail_shipping_fee text not null default 'negotiate',
  mail_shipping_days text not null default 'twoToFourDays',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_exchange_settings_preference_check
    check (preference in ('local', 'mail', 'both')),
  constraint user_exchange_settings_shipping_fee_check
    check (mail_shipping_fee in ('owner', 'partner', 'negotiate')),
  constraint user_exchange_settings_shipping_days_check
    check (mail_shipping_days in ('oneDay', 'twoToFourDays', 'afterFiveDays')),
  constraint user_exchange_settings_local_prefecture_length
    check (local_prefecture is null or char_length(local_prefecture) <= 40)
);

comment on table public.user_exchange_settings is
  'User-level standard exchange conditions shown read-only from public profile surfaces.';

drop trigger if exists trg_user_exchange_settings_updated_at on public.user_exchange_settings;
create trigger trg_user_exchange_settings_updated_at
  before update on public.user_exchange_settings
  for each row execute function public.set_updated_at();

alter table public.user_exchange_settings enable row level security;

drop policy if exists "Authenticated users can read exchange settings" on public.user_exchange_settings;
create policy "Authenticated users can read exchange settings" on public.user_exchange_settings
  for select
  using (auth.uid() is not null);

drop policy if exists "Users can insert their own exchange settings" on public.user_exchange_settings;
create policy "Users can insert their own exchange settings" on public.user_exchange_settings
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own exchange settings" on public.user_exchange_settings;
create policy "Users can update their own exchange settings" on public.user_exchange_settings
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update
  on public.user_exchange_settings
  to authenticated;
