-- iter587: 支払い条件設定画面用の表示メモと本人用口座詳細
-- ホーム候補へ出すのは users.payment_methods / users.payment_note まで。
-- 口座詳細は user_payment_settings に分離し、本人だけが読める。

alter table public.users
  add column if not exists payment_note text;

alter table public.users
  drop constraint if exists users_payment_note_length;

alter table public.users
  add constraint users_payment_note_length
  check (payment_note is null or char_length(payment_note) <= 80);

comment on column public.users.payment_note is
  '支払い条件のその他表示メモ。ホーム候補などauthenticatedな取引前表示に使う。口座番号などの機微情報は入れない。';

create table if not exists public.user_payment_settings (
  user_id uuid primary key references public.users(id) on delete cascade,
  bank_name text,
  bank_branch_name text,
  bank_account_type text,
  bank_account_number text,
  bank_account_holder text,
  other_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_payment_settings_bank_name_length check (bank_name is null or char_length(bank_name) <= 80),
  constraint user_payment_settings_branch_name_length check (bank_branch_name is null or char_length(bank_branch_name) <= 80),
  constraint user_payment_settings_account_type_length check (bank_account_type is null or char_length(bank_account_type) <= 20),
  constraint user_payment_settings_account_number_length check (bank_account_number is null or char_length(bank_account_number) <= 32),
  constraint user_payment_settings_account_holder_length check (bank_account_holder is null or char_length(bank_account_holder) <= 80),
  constraint user_payment_settings_other_note_length check (other_note is null or char_length(other_note) <= 80)
);

comment on table public.user_payment_settings is
  '本人だけが編集・閲覧できる支払い条件詳細。銀行口座詳細はホーム候補表示には使わない。';

drop trigger if exists trg_user_payment_settings_updated_at on public.user_payment_settings;
create trigger trg_user_payment_settings_updated_at
  before update on public.user_payment_settings
  for each row execute function public.set_updated_at();

alter table public.user_payment_settings enable row level security;

drop policy if exists "Users can read their own payment settings" on public.user_payment_settings;
create policy "Users can read their own payment settings" on public.user_payment_settings
  for select using (auth.uid() = user_id);

drop policy if exists "Users can insert their own payment settings" on public.user_payment_settings;
create policy "Users can insert their own payment settings" on public.user_payment_settings
  for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update their own payment settings" on public.user_payment_settings;
create policy "Users can update their own payment settings" on public.user_payment_settings
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own payment settings" on public.user_payment_settings;
create policy "Users can delete their own payment settings" on public.user_payment_settings
  for delete using (auth.uid() = user_id);
