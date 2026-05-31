-- =====================================================================
-- iter353: goods_inventory reports
-- =====================================================================
-- Home/Search grid tiles can be reported independently from trade
-- disputes. Reports are scoped to visible goods rows and can only be
-- created by the signed-in reporter.

create table if not exists public.goods_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  goods_inventory_id uuid not null references public.goods_inventory(id) on delete cascade,
  reported_user_id uuid not null references public.users(id) on delete cascade,
  reason text not null check (
    reason in ('spam', 'harassment', 'fake_item', 'privacy', 'unsafe', 'other')
  ),
  note text check (note is null or length(note) <= 500),
  status text not null default 'open' check (
    status in ('open', 'reviewing', 'resolved', 'dismissed')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (reporter_id, goods_inventory_id),
  check (reporter_id <> reported_user_id)
);

create index if not exists idx_goods_reports_reporter
  on public.goods_reports(reporter_id, created_at desc);

create index if not exists idx_goods_reports_status
  on public.goods_reports(status, created_at desc);

drop trigger if exists trg_goods_reports_updated_at on public.goods_reports;
create trigger trg_goods_reports_updated_at
  before update on public.goods_reports
  for each row execute function public.set_updated_at();

alter table public.goods_reports enable row level security;

drop policy if exists "Users can insert own goods reports" on public.goods_reports;
create policy "Users can insert own goods reports"
  on public.goods_reports for insert
  with check (
    auth.uid() = reporter_id
    and reporter_id <> reported_user_id
    and exists (
      select 1
        from public.goods_inventory item
       where item.id = goods_inventory_id
         and item.user_id = reported_user_id
         and item.status in ('active', 'reserved')
    )
  );

drop policy if exists "Users can read own goods reports" on public.goods_reports;
create policy "Users can read own goods reports"
  on public.goods_reports for select
  using (auth.uid() = reporter_id);

-- =====================================================================
-- 完了
-- =====================================================================
