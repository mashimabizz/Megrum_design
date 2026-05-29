-- =====================================================================
-- iter168.74: 郵送交換MVP
-- =====================================================================
-- 現地交換に加えて、郵送交換を提案・合意できるようにする。
-- 住所は user_mailing_addresses に本人のみ保存し、合意時に proposals へ
-- スナップショットを固定して、当事者だけが取引画面で参照する。

create table if not exists public.user_mailing_addresses (
  user_id uuid primary key references public.users(id) on delete cascade,
  recipient_name text not null check (char_length(btrim(recipient_name)) between 1 and 80),
  postal_code text not null check (postal_code ~ '^[0-9]{7}$'),
  prefecture text not null check (char_length(btrim(prefecture)) between 1 and 40),
  city text not null check (char_length(btrim(city)) between 1 and 120),
  line1 text not null check (char_length(btrim(line1)) between 1 and 160),
  line2 text,
  phone_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.user_mailing_addresses is
  '郵送交換で使う住所。本人だけが読み書きでき、proposal 合意時にスナップショット化される。';

drop trigger if exists trg_user_mailing_addresses_updated_at on public.user_mailing_addresses;
create trigger trg_user_mailing_addresses_updated_at
  before update on public.user_mailing_addresses
  for each row execute function public.set_updated_at();

alter table public.user_mailing_addresses enable row level security;

drop policy if exists "Users can read own mailing address" on public.user_mailing_addresses;
create policy "Users can read own mailing address"
  on public.user_mailing_addresses for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own mailing address" on public.user_mailing_addresses;
create policy "Users can insert own mailing address"
  on public.user_mailing_addresses for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own mailing address" on public.user_mailing_addresses;
create policy "Users can update own mailing address"
  on public.user_mailing_addresses for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter table public.proposals
  add column if not exists exchange_method text,
  add column if not exists sender_mailing_address jsonb,
  add column if not exists receiver_mailing_address jsonb;

update public.proposals
   set exchange_method = 'hand'
 where exchange_method is null;

alter table public.proposals
  alter column exchange_method set default 'hand';

alter table public.proposals
  alter column exchange_method set not null;

alter table public.proposals
  drop constraint if exists proposals_exchange_method_check;

alter table public.proposals
  add constraint proposals_exchange_method_check
  check (exchange_method in ('hand', 'mail'));

comment on column public.proposals.exchange_method is
  '提案単位の受け渡し方法。hand=現地交換 / mail=郵送交換';

comment on column public.proposals.sender_mailing_address is
  '郵送交換が合意した時点の送信者住所スナップショット。';

comment on column public.proposals.receiver_mailing_address is
  '郵送交換が合意した時点の受信者住所スナップショット。';

alter table public.proposals
  drop constraint if exists proposals_meetup_required;

alter table public.proposals
  add constraint proposals_meetup_required
  check (
    status = 'draft'
    or (
      exchange_method = 'mail'
      and true
    )
    or (
      exchange_method = 'hand'
      and meetup_start_at is not null
      and meetup_end_at is not null
      and meetup_end_at > meetup_start_at
      and meetup_place_name is not null
      and meetup_lat is not null
      and meetup_lng is not null
    )
  );
