-- =====================================================================
-- iter168.73: Meguri board MVP
-- =====================================================================
-- 現地の情報共有・雑談用のスレッド掲示板。
-- MVPでは exact な「同じスポット」判定はクライアントの spot_key で行い、
-- RLS では author / global / same prefecture までをサーバー側の最小防壁にする。

create table if not exists public.meguri_board_threads (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 80),
  body text not null check (char_length(btrim(body)) between 1 and 500),
  audience_scope text not null default 'same_spot' check (
    audience_scope in ('same_spot', 'same_prefecture', 'global')
  ),
  spot_key text,
  spot_label text,
  prefecture text,
  reply_count integer not null default 0 check (reply_count >= 0),
  latest_reply_preview text check (
    latest_reply_preview is null or char_length(latest_reply_preview) <= 160
  ),
  latest_activity_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint meguri_board_scope_context check (
    case audience_scope
      when 'same_spot' then spot_key is not null and spot_label is not null and prefecture is not null
      when 'same_prefecture' then prefecture is not null
      else true
    end
  )
);

comment on table public.meguri_board_threads is
  'めぐり配下のスポット掲示板スレッド。交換成立用ではなく、現地の情報共有と雑談のために使う。';

create index if not exists idx_meguri_board_threads_feed
  on public.meguri_board_threads(latest_activity_at desc);
create index if not exists idx_meguri_board_threads_prefecture
  on public.meguri_board_threads(prefecture, latest_activity_at desc);
create index if not exists idx_meguri_board_threads_spot
  on public.meguri_board_threads(spot_key, latest_activity_at desc)
  where spot_key is not null;

drop trigger if exists trg_meguri_board_threads_updated_at on public.meguri_board_threads;
create trigger trg_meguri_board_threads_updated_at
  before update on public.meguri_board_threads
  for each row execute function public.set_updated_at();

create table if not exists public.meguri_board_replies (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.meguri_board_threads(id) on delete cascade,
  author_id uuid not null references public.users(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);

comment on table public.meguri_board_replies is
  'スポット掲示板スレッドの追記型返信。MVPではテキストのみ。';

create index if not exists idx_meguri_board_replies_thread
  on public.meguri_board_replies(thread_id, created_at asc);
create index if not exists idx_meguri_board_replies_author
  on public.meguri_board_replies(author_id, created_at desc);

create or replace function public.sync_meguri_board_thread_after_reply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.meguri_board_threads
     set reply_count = reply_count + 1,
         latest_reply_preview = left(new.body, 160),
         latest_activity_at = coalesce(new.created_at, now()),
         updated_at = now()
   where id = new.thread_id;

  return new;
end;
$$;

revoke all on function public.sync_meguri_board_thread_after_reply() from public;
grant execute on function public.sync_meguri_board_thread_after_reply() to authenticated;

drop trigger if exists trg_meguri_board_replies_after_insert on public.meguri_board_replies;
create trigger trg_meguri_board_replies_after_insert
  after insert on public.meguri_board_replies
  for each row execute function public.sync_meguri_board_thread_after_reply();

create or replace function public.can_view_meguri_board_thread(
  target_thread_id uuid,
  viewer_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.meguri_board_threads thread
      left join public.users viewer on viewer.id = viewer_id
     where thread.id = target_thread_id
       and viewer_id is not null
       and (
         thread.author_id = viewer_id
         or thread.audience_scope = 'global'
         or (
           thread.audience_scope in ('same_prefecture', 'same_spot')
           and thread.prefecture is not null
           and viewer.primary_area is not null
           and replace(viewer.primary_area, ' ', '') = replace(thread.prefecture, ' ', '')
         )
       )
  );
$$;

revoke all on function public.can_view_meguri_board_thread(uuid, uuid) from public;
grant execute on function public.can_view_meguri_board_thread(uuid, uuid) to authenticated;

alter table public.meguri_board_threads enable row level security;
alter table public.meguri_board_replies enable row level security;

drop policy if exists "Users can read visible meguri board threads" on public.meguri_board_threads;
create policy "Users can read visible meguri board threads"
  on public.meguri_board_threads for select
  using (public.can_view_meguri_board_thread(id, auth.uid()));

drop policy if exists "Users can insert own meguri board threads" on public.meguri_board_threads;
create policy "Users can insert own meguri board threads"
  on public.meguri_board_threads for insert
  with check (
    auth.uid() = author_id
  );

drop policy if exists "Users can read visible meguri board replies" on public.meguri_board_replies;
create policy "Users can read visible meguri board replies"
  on public.meguri_board_replies for select
  using (public.can_view_meguri_board_thread(thread_id, auth.uid()));

drop policy if exists "Users can insert visible meguri board replies" on public.meguri_board_replies;
create policy "Users can insert visible meguri board replies"
  on public.meguri_board_replies for insert
  with check (
    auth.uid() = author_id
    and public.can_view_meguri_board_thread(thread_id, auth.uid())
  );
