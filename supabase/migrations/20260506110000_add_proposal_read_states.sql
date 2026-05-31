-- =====================================================================
-- iter162.83: proposal read states for actual read receipts
-- =====================================================================
-- Stores the latest message timestamp each proposal participant has opened.
-- The messages table remains append-only; read state is participant-scoped.

create table public.proposal_read_states (
  proposal_id uuid not null references public.proposals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (proposal_id, user_id)
);

comment on table public.proposal_read_states is
  '取引チャット/ネゴチャットの参加者別読了位置。相手のlast_read_atが自分のメッセージ時刻以降なら既読表示する。';

create index idx_proposal_read_states_user
  on public.proposal_read_states(user_id, last_read_at desc);

alter table public.proposal_read_states enable row level security;

create policy "Participants can read proposal read states"
  on public.proposal_read_states for select
  using (
    exists (
      select 1 from public.proposals p
      where p.id = proposal_read_states.proposal_id
        and (p.sender_id = auth.uid() or p.receiver_id = auth.uid())
    )
  );

create policy "Participants can insert own proposal read states"
  on public.proposal_read_states for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.proposals p
      where p.id = proposal_read_states.proposal_id
        and (p.sender_id = auth.uid() or p.receiver_id = auth.uid())
    )
  );

create policy "Participants can update own proposal read states"
  on public.proposal_read_states for update
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.proposals p
      where p.id = proposal_read_states.proposal_id
        and (p.sender_id = auth.uid() or p.receiver_id = auth.uid())
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.proposals p
      where p.id = proposal_read_states.proposal_id
        and (p.sender_id = auth.uid() or p.receiver_id = auth.uid())
    )
  );

-- =====================================================================
-- done
-- =====================================================================
