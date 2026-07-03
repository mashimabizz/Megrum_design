-- =====================================================================
-- iter1222: minimal admin operations console support
-- =====================================================================
-- Adds the generic user/trade/message reports table described in notes/05
-- and lets admins send official in-app/mobile notifications through the
-- existing notifications + mobile push pipeline.

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  target_user_id uuid references public.users(id) on delete cascade,
  target_proposal_id uuid references public.proposals(id) on delete cascade,
  target_message_id uuid references public.messages(id) on delete cascade,
  category text not null check (
    category in (
      'spam',
      'harassment',
      'fake_item',
      'no_show',
      'unsafe',
      'privacy',
      'other'
    )
  ),
  description text check (description is null or length(description) <= 4000),
  evidence_urls text[] not null default '{}',
  status text not null default 'open' check (
    status in ('open', 'reviewing', 'resolved', 'dismissed')
  ),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_target_required check (
    target_user_id is not null
    or target_proposal_id is not null
    or target_message_id is not null
  ),
  constraint reports_no_self_user_report check (
    target_user_id is null or reporter_id <> target_user_id
  )
);

create index if not exists idx_reports_reporter
  on public.reports(reporter_id, created_at desc);

create index if not exists idx_reports_target_user
  on public.reports(target_user_id, created_at desc)
  where target_user_id is not null;

create index if not exists idx_reports_target_proposal
  on public.reports(target_proposal_id, created_at desc)
  where target_proposal_id is not null;

create index if not exists idx_reports_status
  on public.reports(status, created_at desc);

drop trigger if exists trg_reports_updated_at on public.reports;
create trigger trg_reports_updated_at
  before update on public.reports
  for each row execute function public.set_updated_at();

alter table public.reports enable row level security;

drop policy if exists "Users can insert own reports" on public.reports;
create policy "Users can insert own reports"
  on public.reports for insert
  with check (auth.uid() = reporter_id);

drop policy if exists "Users can read own reports" on public.reports;
create policy "Users can read own reports"
  on public.reports for select
  using (auth.uid() = reporter_id);

comment on table public.reports is
  '汎用通報。ユーザー、取引、メッセージ対象の通報を管理者確認へ回す。';

alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (
    kind in (
      'proposal_received',
      'proposal_accepted',
      'proposal_rejected',
      'proposal_revised',
      'message_received',
      'evidence_added',
      'trade_completed',
      'evaluation_received',
      'dispute_received',
      'dispute_responded',
      'dispute_closed',
      'cancel_requested',
      'expires_soon',
      'groom_liked',
      'groom_reply',
      'meguri_message',
      'meguri_board_reply',
      'meguri_board_mention',
      'admin_announcement'
    )
  );

comment on constraint notifications_kind_check on public.notifications is
  '通知種別。admin_announcement は管理者画面から送る運営通知。';

comment on column public.admin_roles.permissions is
  '例: users.read, users.update_status, roles.read, roles.manage, reports.read, reports.moderate, oshi_requests.read, oshi_requests.manage, notifications.send, billing.read, entitlements.manage, audit.read。ownerまたは*は全権限。';

-- =====================================================================
-- 完了
-- =====================================================================
