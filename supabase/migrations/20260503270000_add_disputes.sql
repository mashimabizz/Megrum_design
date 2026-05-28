-- =====================================================================
-- iter79-C: dispute（D-flow）テーブル新設
-- =====================================================================
-- 仕様: Megrum/c-dispute.jsx
--
-- フロー：
--   1. submitted   申告者が D-1 + D-2 フォームを送信
--   2. response_pending 相手側に反論要請（24h SLA）— ※ D-4 は次イテで実装
--   3. arbitrating 運営による事実確認（D-5 の「進行中」）
--   4. closed      結論確定（outcome に cancelled / upheld / partial）
--
-- カテゴリは D-1 の 5 種：
--   short   受け取った点数が少ない
--   wrong   グッズが違う / 状態が悪い
--   noshow  相手が現れなかった
--   cancel  合意済みのキャンセル
--   other   その他

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  proposal_id uuid not null references public.proposals(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  respondent_id uuid not null references auth.users(id) on delete cascade,

  category text not null check (
    category in ('short', 'wrong', 'noshow', 'cancel', 'other')
  ),
  fact_memo text check (fact_memo is null or length(fact_memo) <= 4000),
  evidence_photo_urls text[] not null default '{}',

  status text not null default 'submitted' check (
    status in ('submitted', 'response_pending', 'arbitrating', 'closed')
  ),
  outcome text check (
    outcome is null or outcome in ('cancelled', 'upheld', 'partial')
  ),
  operator_comment text check (
    operator_comment is null or length(operator_comment) <= 2000
  ),

  -- 受付番号 DPT-YYMMDD-XXXX（人間用）
  ticket_no text not null unique,

  -- SLA 期限：相手反論 + 運営一次回答
  respondent_deadline_at timestamptz,
  operator_deadline_at timestamptz,

  submitted_at timestamptz not null default now(),
  closed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- 同一 proposal に同時 open は 1 件のみ
  -- （closed は複数可、open は 1 件）
  -- → unique index で実装
  check (reporter_id <> respondent_id)
);

create unique index idx_disputes_proposal_open
  on public.disputes(proposal_id)
  where status <> 'closed';

create index idx_disputes_reporter on public.disputes(reporter_id);
create index idx_disputes_respondent on public.disputes(respondent_id);
create index idx_disputes_status on public.disputes(status);

create trigger trg_disputes_updated_at
  before update on public.disputes
  for each row execute function public.set_updated_at();

comment on table public.disputes is
  'D-flow（取引申告 / 仲裁）。1 取引につき同時 open 1 件まで。';
comment on column public.disputes.ticket_no is
  '受付番号 DPT-YYMMDD-XXXX（人間用、UI 表示）';

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.disputes enable row level security;

-- 自分が reporter or respondent なら参照可
create policy "Participants read own disputes"
  on public.disputes for select
  using (auth.uid() = reporter_id or auth.uid() = respondent_id);

-- 自分が reporter として作成可（proposal の参加者である必要は server-side で検証）
create policy "Reporter creates dispute"
  on public.disputes for insert
  with check (auth.uid() = reporter_id);

-- 自分が reporter or respondent なら更新可（reply 用）
-- 運営側の更新は service role で行う
create policy "Participants update own disputes"
  on public.disputes for update
  using (auth.uid() = reporter_id or auth.uid() = respondent_id);

-- =====================================================================
-- 完了
-- =====================================================================
