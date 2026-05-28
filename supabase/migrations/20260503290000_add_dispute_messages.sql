-- =====================================================================
-- iter89-D5d: dispute_messages テーブル新設
-- =====================================================================
-- 仕様: Megrum/c-dispute.jsx の D5dAdditionalInfo
--
-- 申告者・被申告者・運営の 3 者間で「追加質問」「追加情報」をやり取りする。
-- 既存の disputes テーブルは申告本体・反論本体の保存に使い、
-- それ以降の追加コミュニケーションは dispute_messages に記録する。
--
-- sender_role:
--   reporter   申告者（dispute.reporter_id）
--   respondent 被申告者（dispute.respondent_id）
--   operator   運営側（sender_id null、admin panel 経由で挿入）
--
-- 添付：写真は chat-photos バケット流用、URL を photo_urls 配列で保存。

create table public.dispute_messages (
  id uuid primary key default gen_random_uuid(),
  dispute_id uuid not null references public.disputes(id) on delete cascade,

  sender_id uuid references auth.users(id) on delete set null,
  sender_role text not null check (
    sender_role in ('reporter', 'respondent', 'operator')
  ),

  body text not null check (length(body) between 1 and 4000),
  photo_urls text[] not null default '{}',

  created_at timestamptz not null default now()
);

create index idx_dispute_messages_dispute on public.dispute_messages(dispute_id);
create index idx_dispute_messages_created_at
  on public.dispute_messages(dispute_id, created_at);

comment on table public.dispute_messages is
  '申告フロー（D-flow）の追加コミュニケーション。reporter / respondent / operator 間のメッセージ。';

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.dispute_messages enable row level security;

-- 自分が参加者の dispute メッセージは参照可
create policy "Participants read dispute messages"
  on public.dispute_messages for select
  using (
    exists (
      select 1 from public.disputes d
      where d.id = dispute_messages.dispute_id
        and (d.reporter_id = auth.uid() or d.respondent_id = auth.uid())
    )
  );

-- 自分が参加者の dispute に reporter / respondent としてメッセージを送信可
create policy "Participants send dispute messages"
  on public.dispute_messages for insert
  with check (
    auth.uid() = sender_id
    and sender_role in ('reporter', 'respondent')
    and exists (
      select 1 from public.disputes d
      where d.id = dispute_messages.dispute_id
        and (
          (d.reporter_id = auth.uid() and sender_role = 'reporter')
          or (d.respondent_id = auth.uid() and sender_role = 'respondent')
        )
    )
  );

-- operator メッセージは service role でのみ挿入される（RLS により一般ユーザは insert 不可）

-- =====================================================================
-- 完了
-- =====================================================================
